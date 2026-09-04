#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يستبدل `assets/hadith/hadith.db` (كان ٩ كتب كاملة، ~٨٣ ميجا) بنسخة نحيلة
تحوي فقط الكتابين الصغيرين المضمَّنين دائماً: الأربعون النووية والأربعون
القدسية (`nawawi`/`qudsi`، ~٣٠٠ كيلوبايت معاً) — بقية الكتب السبعة
(البخاري/مسلم/أبو داود/الترمذي/النسائي/ابن ماجه/موطأ مالك) صارت تنزيلاً
اختيارياً عبر `HadithDownloadController` (راجع `tools/hadith_shards/`
و`tools/split_hadith_shards.py` لملفاتها الجاهزة للاستضافة).

**لماذا لا حذف الأحاديث السبعة المستشهَد بها بالكود مباشرة (تذكيرات
القيام/الحفظ، `reminder_messages.dart`/`qiyam_screen.dart`/
`hifz_screen.dart`) رغم أن كتبها (بخاري/مسلم/أبو داود/نسائي) صارت غير
مضمَّنة؟** لأنها نُسخت يدوياً كنسخة احتياطية ثابتة بـ
`lib/core/data/hadith/essential_hadith_fallback.dart` — راجعه، يضمن عمل
هذه الاستشهادات المحدَّدة السبعة بلا إنترنت وبلا تنزيل حتى لو المستخدم لم
ينزّل كتابها كاملاً بعد.

**لا يمسّ ملفات المصدر ولا الشظايا** — فقط يعيد بناء `assets/hadith/hadith.db`
من `tools/hadith_shards/nawawi.db` + `tools/hadith_shards/qudsi.db`
الجاهزتين أصلاً (نفس مخطط `hadith_tables.dart` حرفياً). **شغّل
`split_hadith_shards.py` أولاً** لو الشظايا غير موجودة بعد.

الاستخدام:
    python tools/build_hadith_db_slim.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHARDS_DIR = ROOT / "hadith_shards"
OUT_DB = ROOT.parent / "assets" / "hadith" / "hadith.db"
OUT_VERSION = ROOT.parent / "assets" / "hadith" / "hadith_db_version.txt"

# مفاتيح الكتابين الوحيدين الباقيين مضمَّنين دائماً — طابق
# `kEmbeddedHadithBookKeys` بـ`hadith_book_catalog.dart` حرفياً.
EMBEDDED_KEYS = ["nawawi", "qudsi"]

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
    for key in EMBEDDED_KEYS:
        shard = SHARDS_DIR / f"{key}.db"
        if not shard.exists():
            raise SystemExit(
                f"شظية غير موجودة: {shard} — شغّل split_hadith_shards.py أولاً"
            )

    if OUT_DB.exists():
        OUT_DB.unlink()
    dst = sqlite3.connect(OUT_DB)
    dst.executescript(SCHEMA)

    total_hadiths = 0
    for key in EMBEDDED_KEYS:
        src = sqlite3.connect(SHARDS_DIR / f"{key}.db")
        books = src.execute("SELECT id, key, name_ar FROM hadith_books").fetchall()
        dst.executemany("INSERT INTO hadith_books VALUES (?, ?, ?)", books)

        chapters = src.execute(
            "SELECT id, book_id, chapter_number, name_en, name_ar FROM hadith_chapters"
        ).fetchall()
        dst.executemany(
            "INSERT INTO hadith_chapters VALUES (?, ?, ?, ?, ?)", chapters
        )

        hadiths = src.execute(
            "SELECT id, book_id, chapter_id, hadith_number, text, text_search FROM hadiths"
        ).fetchall()
        dst.executemany("INSERT INTO hadiths VALUES (?, ?, ?, ?, ?, ?)", hadiths)
        total_hadiths += len(hadiths)
        src.close()

    dst.execute(
        "INSERT INTO fts_hadiths(rowid, text_search) SELECT id, text_search FROM hadiths"
    )
    dst.commit()
    dst.execute("VACUUM")
    dst.close()

    size_kb = OUT_DB.stat().st_size / 1024
    print(f"hadith.db النحيلة: {total_hadiths} حديثاً، {size_kb:.0f} كيلوبايت")
    print(f"-> {OUT_DB}")

    # يجب زيادة نص هذا الملف كلما تغيّر محتوى hadith.db — راجع
    # `syncAssetSqliteDatabase` بـ`asset_sqlite_sync.dart` (المقارنة نصّية
    # فقط، لا معنى محدَّد للرقم نفسه).
    current = OUT_VERSION.read_text(encoding="utf-8").strip()
    next_version = str(int(current) + 1) if current.isdigit() else "slim1"
    OUT_VERSION.write_text(next_version, encoding="utf-8")
    print(f"hadith_db_version.txt: {current} -> {next_version}")


if __name__ == "__main__":
    main()
