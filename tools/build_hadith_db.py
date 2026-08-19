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

from hadith_chapter_names_ar import BUKHARI_CHAPTER_NAMES_AR, MUSLIM_CHAPTER_NAMES_AR, NAWAWI_CHAPTER_NAMES_AR
from text_normalize import normalize_search_text

CHAPTER_NAMES_AR_BY_BOOK: dict[str, dict[int, str]] = {
    "bukhari": BUKHARI_CHAPTER_NAMES_AR,
    "muslim": MUSLIM_CHAPTER_NAMES_AR,
    "nawawi": NAWAWI_CHAPTER_NAMES_AR,
}

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OUT_DIR = ROOT.parent / "assets" / "hadith"
OUT_DB = OUT_DIR / "hadith.db"

# (المفتاح، اسم الملف الخام، الاسم العربي المعروض، الحد الأدنى المتوقَّع
# لعدد الأحاديث الحقيقية بعد استبعاد صفوف الفواصل الفارغة — تحقّق ضد
# انكماش البيانات لا رقم دقيق حرفي، لأن صفوف الفواصل الفارغة قد تختلف
# بين تحديثات المصدر).
#
# الستة الأخيرة (أبو داود..القدسية) أُضيفت ٢٠٢٦-٠٨-١٩ — نفس المصدر
# ونفس رخصة Unlicense المستخدَمة أصلاً للبخاري/مسلم (تحقّقت من
# editions.json: كل ستّتها edition عربي رسمي بنفس المستودع، لا مصدر
# جديد يحتاج تحقّق ترخيص منفصل). عناوين أبوابها العربية **غير مترجَمة
# بعد** (خلافاً للثلاثة الأولى) — راجع `CHAPTER_NAMES_AR_BY_BOOK` والتحقّق
# النهائي بأسفل الملف: الواجهة تعرض `name_en` كعنوان مؤقت لهذه الكتب
# تحديداً (`hadith_book_screen.dart` أصلاً `nameAr ?? nameEn`)، ولا نمنع
# البناء بسببها — ترجمة ~٢٥٠ باباً إضافياً من الذاكرة تخالف قاعدة "لا نص/
# تصنيف ديني من التخمين" بنفس صرامة النص نفسه.
BOOKS = [
    ("bukhari", "hadith_ara-bukhari.json", "صحيح البخاري", 7500),
    ("muslim", "hadith_ara-muslim.json", "صحيح مسلم", 7300),
    ("nawawi", "hadith_ara-nawawi.json", "الأربعون النووية", 40),
    ("abudawud", "hadith_ara-abudawud.json", "سنن أبي داود", 5200),
    ("tirmidhi", "hadith_ara-tirmidhi.json", "جامع الترمذي", 3850),
    ("nasai", "hadith_ara-nasai.json", "سنن النسائي", 5600),
    ("ibnmajah", "hadith_ara-ibnmajah.json", "سنن ابن ماجه", 4250),
    ("malik", "hadith_ara-malik.json", "موطأ مالك", 1750),
    ("qudsi", "hadith_ara-qudsi.json", "الأربعون القدسية", 40),
]

SCHEMA = """
CREATE TABLE hadith_books (
  id INTEGER PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL
);

-- "الأبواب"/الكتب الداخلية لكل مجموعة (مثلاً كتاب الإيمان، كتاب العلم
-- بالبخاري) — رقمها (chapter_number) وحدوده من metadata.sections
-- الحقيقية بالمصدر الخام. **لا اسم عربي رسمي بمصدر البيانات نفسه حتى
-- بنسخته العربية** (تحقّقت من editions.json ومن ara-bukhari.json
-- مباشرة) — name_en هو الاسم الإنجليزي الموثَّق فعلياً بالملف الخام،
-- معروض كعنوان مؤقت للمجموعة ريثما يُعثر على مصدر عربي موثوق. راجع
-- "قيد معروف" بـ tools/raw/README.md.
CREATE TABLE hadith_chapters (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL,
  chapter_number INTEGER NOT NULL,
  name_en TEXT NOT NULL,
  name_ar TEXT
);
CREATE INDEX idx_chapter_book ON hadith_chapters(book_id, chapter_number);

CREATE TABLE hadiths (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL,
  chapter_id INTEGER,
  hadith_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  text_search TEXT NOT NULL
);
CREATE INDEX idx_hadith_book ON hadiths(book_id, hadith_number);
CREATE INDEX idx_hadith_chapter ON hadiths(chapter_id);

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

        # الأبواب/الكتب الداخلية — من metadata.sections الحقيقية. رقم
        # الفصل بالمعرّف المركّب (book_index*1000 + section_number) يبقى
        # فريداً ومستقراً بلا اعتماد على ترتيب إدراج غير حتمي.
        sections: dict = data["metadata"].get("sections", {})
        chapter_ids: dict[int, int] = {}
        for section_key, section_name_en in sections.items():
            section_number = int(section_key)
            name = section_name_en.strip()
            if not name:
                # اسم فارغ حرفياً بالمصدر (مثلاً قسم "0" بالبخاري: ٣٠٦ حديث
                # حقيقي بلا عنوان باب أصلاً بملف البيانات نفسه، ليس نقصاً
                # بجهتنا) — نتجاهل قسم "0" فقط لو لا أحاديث حقيقية مرتبطة
                # به لاحقاً (نتحقق بعد الحلقة)، وإلا نعطيه عنواناً مؤقتاً
                # صريحاً بدل إسقاط أحاديثه من أي تصنيف.
                name = "(بلا عنوان باب في المصدر)"
            chapter_id = book_index * 1000 + section_number
            chapter_ids[section_number] = chapter_id
            chapter_name_ar = CHAPTER_NAMES_AR_BY_BOOK.get(key, {}).get(section_number)
            conn.execute(
                "INSERT INTO hadith_chapters (id, book_id, chapter_number, name_en, name_ar) VALUES (?,?,?,?,?)",
                (chapter_id, book_index, section_number, name, chapter_name_ar),
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
            section_number = h.get("reference", {}).get("book")
            chapter_id = chapter_ids.get(section_number)
            conn.execute(
                "INSERT INTO hadiths (id, book_id, chapter_id, hadith_number, text, text_search) VALUES (?,?,?,?,?,?)",
                (hadith_id, book_index, chapter_id, h["hadithnumber"], text, normalize_search_text(text)),
            )

        if book_count < min_count:
            sys.exit(f"فشل التحقق: كتاب {name_ar} فيه {book_count} حديث فقط، أقل من الحد الأدنى المتوقَّع {min_count}")

        print(f"  {name_ar}: {book_count} حديث")

    conn.execute("INSERT INTO fts_hadiths(rowid, text_search) SELECT id, text_search FROM hadiths")
    # رُفع لـ٣ مع إضافة عمود hadith_chapters.name_ar (تغيير بنية فعلي) —
    # يطابق HadithDatabase.schemaVersion بطبقة drift حرفياً، ارفعهما معاً دائماً.
    conn.execute("PRAGMA user_version = 3")

    (total,) = conn.execute("SELECT COUNT(*) FROM hadiths").fetchone()
    (books_count,) = conn.execute("SELECT COUNT(*) FROM hadith_books").fetchone()
    (chapters_count,) = conn.execute("SELECT COUNT(*) FROM hadith_chapters").fetchone()
    (unassigned,) = conn.execute("SELECT COUNT(*) FROM hadiths WHERE chapter_id IS NULL").fetchone()
    if books_count != len(BOOKS):
        sys.exit(f"فشل التحقق النهائي: {books_count} كتاب != {len(BOOKS)}")
    if chapters_count < 90:  # البخاري وحده فيه ٩٧ باباً معروفاً
        sys.exit(f"فشل التحقق: {chapters_count} باب فقط بكل المجموعات، أقل من المتوقَّع")
    if unassigned > 0:
        sys.exit(f"فشل التحقق: {unassigned} حديث بلا باب معروف (chapter_id NULL) — تحقّق من ربط reference.book")

    # الاكتمال الإجباري لاسم الباب العربي مقصور على الكتب المُترجَمة يدوياً
    # (راجع تعليق BOOKS أعلاه) — باقي الكتب name_ar فيها NULL متوقَّع
    # ومقبول، الواجهة تعرض name_en بدله بدل ما نمنع البناء أو نخترع ترجمة.
    curated_book_ids = [i for i, (key, *_rest) in enumerate(BOOKS, start=1) if key in CHAPTER_NAMES_AR_BY_BOOK]
    placeholders = ",".join("?" * len(curated_book_ids))
    (missing_ar,) = conn.execute(
        f"SELECT COUNT(*) FROM hadith_chapters WHERE name_ar IS NULL AND book_id IN ({placeholders})",
        curated_book_ids,
    ).fetchone()
    if missing_ar > 0:
        sys.exit(f"فشل التحقق: {missing_ar} باباً بلا اسم عربي بكتاب مُترجَم مسبقاً — حدّث hadith_chapter_names_ar.py")

    # ⚠️ منفصل عمداً عن PRAGMA user_version أعلاه (يطابق HadithDatabase.
    # schemaVersion البنيوي، ثابت لأن بنية الجداول لم تتغيّر). هذا الرقم
    # هو آلية إجبار إعادة نسخ الـ asset لأجهزة نزّلت التطبيق قبل توسعة
    # الكتب الستة الإضافية (٢٠٢٦-٠٨-١٩) — رُفع من ٣ إلى ٤ رغم ثبات البنية،
    # نفس نمط quran_db_version.txt (راجع تعليقها بـbuild_quran_db.py).
    (OUT_DIR / "hadith_db_version.txt").write_text("4", encoding="utf-8")

    conn.commit()
    conn.close()

    size_kb = OUT_DB.stat().st_size / 1024
    print(f"تم بنجاح: {OUT_DB} ({size_kb:.0f} كيلوبايت)")
    print(f"  كتب: {books_count}  أبواب: {chapters_count}  أحاديث: {total}")


if __name__ == "__main__":
    main()
