#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يضيف جدولي `page_lines_v4`/`words_v4` (تخطيط وكلمات خط QCF V4 Tajweed
1441هـ، مصدر QUL — mushaf_id=19) إلى `assets/quran/quran.db` **الموجودة
فعلاً** — لا يعيد بناء بقية القاعدة من الصفر (يحتاج ذلك كل لقطة `raw/`
الخام لباقي الجداول، غير متوفرة بهذا الفحص المحلي). يُشغَّل يدوياً مرة
واحدة عند إضافة طبعة V4، مو جزء من `build_quran_db.py` وقت التشغيل.

الاستخدام:
    python tools/add_qcf_v4_tajweed.py

يفشل بخطأ واضح إن كانت `page_lines_v4`/`words_v4` موجودة أصلاً (لا يكتب
فوقها بصمت) أو إن اختل أي تحقق بـ`quran_layout.merge_layout` نفسه.
"""
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

from quran_layout import merge_layout

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
DB_PATH = ROOT.parent / "assets" / "quran" / "quran.db"

RAW_PAGES_V4_DB = RAW / "qpc-v4-tajweed-15-lines.db"
RAW_WORDS_V4_DB = RAW / "qpc-v4.db"

# `PRAGMA user_version` الحالي بـquran.db (راجع quran_database.dart)، يرتفع
# لـ٥ بعد هذه الإضافة — تغيير بنية فعلي (جدولان جديدان).
NEXT_SCHEMA_VERSION = 5


def main() -> None:
    if not DB_PATH.exists():
        sys.exit(f"خطأ: {DB_PATH} غير موجودة")

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row

    existing_tables = {
        r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }
    if "page_lines_v4" in existing_tables or "words_v4" in existing_tables:
        sys.exit("خطأ: page_lines_v4/words_v4 موجودة أصلاً بالقاعدة — احذفها يدوياً أولاً إن كنت تنوي إعادة البناء")

    ayah_id_by_key: dict[tuple[int, int], int] = {}
    for r in conn.execute("SELECT id, surah, ayah FROM ayahs"):
        ayah_id_by_key[(r["surah"], r["ayah"])] = r["id"]

    if len(ayah_id_by_key) != 6236:
        sys.exit(f"فشل التحقق: {len(ayah_id_by_key)} آية بجدول ayahs != 6236 — القاعدة غير مكتملة؟")

    merge_layout(conn, RAW_PAGES_V4_DB, RAW_WORDS_V4_DB, ayah_id_by_key, table_suffix="_v4")

    current_version = conn.execute("PRAGMA user_version").fetchone()[0]
    if current_version >= NEXT_SCHEMA_VERSION:
        print(f"  ملاحظة: user_version الحالي ({current_version}) >= {NEXT_SCHEMA_VERSION} أصلاً، لا تغيير عليه")
    else:
        conn.execute(f"PRAGMA user_version = {NEXT_SCHEMA_VERSION}")
        print(f"  PRAGMA user_version: {current_version} -> {NEXT_SCHEMA_VERSION}")

    conn.commit()
    conn.close()
    print("تمت إضافة page_lines_v4/words_v4 بنجاح.")


if __name__ == "__main__":
    main()
