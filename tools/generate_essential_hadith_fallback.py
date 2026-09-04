#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يولّد `lib/core/data/hadith/essential_hadith_fallback.dart` **آلياً** من
`tools/hadith_shards/*.db` — لا تكتب نصوص الأحاديث بهذا الملف يدوياً
إطلاقاً. النص العربي هنا محاط بعلامات RTL خفيّة (RLM، `\u200f`) حول علامات
الاقتباس — نسخ يدوي (لصق بمحرّر نص) يفقدها أو يبدّل مسافة مجاورة بسهولة
تامة بلا أي فرق مرئي بالمحرر، وهذا بالضبط ما حصل أول مرة (اكتشفه اختبار
`test/hadith_repository_test.dart` بمقارنة حرفية مع المصدر الحقيقي). راجع
`essential_hadith_fallback.dart` نفسه لشرح **لماذا** توجد هذه النسخة
الاحتياطية أصلاً (تذكيرات القيام/الحفظ الدوّارة).

الاستخدام:
    python tools/generate_essential_hadith_fallback.py
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHARDS_DIR = ROOT / "hadith_shards"
OUT_FILE = ROOT.parent / "lib" / "core" / "data" / "hadith" / "essential_hadith_fallback.dart"

# (مفتاح الكتاب، ملف الشظية، أرقام الأحاديث المستشهَد بها بالكود) — طابق
# كل استدعاء `hadithByBookAndNumber` بـ`reminder_messages.dart`/
# `qiyam_screen.dart`/`hifz_screen.dart` حرفياً لو أُضيف استشهاد جديد.
TARGETS: list[tuple[str, list[int]]] = [
    ("bukhari", [4937, 5033, 1145]),
    ("muslim", [1844]),
    ("abudawud", [1398]),
    ("nasai", [1614, 1763]),
]

HEADER = """import 'hadith_database.dart';

/// نسخة احتياطية ثابتة لسبعة أحاديث بعينها **مستشهَد بها مباشرة بالكود**
/// (تذكيرات القيام/الحفظ الدوّارة وشاشتَي `qiyam_screen.dart`/
/// `hifz_screen.dart` — راجع كل استدعاء `hadithByBookAndNumber`
/// بـ`reminder_messages.dart`). **السبب:** بعد تحويل الأحاديث لتنزيل حسب
/// الحاجة (راجع `hadith_book_catalog.dart`)، كتب هذه الاستشهادات نفسها
/// (البخاري/مسلم/أبو داود/النسائي) صارت غير مضمَّنة افتراضياً — بلا هذه
/// النسخة، أي تذكير مجدوَل يُطلب حديثه قبل أن يفتح المستخدم التطبيق مرة
/// ويحمّل الكتاب المطلوب كان سيفشل صامتاً (`hadithByBookAndNumber` يرجع
/// `null`). هون **النص فقط**، منسوخ **آلياً** (راجع
/// `tools/generate_essential_hadith_fallback.py` — لا تعدّل هون يدوياً)
/// من `tools/hadith_shards/` (نفس مصدر الترخيص Unlicense الموثَّق
/// بـ`tools/raw/README.md`).
///
/// `HadithRepository.hadithByBookAndNumber` يستخدم هذه القائمة فقط حين
/// يكون كتاب الحديث المطلوب **غير متاح حالياً** (لا مضمَّن ولا منزَّل) —
/// لو نُزِّل الكتاب لاحقاً، يُقرأ الحديث من قاعدته الفعلية كالمعتاد.
const Map<String, Hadith> kEssentialHadithFallback = {
"""


def dart_string(s: str) -> str:
    escaped = s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("$", "\\$")
    return "'" + escaped + "'"


def main() -> None:
    parts = [HEADER]
    total = 0
    for key, numbers in TARGETS:
        shard = SHARDS_DIR / f"{key}.db"
        if not shard.exists():
            raise SystemExit(f"شظية غير موجودة: {shard} — شغّل split_hadith_shards.py أولاً")
        con = sqlite3.connect(shard)
        for number in numbers:
            row = con.execute(
                "SELECT book_id, hadith_number, text, text_search FROM hadiths WHERE hadith_number = ?",
                (number,),
            ).fetchone()
            if row is None:
                raise SystemExit(f"حديث غير موجود: {key}:{number}")
            book_id, hadith_number, text, text_search = row
            parts.append(f"  '{key}:{hadith_number}': Hadith(\n")
            parts.append(f"    id: {hadith_number},\n")
            parts.append(f"    bookId: {book_id},\n")
            parts.append("    chapterId: null,\n")
            parts.append(f"    hadithNumber: {hadith_number},\n")
            parts.append(f"    content: {dart_string(text)},\n")
            parts.append(f"    textSearch: {dart_string(text_search)},\n")
            parts.append("  ),\n")
            total += 1
        con.close()
    parts.append("};\n")

    OUT_FILE.write_text("".join(parts), encoding="utf-8")
    print(f"{OUT_FILE}: {total} حديثاً")


if __name__ == "__main__":
    main()
