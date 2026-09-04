#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يجلب تفاسير الميسر/السعدي/ابن كثير (١١٤ ملف سورة لكل واحد) من مستودع
`spa5k/tafsir_api` (GitHub, ترخيص MIT — يغطّي **كود المستودع فقط**، لا نص
التفاسير نفسه؛ جدول "Source" بملف README الخاص به يُرجع الثلاثة لـ
`qul.tarteel.ai` — نفس مصدر QUL المعلّق ترخيصه أصلاً بمشروعنا (راجع
tools/raw/README.md، بند "ترخيص خطوط/بيانات QUL"). أُضيفت بموافقة صريحة
من صاحب المشروع بعد اطّلاعه على هذا التحفّظ، لا بحسم قانوني مستقل.

يدمج كل ملفات السور الـ١١٤ لكل تفسير بملف خام واحد مسطّح (قائمة
{surah, ayah, text}) بنمط ملفات tools/raw/ الأخرى، ليقرأه quran_texts.py
لاحقاً بنفس منطق ara-jalaladdinalmah.json.

الاستخدام: python3 tools/fetch_extra_tafsirs.py
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

RAW_DIR = Path(__file__).parent / "raw"
SURAH_COUNT = 114
BASE = "https://raw.githubusercontent.com/spa5k/tafsir_api/main/tafsir"

# (اسم الحقل بالمخطط، slug بمستودع tafsir_api)
EDITIONS = [
    ("muyassar", "ar-tafsir-muyassar"),
    ("saadi", "ar-tafseer-al-saddi"),
    ("ibnkathir", "ar-tafsir-ibn-kathir"),
]


def _fetch_json(url: str, retries: int = 3) -> list[dict]:
    # `urllib` بمترجم MSYS2 هون بلا حزمة شهادات جذر صالحة (SSL verify يفشل) —
    # `curl` (مُتحقَّق شغّال بهذه البيئة سابقاً) يستخدم مخزن شهادات النظام
    # مباشرة، فيتجاوز المشكلة بلا تعطيل التحقّق (لا `-k`/`--insecure`).
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            result = subprocess.run(
                ["curl", "-sS", "--fail", "--max-time", "60", url],
                capture_output=True,
                check=True,
            )
            return json.loads(result.stdout.decode("utf-8"))
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            last_err = e
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"فشل الجلب بعد {retries} محاولات: {url}") from last_err


def fetch_edition(edition_key: str, slug: str) -> None:
    out_path = RAW_DIR / f"tafsir_{edition_key}.json"
    merged: list[dict] = []
    for surah in range(1, SURAH_COUNT + 1):
        url = f"{BASE}/{slug}/{surah}.json"
        rows = _fetch_json(url)
        if not isinstance(rows, list) or not rows:
            sys.exit(f"فشل التحقق: {slug} سورة {surah} — استجابة فارغة/غير متوقَّعة")
        for row in rows:
            merged.append({"surah": row["surah"], "ayah": row["ayah"], "text": row["text"]})
        print(f"  {edition_key}: سورة {surah}/{SURAH_COUNT} ({len(rows)} آية)")
    if len(merged) != 6236:
        sys.exit(f"فشل التحقق النهائي: {edition_key} جمع {len(merged)} آية != 6236")
    out_path.write_text(json.dumps(merged, ensure_ascii=False), encoding="utf-8")
    print(f"✅ {edition_key}: {len(merged)} آية → {out_path}")


def main() -> None:
    RAW_DIR.mkdir(exist_ok=True)
    for edition_key, slug in EDITIONS:
        print(f"جلب {edition_key} ({slug})...")
        fetch_edition(edition_key, slug)


if __name__ == "__main__":
    main()
