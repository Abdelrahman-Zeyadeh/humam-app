#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يبني assets/azkar/azkar_categories.json (مكتبة حصن المسلم الكاملة، ١٣٣
قسماً) من tools/raw/hisn_almuslim.json — مصدره
https://github.com/asellam/HisnElMuslim (رخصة MIT صريحة، راجع
tools/raw/hisn_almuslim_LICENSE.md المنسوخ حرفياً من المستودع).

منفصل عمداً عن azkar.json (الصباح/المساء الحالي، Seen-Arabic) — لا نمزج
مصدرين مختلفين بملف واحد. نستثني هون قسمي "أَذْكَارُ الصَّبَاحِ" و"أَذْكَارُ
المَسَاءِ" لأنهما مغطّيان أصلاً بشاشة مخصّصة (azkar_repository.dart)
بعدّاد أدق (type صباح/مساء/كلاهما لكل ذكر منفرد)، فتفادياً للتكرار.

الاستخدام:
    python tools/build_azkar_full.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from text_normalize import strip_diacritics

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw" / "hisn_almuslim.json"
OUT = ROOT.parent / "assets" / "azkar" / "azkar_categories.json"

# مغطّيان أصلاً بشاشة الصباح/المساء المخصّصة — استبعاد تفادياً للتكرار.
# ⚠️ المطابقة بعد تجريد التشكيل (strip_diacritics) لا بالنص الحرفي —
# اكتشفنا أن نفس الكلمة "الصَّبَاحِ" قد تُكتب بترتيب تشكيل مختلف (شدّة
# قبل فتحة أو العكس) فتفشل مطابقة السلسلة الحرفية رغم تطابق الشكل
# المرئي تماماً؛ تجريد التشكيل يتجاوز هذا كلياً.
EXCLUDED_TITLES_STRIPPED = {strip_diacritics("أَذْكَارُ الصَّبَاحِ"), strip_diacritics("أَذْكَارُ المَسَاءِ")}


def main() -> None:
    if not RAW.exists():
        sys.exit(f"خطأ: الملف الخام غير موجود: {RAW}")
    with RAW.open(encoding="utf-8") as f:
        data: dict = json.load(f)

    categories = []
    total_items = 0
    excluded_count = 0
    for cat_id, (title, body) in enumerate(data.items()):
        if strip_diacritics(title) in EXCLUDED_TITLES_STRIPPED:
            excluded_count += 1
            continue
        items = []
        for it in body.get("Adhkar", []):
            text = (it.get("Text") or "").strip()
            if not text:
                continue
            items.append({
                "text": text,
                "count": it.get("Count") or 1,
                "reference": (it.get("Reference") or "").strip() or None,
            })
        if not items:
            continue
        categories.append({"id": cat_id, "title": title, "items": items})
        total_items += len(items)

    if excluded_count != 2:
        sys.exit(f"فشل التحقق: استُبعد {excluded_count} قسماً بدل ٢ (صباح+مساء) — تحقّق من تطابق العناوين")
    if len(categories) < 100:
        sys.exit(f"فشل التحقق: {len(categories)} قسم فقط بعد الاستبعاد، أقل من المتوقَّع (~١٣١)")
    if total_items < 250:  # الإجمالي الحقيقي بالمصدر ٣٠٢ عبر ١٣٣ قسماً، ٤٦ منها بقسمي الصباح/المساء المستبعدين (تحقّقنا فعلياً: يبقى ٢٥٦)
        sys.exit(f"فشل التحقق: {total_items} ذكر فقط، أقل من المتوقَّع")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(categories, ensure_ascii=False, indent=None), encoding="utf-8")

    size_kb = OUT.stat().st_size / 1024
    print(f"تم بنجاح: {OUT} ({size_kb:.0f} كيلوبايت)")
    print(f"  أقسام: {len(categories)}  أذكار: {total_items}")


if __name__ == "__main__":
    main()
