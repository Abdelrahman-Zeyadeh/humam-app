#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يبني assets/quran/quran.db من اللقطة الخام في tools/raw/ (راجع raw/README.md
لمصدر البيانات وترخيصها). يُشغَّل يدوياً عند الحاجة لإعادة توليد قاعدة
البيانات — ليس جزءاً من عملية بناء التطبيق وقت التشغيل.

الاستخدام:
    python tools/build_quran_db.py

يفشل بخطأ واضح (exit code != 0) إن اختل عدد السور (114) أو الآيات (6236)
أو أي تحقق اتساق آخر — لا يُكتب ملف ناقص أو خاطئ أبداً.

يضيف أيضاً جدولي `page_lines` و`words` (تخطيط الصفحة وكلمات خط QCF V2)
عبر `quran_layout.merge_layout` — راجع ذلك الملف لتفاصيل الدمج والتحقق.
"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

from quran_layout import merge_layout
from quran_texts import merge_texts
from text_normalize import normalize_search_text, strip_diacritics

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OUT_DIR = ROOT.parent / "assets" / "quran"
OUT_DB = OUT_DIR / "quran.db"

RAW_PAGES_DB = RAW / "qpc-v2-15-lines.db"  # تخطيط الصفحات (QUL)
RAW_WORDS_DB = RAW / "qpc-v2.db"  # كلمات بخط QCF V2 لكل صفحة (QUL)

EXPECTED_SURAHS = 114
EXPECTED_AYAHS = 6236

# سورة التوبة الوحيدة بلا بسملة. الفاتحة بسملتها آية ١ داخل نص السورة نفسه
# (مضمّنة بتدفق الآيات) لا سطر بسملة منفصل قبلها.
SURAH_NO_BISMILLAH = 9
SURAH_FATIHA = 1

def load_json(name: str):
    path = RAW / name
    if not path.exists():
        sys.exit(f"خطأ: الملف الخام غير موجود: {path}")
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> None:
    info = load_json("info.json")
    uthmani = load_json("ara-quranuthmanihaf.json")

    chapters = info["chapters"]
    if len(chapters) != EXPECTED_SURAHS:
        sys.exit(f"فشل التحقق: عدد السور {len(chapters)} != {EXPECTED_SURAHS}")

    # نص كل آية: {(surah, ayah): text}
    text_by_key: dict[tuple[int, int], str] = {}
    for row in uthmani["quran"]:
        text_by_key[(row["chapter"], row["verse"])] = row["text"]

    if len(text_by_key) != EXPECTED_AYAHS:
        sys.exit(f"فشل التحقق: عدد نصوص الآيات {len(text_by_key)} != {EXPECTED_AYAHS}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if OUT_DB.exists():
        OUT_DB.unlink()

    conn = sqlite3.connect(OUT_DB)
    conn.executescript(
        """
        CREATE TABLE surahs (
          id INTEGER PRIMARY KEY,
          name_ar TEXT NOT NULL,
          name_ar_plain TEXT NOT NULL,
          name_en TEXT NOT NULL,
          revelation_place TEXT NOT NULL,
          revelation_order INTEGER,
          ayah_count INTEGER NOT NULL,
          start_page INTEGER NOT NULL,
          bismillah_pre INTEGER NOT NULL
        );

        CREATE TABLE ayahs (
          id INTEGER PRIMARY KEY,
          surah INTEGER NOT NULL,
          ayah INTEGER NOT NULL,
          page INTEGER NOT NULL,
          juz INTEGER NOT NULL,
          hizb INTEGER,
          rub INTEGER,
          manzil INTEGER NOT NULL,
          sajda_type TEXT,
          text_uthmani TEXT NOT NULL,
          text_search TEXT NOT NULL
        );
        CREATE INDEX idx_ayah_page ON ayahs(page);
        CREATE UNIQUE INDEX idx_ayah_key ON ayahs(surah, ayah);

        CREATE VIRTUAL TABLE fts_ayahs USING fts5(
          text_search, content='ayahs', content_rowid='id'
        );
        """
    )

    ayah_id = 0
    ayah_id_by_key: dict[tuple[int, int], int] = {}
    for chapter in chapters:
        surah_no = chapter["chapter"]
        verses = chapter["verses"]
        if not verses:
            sys.exit(f"فشل التحقق: السورة {surah_no} بلا آيات في info.json")

        name_ar = chapter["arabicname"].strip()
        revelation_place = "makkah" if chapter["revelation"] == "Mecca" else "madinah"
        bismillah_pre = 0 if surah_no in (SURAH_NO_BISMILLAH, SURAH_FATIHA) else 1

        conn.execute(
            """INSERT INTO surahs
               (id, name_ar, name_ar_plain, name_en, revelation_place,
                revelation_order, ayah_count, start_page, bismillah_pre)
               VALUES (?,?,?,?,?,?,?,?,?)""",
            (
                surah_no,
                name_ar,
                strip_diacritics(name_ar),
                chapter["name"],
                revelation_place,
                None,  # TODO: ترتيب النزول — يحتاج مصدراً منفصلاً موثقاً
                len(verses),
                verses[0]["page"],
                bismillah_pre,
            ),
        )

        for v in verses:
            key = (surah_no, v["verse"])
            text = text_by_key.get(key)
            if text is None:
                sys.exit(f"فشل التحقق: لا يوجد نص للآية {surah_no}:{v['verse']}")

            ayah_id += 1
            ayah_id_by_key[key] = ayah_id
            conn.execute(
                """INSERT INTO ayahs
                   (id, surah, ayah, page, juz, hizb, rub, manzil, sajda_type,
                    text_uthmani, text_search)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    ayah_id,
                    surah_no,
                    v["verse"],
                    v["page"],
                    v["juz"],
                    None,  # TODO: الحزب — يحتاج مصدراً منفصلاً موثقاً
                    None,  # TODO: الرُّبع — يحتاج مصدراً منفصلاً موثقاً
                    v["manzil"],
                    "sajda" if v.get("sajda") else None,
                    text,
                    normalize_search_text(text),
                ),
            )

    if ayah_id != EXPECTED_AYAHS:
        sys.exit(f"فشل التحقق: أُدرجت {ayah_id} آية != {EXPECTED_AYAHS}")

    conn.execute("INSERT INTO fts_ayahs(rowid, text_search) SELECT id, text_search FROM ayahs")

    merge_layout(conn, RAW_PAGES_DB, RAW_WORDS_DB, ayah_id_by_key)
    merge_texts(conn, RAW, ayah_id_by_key)

    # يطابق QuranDatabase.schemaVersion بطبقة drift — قاعدة مُنشأة مسبقاً
    # وليست فارغة، فلا داعٍ لتشغيل drift's onCreate عند أول فتح لها.
    # رفعناه لـ٢ لإضافة tafsirs/translations — راجع ملاحظة النسخ بالإصدار
    # بـ QuranDatabase._openConnection (يعيد نسخ الـ asset لو تغيّر الرقم).
    conn.execute("PRAGMA user_version = 2")

    # تحقق نهائي مباشرة من القاعدة المكتوبة، لا من العدادات فقط
    (surah_count,) = conn.execute("SELECT COUNT(*) FROM surahs").fetchone()
    (ayah_count,) = conn.execute("SELECT COUNT(*) FROM ayahs").fetchone()
    (ayah_sum,) = conn.execute("SELECT SUM(ayah_count) FROM surahs").fetchone()
    if surah_count != EXPECTED_SURAHS or ayah_count != EXPECTED_AYAHS or ayah_sum != EXPECTED_AYAHS:
        sys.exit(
            f"فشل التحقق النهائي: سور={surah_count} آيات={ayah_count} "
            f"مجموع ayah_count={ayah_sum}"
        )

    conn.commit()
    conn.close()

    # يُقرأ بجانب quran.db كـ asset منفصل — يقارنه QuranDatabase بنسخة
    # محفوظة بمجلد المستندات ليقرر إعادة نسخ القاعدة عند تغيّره، بدل
    # الاعتماد فقط على "الملف موجود؟" (كان سيُبقي نسخة قديمة بلا الجداول
    # الجديدة عالأجهزة التي جرّبت التطبيق قبل هذا التحديث).
    (OUT_DIR / "quran_db_version.txt").write_text("2", encoding="utf-8")

    size_kb = OUT_DB.stat().st_size / 1024
    print(f"تم بنجاح: {OUT_DB} ({size_kb:.0f} كيلوبايت)")
    print(f"  سور: {surah_count}  آيات: {ayah_count}")


if __name__ == "__main__":
    main()
