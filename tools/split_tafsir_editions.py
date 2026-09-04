#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يستخرج التفاسير الأربعة (الجلالين، الميسر، السعدي، ابن كثير) من
`assets/quran/quran.db` الحالية إلى ملفات SQLite مستقلة بـ`tools/
tafsir_editions/tafsir_{edition}.db` — تحضيراً لتحويلها لتنزيل حسب
الحاجة (نفس مبدأ `split_hadith_shards.py` للأحاديث)، بدل بقائها مضمَّنة
داخل `quran.db`. **لا إصدار مضمَّن إطلاقاً الآن** (بطلب صاحب المشروع
صراحة — كان الجلالين وحده مضمَّناً سابقاً لخفّة حجمه، ١ ميجا، لكن التوحيد
الكامل أُوثِر) — راجع `tafsir_edition_catalog.dart`.

**المصدر: `quran.db` المحلية، لا ملفات JSON المرفوعة لـGitHub Releases
(`Tafsir-v1`)** — عمداً: `quran.db` الحالية مرّت فعلاً بخط أنابيب التحقّق
الصارم (`tools/build_quran_db.py`، ٦٢٣٦ آية بالضبط لكل تفسير، لا نص فارغ)
الموثَّق بـ`tools/raw/README.md`. ملفات JSON المرفوعة استُخدمت فقط
كتحقّق تقاطعي (عيّنة) للتأكد أنها نفس المحتوى — راجع `verify_tafsir_json_
matches_db.py` لو احتجت إعادته.

مخطط كل ملف ناتج (يطابق تصميم-النظام.md §٢.٣ حرفياً): `meta(id, edition,
ayah_count)` + `texts(ayah_id INTEGER PRIMARY KEY, body TEXT)` — لا عمود
`edition` بجدول `texts` (كل ملف تفسير واحد بالتعريف، خلاف `Tafsirs.edition`
بـ`quran.db` المُصمَّمة لتحوي عدّة تفاسير بجدول واحد).

الاستخدام:
    python tools/split_tafsir_editions.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC_DB = ROOT.parent / "assets" / "quran" / "quran.db"
OUT_DIR = ROOT / "tafsir_editions"

# يشمل 'jalalayn' الآن (لا إصدار مضمَّن إطلاقاً) — طابق
# `kEmbeddedTafsirEditions` الفارغة بـ`tafsir_edition_catalog.dart` حرفياً.
DOWNLOADABLE_EDITIONS = ["jalalayn", "muyassar", "saadi", "ibnkathir"]

SCHEMA = """
CREATE TABLE meta (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  edition TEXT NOT NULL,
  ayah_count INTEGER NOT NULL
);
CREATE TABLE texts (
  ayah_id INTEGER PRIMARY KEY,
  body TEXT NOT NULL
);
"""


def main() -> None:
    if not SRC_DB.exists():
        raise SystemExit(f"غير موجود: {SRC_DB}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    src = sqlite3.connect(SRC_DB)

    print(f"{'التفسير':<12} {'آيات':>8} {'حجم الملف':>12}")
    for edition in DOWNLOADABLE_EDITIONS:
        rows = src.execute(
            "SELECT ayah_id, text FROM tafsirs WHERE edition = ? ORDER BY ayah_id",
            (edition,),
        ).fetchall()
        if len(rows) != 6236:
            raise SystemExit(f"عدد آيات غير متوقَّع لـ{edition}: {len(rows)} (متوقَّع ٦٢٣٦)")

        out_path = OUT_DIR / f"tafsir_{edition}.db"
        if out_path.exists():
            out_path.unlink()
        dst = sqlite3.connect(out_path)
        dst.executescript(SCHEMA)
        dst.execute("INSERT INTO meta VALUES (1, ?, ?)", (edition, len(rows)))
        dst.executemany("INSERT INTO texts VALUES (?, ?)", rows)
        dst.commit()
        dst.execute("VACUUM")
        dst.close()

        size_mb = out_path.stat().st_size / 1024 / 1024
        print(f"{edition:<12} {len(rows):>8} {size_mb:>10.1f} ميجا")

    src.close()
    print(f"-> الملفات جاهزة بـ {OUT_DIR}")


if __name__ == "__main__":
    main()
