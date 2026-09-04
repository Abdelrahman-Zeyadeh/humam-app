#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يجلب تفاسير إضافية من `spa5k/tafsir_api` (نفس مصدر fetch_extra_tafsirs.py،
ترخيص MIT للكود، النص الفعلي أصله qul.tarteel.ai — نفس التحفّظ المقبول
أصلاً بالمشروع) ويبنيها مباشرة كملفات `.db` جاهزة للرفع، **بلا حاجة لإعادة
بناء quran.db الكاملة** (tools/raw/ وملفات QUL الخام غير موجودين حالياً
على هذا الجهاز) — بدلاً من ذلك يستخدم جدول `ayahs` بالنسخة المشحونة
`assets/quran/quran.db` (لسا كاملاً رغم تفريغ جدول tafsirs) لتحويل
(surah, ayah) → ayah_id مباشرة.

المخطط الناتج مطابق حرفياً لـ`split_tafsir_editions.py`:
  meta(id, edition, ayah_count) + texts(ayah_id PK, body)

**تغطية جزئية مسموحة الآن** (خلاف `split_tafsir_editions.py` الأصلي
اللي يفرض ٦٢٣٦ بالضبط): بعض المصادر (تفسير ابن عثيمين تحديداً — تحقّقت
مباشرة: `.../tafsir-ibn-uthaymeen/7.json` يرجع HTTP 200 بمصفوفة فارغة
`[]` فعلياً، لا خطأ شبكة) تغطّي جزءاً من القرآن فقط لأن المصدر الأصلي نفسه
جزئي (الشيخ رحمه الله لم يفسّر كل القرآن كاملاً). `ayah_count` بجدول
`meta` يعكس التغطية الفعلية الحقيقية لا ٦٢٣٦ افتراضية.

الاستخدام:
    python tools/fetch_build_new_tafsir_editions.py
"""
from __future__ import annotations

import json
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

# طرفية Windows هون بترمز CP1256 (عربي) لا UTF-8 — أي رمز خارج نطاقها
# (✅، الأسهم...) كان يفشل الطباعة (`UnicodeEncodeError`) على stdout
# **و**stderr معاً (لازم الاثنان، لا واحد بس — نسيان stderr هون بالضبط
# سبَّب فشلاً ثانياً بجولة سابقة رغم إصلاح stdout).
for _stream in (sys.stdout, sys.stderr):
    if _stream.encoding and _stream.encoding.lower() != "utf-8":
        _stream.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent
QURAN_DB = ROOT.parent / "assets" / "quran" / "quran.db"
OUT_DIR = ROOT / "tafsir_editions"
SURAH_COUNT = 114
EXPECTED_AYAHS = 6236
BASE = "https://raw.githubusercontent.com/spa5k/tafsir_api/main/tafsir"

# (مفتاح الكتالوج بالتطبيق, slug بمستودع tafsir_api) — الفجوات العشر
# الحالية بـ`tafsir_edition_catalog.dart` (kEmbeddedTafsirEditions فارغ،
# الأربعة الأخرى (jalalayn/muyassar/saadi/ibnkathir) مرفوعة أصلاً).
EDITIONS: list[tuple[str, str]] = [
    ("mukhtasar", "ar-tafsir-al-mukhtasar"),
    ("uthaymeen", "tafsir-ibn-uthaymeen"),
    ("adwaa", "adwa-al-bayan"),
    ("baghawi", "ar-tafsir-al-baghawi"),
    ("tabari", "ar-tafsir-al-tabari"),
    ("qurtubi", "ar-tafseer-al-qurtubi"),
    ("irab_muyassar", "al-i-rab-al-muyassar"),
    ("irab_darwish", "i-rab-al-quran-li-al-darwish"),
    ("irab_jadwal", "al-jadwal-fi-i-rab-al-quran"),
    ("words_meanings", "al-muyassar-fi-al-gharib"),
]

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


def _fetch_json(url: str, retries: int = 4) -> list[dict] | None:
    """يرجع `None` فقط لو الرابط نفسه غير موجود (٤٠٤) — مش خطأ شبكة عابر."""
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            result = subprocess.run(
                ["curl", "-sS", "--fail", "--max-time", "60", url],
                capture_output=True,
            )
            if result.returncode != 0:
                # curl --fail يرجع 22 لأي HTTP >= 400 — نفرّق 404 (غياب حقيقي)
                # عن أعطال عابرة (مهلة/DNS) بإعادة محاولة الأخيرة بلا --fail.
                probe = subprocess.run(
                    ["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "30", url],
                    capture_output=True,
                )
                code = probe.stdout.decode().strip()
                if code == "404":
                    return None
                raise RuntimeError(f"HTTP {code}")
            return json.loads(result.stdout.decode("utf-8"))
        except (RuntimeError, json.JSONDecodeError) as e:
            last_err = e
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"فشل الجلب بعد {retries} محاولات: {url}") from last_err


def _ayah_id_lookup() -> dict[tuple[int, int], int]:
    conn = sqlite3.connect(QURAN_DB)
    rows = conn.execute("SELECT id, surah, ayah FROM ayahs").fetchall()
    conn.close()
    if len(rows) != EXPECTED_AYAHS:
        sys.exit(f"عدد آيات quran.db غير متوقَّع: {len(rows)}")
    return {(surah, ayah): ayah_id for ayah_id, surah, ayah in rows}


def build_edition(key: str, slug: str, lookup: dict[tuple[int, int], int]) -> None:
    out_path = OUT_DIR / f"tafsir_{key}.db"
    if out_path.exists():
        try:
            existing = sqlite3.connect(out_path)
            (n,) = existing.execute("SELECT COUNT(*) FROM texts").fetchone()
            existing.close()
            if n > 0:
                print(f"-- {key}: موجود مسبقاً ({n} آية) — تخطّي")
                return
        except sqlite3.Error:
            pass  # ملف تالف/ناقص من محاولة سابقة — أعد بناءه

    print(f"جلب {key} ({slug})...")
    pairs: list[tuple[int, str]] = []
    seen: set[tuple[int, int]] = set()
    empty_surahs: list[int] = []
    for surah in range(1, SURAH_COUNT + 1):
        url = f"{BASE}/{slug}/{surah}.json"
        rows = _fetch_json(url)
        if rows is None or not isinstance(rows, list) or not rows:
            empty_surahs.append(surah)
            print(f"  {key}: سورة {surah}/{SURAH_COUNT} — لا محتوى بالمصدر (تخطّي)")
            continue
        for row in rows:
            s, a = int(row["surah"]), int(row["ayah"])
            if (s, a) in seen:
                continue  # بعض المصادر تكرر صفوفاً (تعليقات معترضة) — الأول يفوز
            seen.add((s, a))
            ayah_id = lookup.get((s, a))
            if ayah_id is None:
                print(f"  !! تحذير: لا مطابقة لـ(surah={s}, ayah={a}) — تُجوهَل")
                continue
            pairs.append((ayah_id, row["text"]))
        print(f"  {key}: سورة {surah}/{SURAH_COUNT} ({len(rows)} صف)")

    if not pairs:
        print(f"!! {key}: صفر آيات مجموعة — تخطّي كلياً بلا كتابة ملف")
        return
    pairs.sort(key=lambda p: p[0])

    if out_path.exists():
        out_path.unlink()
    dst = sqlite3.connect(out_path)
    dst.executescript(SCHEMA)
    dst.execute("INSERT INTO meta VALUES (1, ?, ?)", (key, len(pairs)))
    dst.executemany("INSERT INTO texts VALUES (?, ?)", pairs)
    dst.commit()
    dst.execute("VACUUM")
    dst.close()

    size_mb = out_path.stat().st_size / 1024 / 1024
    coverage = len(pairs) / EXPECTED_AYAHS * 100
    flag = "" if len(pairs) == EXPECTED_AYAHS else f"  [تغطية جزئية {coverage:.0f}% — {len(empty_surahs)} سورة بلا محتوى بالمصدر]"
    print(f"== {key}: {len(pairs)} آية -> {out_path} ({size_mb:.1f} ميجا){flag}")


def main() -> None:
    if not QURAN_DB.exists():
        sys.exit(f"غير موجود: {QURAN_DB}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    lookup = _ayah_id_lookup()
    for key, slug in EDITIONS:
        try:
            build_edition(key, slug, lookup)
        except Exception as e:  # لا نوقف بقية التفاسير بسبب واحد فشل
            print(f"!! {key}: فشل كلياً — {e}")
    print(f"-> انتهى. الملفات الجاهزة بـ {OUT_DIR} — ارفعها لنفس إصدار Tafsir-v1 بمستودع humam-app-assets.")


if __name__ == "__main__":
    main()
