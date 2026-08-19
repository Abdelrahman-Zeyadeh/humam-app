#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يبني assets/hadith/hadith.db من اللقطة الخام بـ tools/raw/hadith_*.json
(مصدرها fawazahmed0/hadith-api، رخصة Unlicense — راجع tools/raw/README.md).

الاستخدام:
    python tools/build_hadith_db.py

يفشل بخطأ واضح إن اختل عدد كتاب أو حديث متوقَّع — لا يُكتب ملف ناقص.
"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

from text_normalize import normalize_search_text

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OUT_DIR = ROOT.parent / "assets" / "hadith"
OUT_DB = OUT_DIR / "hadith.db"

# (المفتاح، اسم الملف الخام، الاسم العربي المعروض، الحد الأدنى المتوقَّع
# لعدد الأحاديث الحقيقية بعد استبعاد صفوف الفواصل الفارغة — تحقّق ضد
# انكماش البيانات لا رقم دقيق حرفي، لأن صفوف الفواصل الفارغة قد تختلف
# بين تحديثات المصدر).
BOOKS = [
    ("bukhari", "hadith_ara-bukhari.json", "صحيح البخاري", 7500),
    ("muslim", "hadith_ara-muslim.json", "صحيح مسلم", 7300),
    ("nawawi", "hadith_ara-nawawi.json", "الأربعون النووية", 40),
]

SCHEMA = """
CREATE TABLE hadith_books (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL
);

CREATE TABLE hadiths (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL,
  hadith_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  text_search TEXT NOT NULL
);
CREATE INDEX idx_hadith_book ON hadiths(book_id, hadith_number);

CREATE VIRTUAL TABLE fts_hadiths USING fts5(
  text_search, content='hadiths', content_rowid='id'
);
"""


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if OUT_DB.exists():
        OUT_DB.unlink()

    conn = sqlite3.connect(OUT_DB)
    conn.executescript(SCHEMA)

    hadith_id = 0
    for book_index, (key, filename, name_ar, min_count) in enumerate(BOOKS, start=1):
        path = RAW / filename
        if not path.exists():
            sys.exit(f"خطأ: الملف الخام غير موجود: {path}")
        with path.open(encoding="utf-8") as f:
            data = json.load(f)

        conn.execute(
            "INSERT INTO hadith_books (id, key, name_ar) VALUES (?,?,?)",
            (book_index, key, name_ar),
        )

        book_count = 0
        for h in data["hadiths"]:
            text = (h.get("text") or "").strip()
            if not text:
                # صفوف فواصل/فهرسة فارغة بالمصدر (فروقات أرقام العناوين) —
                # ليست أحاديث ناقصة، نتجاهلها بدل عرض بطاقة فارغة بالواجهة.
                continue
            hadith_id += 1
            book_count += 1
            conn.execute(
                "INSERT INTO hadiths (id, book_id, hadith_number, text, text_search) VALUES (?,?,?,?,?)",
                (hadith_id, book_index, h["hadithnumber"], text, normalize_search_text(text)),
            )

        if book_count < min_count:
            sys.exit(f"فشل التحقق: كتاب {name_ar} فيه {book_count} حديث فقط، أقل من الحد الأدنى المتوقَّع {min_count}")

        print(f"  {name_ar}: {book_count} حديث")

    conn.execute("INSERT INTO fts_hadiths(rowid, text_search) SELECT id, text_search FROM hadiths")
    conn.execute("PRAGMA user_version = 1")

    (total,) = conn.execute("SELECT COUNT(*) FROM hadiths").fetchone()
    (books_count,) = conn.execute("SELECT COUNT(*) FROM hadith_books").fetchone()
    if books_count != len(BOOKS):
        sys.exit(f"فشل التحقق النهائي: {books_count} كتاب != {len(BOOKS)}")

    (OUT_DIR / "hadith_db_version.txt").write_text("1", encoding="utf-8")

    conn.commit()
    conn.close()

    size_kb = OUT_DB.stat().st_size / 1024
    print(f"تم بنجاح: {OUT_DB} ({size_kb:.0f} كيلوبايت)")
    print(f"  كتب: {books_count}  أحاديث: {total}")


if __name__ == "__main__":
    main()
