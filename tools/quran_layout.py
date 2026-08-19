#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
دمج تخطيط الصفحة (page_lines) وبيانات الكلمات بخط QCF V2 (words) من لقطة
QUL الخام إلى قاعدة `quran.db`. يُستدعى من `build_quran_db.py` بعد إنشاء
جدولي `surahs`/`ayahs`، ولا يُشغَّل مستقلاً.

مصدر البيانات: راجع `raw/README.md` (قسم "بيانات الصفحة والكلمات").
"""
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

EXPECTED_PAGES = 604

SCHEMA = """
CREATE TABLE page_lines (
  page INTEGER NOT NULL,
  line_no INTEGER NOT NULL,
  line_type TEXT NOT NULL,       -- ayah | surah_name | basmallah
  is_centered INTEGER NOT NULL,
  first_word_id INTEGER,         -- NULL لسطور اسم السورة/البسملة (لا كلمات)
  last_word_id INTEGER,
  surah_ref INTEGER,             -- رقم السورة لسطور اسم السورة، وإلا NULL
  PRIMARY KEY (page, line_no)
);

CREATE TABLE words (
  id INTEGER PRIMARY KEY,        -- معرّف عام يطابق first_word_id/last_word_id بـ page_lines
  ayah_id INTEGER NOT NULL,      -- مفتاح أجنبي منطقي إلى ayahs.id
  position INTEGER NOT NULL,     -- ترتيب الكلمة داخل الآية (١-based)
  page INTEGER NOT NULL,
  line_no INTEGER NOT NULL,
  glyph TEXT NOT NULL,           -- رمز الحرف بخط QCF V2 الخاص بهذه الصفحة (p{page}.ttf)
  char_type TEXT NOT NULL        -- word | ayah_marker
  -- عمداً بلا عمود نص عثماني عادي لكل كلمة: تجزئة نص الآية بالمسافات
  -- لا تطابق حدود كلمات QCF حرفياً (تحقق ميداني، مئات حالات الاختلاف)،
  -- وتخمين نص قرآني خاطئ غير مقبول إطلاقاً. يُشتق نص الكلمة لاحقاً من
  -- مصدر word-by-word نصي موثّق مخصص (وليس من هذا التخطيط) عند الحاجة.
);
CREATE INDEX idx_word_line ON words(page, line_no, position);
CREATE INDEX idx_word_ayah ON words(ayah_id);
"""


def _none_if_empty(value):
    """المصدر الخام (QUL) يخزّن `''` بدل NULL الحقيقي بالأعمدة الاختيارية
    (first_word_id/last_word_id لسطور غير الآية، وsurah_ref لسطور الآية) —
    عيب بيانات بالمصدر نفسه، نعالجه هنا قبل الإدراج بقاعدتنا."""
    return None if value == "" else value


def _load_pages(pages_db: Path) -> list[sqlite3.Row]:
    conn = sqlite3.connect(pages_db)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT page_number, line_number, line_type, is_centered, "
        "first_word_id, last_word_id, surah_number FROM pages "
        "ORDER BY page_number, line_number"
    ).fetchall()
    conn.close()
    return rows


def _load_words(words_db: Path) -> list[sqlite3.Row]:
    conn = sqlite3.connect(words_db)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT id, surah, ayah, word, text FROM words ORDER BY id"
    ).fetchall()
    conn.close()
    return rows


def merge_layout(
    conn: sqlite3.Connection,
    pages_db: Path,
    words_db: Path,
    ayah_id_by_key: dict[tuple[int, int], int],
) -> None:
    """يبني `page_lines` و`words` داخل الاتصال `conn` المفتوح على quran.db.

    `ayah_id_by_key` قادم من نفس المرور على info.json الذي بنى جدول
    `ayahs` — لضمان الاتساق بلا قراءة الملف الخام مرتين بمنطقين مختلفين.
    """
    if not pages_db.exists():
        sys.exit(f"خطأ: ملف تخطيط الصفحات غير موجود: {pages_db}")
    if not words_db.exists():
        sys.exit(f"خطأ: ملف كلمات QCF غير موجود: {words_db}")

    conn.executescript(SCHEMA)

    page_rows = _load_pages(pages_db)
    word_rows = _load_words(words_db)

    # --- بناء (page, line_no) لكل معرّف كلمة، من سطور نوع "ayah" فقط ---
    word_location: dict[int, tuple[int, int]] = {}
    pages_seen: set[int] = set()
    for r in page_rows:
        pages_seen.add(r["page_number"])
        first_word_id = _none_if_empty(r["first_word_id"])
        last_word_id = _none_if_empty(r["last_word_id"])
        surah_ref = _none_if_empty(r["surah_number"])
        conn.execute(
            "INSERT INTO page_lines "
            "(page, line_no, line_type, is_centered, first_word_id, last_word_id, surah_ref) "
            "VALUES (?,?,?,?,?,?,?)",
            (
                r["page_number"],
                r["line_number"],
                r["line_type"],
                r["is_centered"],
                first_word_id,
                last_word_id,
                surah_ref,
            ),
        )
        if r["line_type"] == "ayah":
            if first_word_id is None or last_word_id is None:
                sys.exit(f"فشل التحقق: سطر آية بلا نطاق كلمات — صفحة {r['page_number']} سطر {r['line_number']}")
            for wid in range(first_word_id, last_word_id + 1):
                word_location[wid] = (r["page_number"], r["line_number"])

    if len(pages_seen) != EXPECTED_PAGES:
        sys.exit(f"فشل التحقق: عدد صفحات التخطيط {len(pages_seen)} != {EXPECTED_PAGES}")

    # --- تجميع الكلمات حسب الآية لتحديد آخر موضع (علامة نهاية الآية) ---
    # قاعدة ثابتة بمصادر QUL لخط QCF: كل آية تنتهي بـ"كلمة" زائدة هي رمز
    # العلامة الزخرفية لرقم الآية، لا نص حقيقي. أعلى `position` بكل مجموعة
    # هو دائماً هذه العلامة — تحقّقنا يدوياً من الفاتحة (٤ كلمات + علامة)،
    # آية الكرسي (٥٠ + علامة)، والإخلاص ١ (٤ + علامة).
    max_position: dict[tuple[int, int], int] = {}
    for w in word_rows:
        key = (w["surah"], w["ayah"])
        max_position[key] = max(max_position.get(key, 0), w["word"])

    mismatches: list[str] = []
    inserted = 0
    for w in word_rows:
        key = (w["surah"], w["ayah"])
        ayah_id = ayah_id_by_key.get(key)
        if ayah_id is None:
            mismatches.append(f"آية غير معروفة بجدول ayahs: {key}")
            continue

        wid = w["id"]
        loc = word_location.get(wid)
        if loc is None:
            mismatches.append(f"كلمة {wid} ({key}) بلا موضع بالتخطيط (page/line)")
            continue

        page, line_no = loc
        position = w["word"]
        is_marker = position == max_position[key]
        conn.execute(
            "INSERT INTO words (id, ayah_id, position, page, line_no, glyph, char_type) "
            "VALUES (?,?,?,?,?,?,?)",
            (wid, ayah_id, position, page, line_no, w["text"], "ayah_marker" if is_marker else "word"),
        )
        inserted += 1

    if mismatches:
        sys.exit(
            "فشل التحقق: عدم اتساق بين جدول ayahs وبيانات كلمات QCF "
            f"({len(mismatches)} حالة). أمثلة:\n" + "\n".join(mismatches[:10])
        )

    if inserted != len(word_rows):
        sys.exit(f"فشل التحقق: أُدرجت {inserted} كلمة من أصل {len(word_rows)} بمصدر QCF")

    print(f"  تخطيط الصفحات: {len(pages_seen)} صفحة، {len(page_rows)} سطراً، {inserted} كلمة")
