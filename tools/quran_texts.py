#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يدمج التفسير والترجمة بجدولي `tafsirs` و`translations`. المصدر لكليهما
نفس مشروع `fawazahmed0/quran-api` (رخصة Unlicense، ملك عام) المستخدم أصلاً
لنص القرآن العثماني — راجع raw/README.md لتفاصيل المصدر والتحقق.

المخطط عام (`edition` كنص) لدعم إضافة تفاسير/ترجمات أخرى لاحقاً بلا تغيير
بنية الجدول — راجع MushafPage خطة العمل، الفقرة "ب".
"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

EXPECTED_AYAHS = 6236

SCHEMA = """
CREATE TABLE tafsirs (
  id INTEGER PRIMARY KEY,
  ayah_id INTEGER NOT NULL,
  edition TEXT NOT NULL,
  text TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_tafsir_ayah_edition ON tafsirs(ayah_id, edition);

CREATE TABLE translations (
  id INTEGER PRIMARY KEY,
  ayah_id INTEGER NOT NULL,
  edition TEXT NOT NULL,
  lang TEXT NOT NULL,
  text TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_translation_ayah_edition ON translations(ayah_id, edition);
"""


def _load(path: Path) -> list[dict]:
    if not path.exists():
        sys.exit(f"خطأ: الملف الخام غير موجود: {path}")
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    rows = data["quran"]
    if len(rows) != EXPECTED_AYAHS:
        sys.exit(f"فشل التحقق: {path.name} فيه {len(rows)} سطر != {EXPECTED_AYAHS}")
    return rows


def merge_texts(
    conn: sqlite3.Connection,
    raw_dir: Path,
    ayah_id_by_key: dict[tuple[int, int], int],
) -> None:
    conn.executescript(SCHEMA)

    tafsir_rows = _load(raw_dir / "ara-jalaladdinalmah.json")
    translation_rows = _load(raw_dir / "eng-ummmuhammad.json")

    tafsir_id = 0
    for row in tafsir_rows:
        key = (row["chapter"], row["verse"])
        ayah_id = ayah_id_by_key.get(key)
        if ayah_id is None:
            sys.exit(f"فشل التحقق: تفسير الجلالين يحوي آية غير موجودة {key}")
        text = row["text"].strip()
        if not text:
            sys.exit(f"فشل التحقق: نص تفسير فارغ للآية {key}")
        tafsir_id += 1
        conn.execute(
            "INSERT INTO tafsirs (id, ayah_id, edition, text) VALUES (?,?,?,?)",
            (tafsir_id, ayah_id, "jalalayn", text),
        )

    translation_id = 0
    for row in translation_rows:
        key = (row["chapter"], row["verse"])
        ayah_id = ayah_id_by_key.get(key)
        if ayah_id is None:
            sys.exit(f"فشل التحقق: ترجمة صحيح إنترناشونال تحوي آية غير موجودة {key}")
        text = row["text"].strip()
        if not text:
            sys.exit(f"فشل التحقق: نص ترجمة فارغ للآية {key}")
        translation_id += 1
        conn.execute(
            "INSERT INTO translations (id, ayah_id, edition, lang, text) VALUES (?,?,?,?,?)",
            (translation_id, ayah_id, "en_sahih", "en", text),
        )

    (tafsir_count,) = conn.execute("SELECT COUNT(*) FROM tafsirs").fetchone()
    (translation_count,) = conn.execute("SELECT COUNT(*) FROM translations").fetchone()
    if tafsir_count != EXPECTED_AYAHS or translation_count != EXPECTED_AYAHS:
        sys.exit(
            f"فشل التحقق النهائي: تفسير={tafsir_count} ترجمة={translation_count} "
            f"(المتوقّع {EXPECTED_AYAHS} لكل منهما)"
        )
