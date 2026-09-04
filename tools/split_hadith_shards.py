#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يجزّئ assets/hadith/hadith.db (٨٣ ميجا، ٩ كتب مضمَّنة كاملة) إلى ملف
SQLite مستقل لكل كتاب بـ tools/hadith_shards/<key>.db — تحضيراً لتحويل
قسم الأحاديث لتنزيل حسب الحاجة (بطلب صاحب المشروع)، بدل تضمين كل الكتب
التسعة بالـ APK من أول تشغيل.

**لا يغيّر شيئاً بالتطبيق نفسه** — لا يمسّ `assets/hadith/hadith.db` ولا
كود القراءة الحالي (`hadith_repository.dart`). هذا فقط يُنتج الملفات
الجاهزة للاستضافة (راجع نمط الخطوط: `remote_assets_config.dart` +
GitHub Releases). الخطوة التالية (تحتاج قراراً/رفعاً من صاحب المشروع لا
تلقائياً): ارفع هذه الملفات لإصدار جديد بمستودع `humam-app-assets`، ثم
أضِف `HadithDownloadController` بنفس نمط `audio_download_service.dart`/
`font_download_service.dart` يقرأ منها بدل `ATTACH` الكتب غير المضمَّنة.

كل ملف ناتج مستقل تماماً بنفس مخطط hadith.db (جدول واحد بـhadith_books
يحوي صفّ الكتاب هذا فقط، حتى تبقى المعرّفات `book_id` كما هي بلا حاجة
لإعادة ترقيم أو تغيير كود القراءة لاحقاً)، مع فهرس FTS5 خاص به مُعاد بناؤه
كاملاً (خارجي المحتوى `content='hadiths'`، فلازم يُبنى من الصفر لكل شظية
لا يُنسَخ كـBLOB خام).

الاستخدام:
    python tools/split_hadith_shards.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SRC_DB = ROOT.parent / "assets" / "hadith" / "hadith.db"
OUT_DIR = ROOT / "hadith_shards"

SCHEMA = """
CREATE TABLE hadith_books (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL
);
CREATE TABLE hadith_chapters (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL,
  chapter_number INTEGER NOT NULL,
  name_en TEXT NOT NULL,
  name_ar TEXT
);
CREATE TABLE hadiths (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL,
  chapter_id INTEGER,
  hadith_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  text_search TEXT NOT NULL
);
CREATE VIRTUAL TABLE fts_hadiths USING fts5(
  text_search, content='hadiths', content_rowid='id'
);
"""


def main() -> None:
    if not SRC_DB.exists():
        raise SystemExit(f"غير موجود: {SRC_DB}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    src = sqlite3.connect(SRC_DB)
    books = src.execute("SELECT id, key, name_ar FROM hadith_books ORDER BY id").fetchall()

    print(f"{'الكتاب':<12} {'المفتاح':<10} {'أحاديث':>8} {'حجم الملف':>12}")
    total_shard_bytes = 0
    for book_id, key, name_ar in books:
        out_path = OUT_DIR / f"{key}.db"
        if out_path.exists():
            out_path.unlink()
        dst = sqlite3.connect(out_path)
        dst.executescript(SCHEMA)

        dst.execute("INSERT INTO hadith_books VALUES (?, ?, ?)", (book_id, key, name_ar))

        chapters = src.execute(
            "SELECT id, book_id, chapter_number, name_en, name_ar FROM hadith_chapters WHERE book_id = ?",
            (book_id,),
        ).fetchall()
        dst.executemany("INSERT INTO hadith_chapters VALUES (?, ?, ?, ?, ?)", chapters)

        hadiths = src.execute(
            "SELECT id, book_id, chapter_id, hadith_number, text, text_search FROM hadiths WHERE book_id = ?",
            (book_id,),
        ).fetchall()
        dst.executemany("INSERT INTO hadiths VALUES (?, ?, ?, ?, ?, ?)", hadiths)

        # فهرس FTS خارجي المحتوى — يُبنى من صفوف hadiths المُدرَجة للتو،
        # لا نسخ مباشر لجداول fts_* الداخلية (مرتبطة بترقيم rowid الأصلي
        # الكامل لقاعدة البيانات المصدر، غير صالحة بملف منفصل).
        dst.execute("INSERT INTO fts_hadiths(rowid, text_search) SELECT id, text_search FROM hadiths")

        dst.commit()
        dst.execute("VACUUM")
        dst.close()

        size_kb = out_path.stat().st_size / 1024
        total_shard_bytes += out_path.stat().st_size
        print(f"{name_ar:<12} {key:<10} {len(hadiths):>8} {size_kb:>10.0f} كيلوبايت")

    src_size_mb = SRC_DB.stat().st_size / 1024 / 1024
    total_mb = total_shard_bytes / 1024 / 1024
    print()
    print(f"الأصل الكامل (assets/hadith/hadith.db): {src_size_mb:.1f} ميجا")
    print(f"مجموع الشظايا المنفصلة:                 {total_mb:.1f} ميجا")
    print(f"-> الملفات جاهزة بـ {OUT_DIR}")


if __name__ == "__main__":
    main()
