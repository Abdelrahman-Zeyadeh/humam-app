#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يحذف صفوف الجلالين/الميسر/السعدي/ابن كثير **كلها** من جدول `tafsirs`
بـ`assets/quran/quran.db` **في مكانها** (لا يعيد بناء الملف كاملاً كـ
`build_quran_db.py` — تجنّباً لإعادة تشغيل خط أنابيب البناء الكامل
الحسّاس لمخاطر أكبر) — **لا إصدار مضمَّن إطلاقاً الآن** (بطلب صاحب
المشروع صراحة، راجع `tafsir_edition_catalog.dart`؛ كان الجلالين وحده
مضمَّناً سابقاً). **شغّل `split_tafsir_editions.py` أولاً وتحقّق من نجاح
ناتجه قبل هذا السكربت** — لا رجعة سهلة بعد الحذف+VACUUM غير استعادة نسخة
احتياطية.

يقلّص `quran.db` من ~١٥٢ ميجا إلى ~٩ ميجا تقريباً (يبقي: نص المصحف الكامل
+ تخطيط الصفحات + الترجمة + المتشابهات — بلا أي تفسير).

الاستخدام:
    python tools/slim_quran_db_tafsirs.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT.parent / "assets" / "quran" / "quran.db"
VERSION_PATH = ROOT.parent / "assets" / "quran" / "quran_db_version.txt"

REMOVED_EDITIONS = ["jalalayn", "muyassar", "saadi", "ibnkathir"]


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(f"غير موجود: {DB_PATH}")

    size_before = DB_PATH.stat().st_size / 1024 / 1024

    con = sqlite3.connect(DB_PATH)
    for edition in REMOVED_EDITIONS:
        count = con.execute("SELECT COUNT(*) FROM tafsirs WHERE edition = ?", (edition,)).fetchone()[0]
        con.execute("DELETE FROM tafsirs WHERE edition = ?", (edition,))
        print(f"حذف {count} صفاً لتفسير {edition}")

    remaining = con.execute("SELECT edition, COUNT(*) FROM tafsirs GROUP BY edition").fetchall()
    con.commit()
    con.execute("VACUUM")
    con.close()

    print("الإصدارات المتبقّية بـtafsirs:", remaining)

    size_after = DB_PATH.stat().st_size / 1024 / 1024
    print(f"quran.db: {size_before:.1f} ميجا -> {size_after:.1f} ميجا")

    # راجع ملاحظة الإصدار بـ`tools/build_hadith_db_slim.py` — نفس المبدأ:
    # نص حر يُقارَن بالمساواة فقط عبر `syncAssetSqliteDatabase`، القيمة
    # نفسها لا معنى لها، فقط يجب أن *تتغيّر* عن السابقة.
    current = VERSION_PATH.read_text(encoding="utf-8").strip()
    next_version = str(int(current) + 1) if current.isdigit() else "slim1"
    VERSION_PATH.write_text(next_version, encoding="utf-8")
    print(f"quran_db_version.txt: {current} -> {next_version}")


if __name__ == "__main__":
    main()
