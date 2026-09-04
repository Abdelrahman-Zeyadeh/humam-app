#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يدمج جدول `mutashabihat` (آيات متشابهة اللفظ، بما فيها عبر سور مختلفة) من
`raw/matching-ayah.db` الخام — راجع raw/README.md لتفاصيل المصدر والترخيص.

كل صف بالمصدر اتجاه واحد فقط (`verse_key` → `matched_ayah_key`)، **والمصدر
نفسه يخزّن الاتجاهين كصفّين منفصلين مستقلّين** (تحقّقنا يدوياً: `27:30` له
صف عكسي مستقل لـ`1:1` بمدى/تغطية مختلفين حسب طول كل آية) — فلا حاجة لتوليد
الاتجاه المعاكس هون، مجرّد نسخ حرفي لكل صف كما هو.
"""
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

SCHEMA = """
CREATE TABLE mutashabihat (
  ayah_id INTEGER NOT NULL,
  similar_ayah_id INTEGER NOT NULL,
  match_words_range TEXT
);
CREATE INDEX idx_mutashabihat_ayah ON mutashabihat(ayah_id);
"""


def _parse_key(raw: str) -> tuple[int, int]:
    surah, ayah = raw.split(":")
    return int(surah), int(ayah)


def merge_mutashabihat(
    conn: sqlite3.Connection,
    raw_dir: Path,
    ayah_id_by_key: dict[tuple[int, int], int],
) -> None:
    raw_db_path = raw_dir / "matching-ayah.db"
    if not raw_db_path.exists():
        sys.exit(f"خطأ: الملف الخام غير موجود: {raw_db_path}")

    conn.executescript(SCHEMA)

    src = sqlite3.connect(raw_db_path)
    rows = src.execute(
        "SELECT verse_key, matched_ayah_key, match_words_range FROM similar_ayahs"
    ).fetchall()
    src.close()

    if not rows:
        sys.exit("فشل التحقق: matching-ayah.db بلا صفوف")

    for verse_key, matched_key, match_range in rows:
        ayah_id = ayah_id_by_key.get(_parse_key(verse_key))
        similar_ayah_id = ayah_id_by_key.get(_parse_key(matched_key))
        if ayah_id is None or similar_ayah_id is None:
            sys.exit(f"فشل التحقق: مفتاح متشابهات غير موجود {verse_key} أو {matched_key}")
        conn.execute(
            "INSERT INTO mutashabihat (ayah_id, similar_ayah_id, match_words_range) VALUES (?,?,?)",
            (ayah_id, similar_ayah_id, match_range),
        )

    (count,) = conn.execute("SELECT COUNT(*) FROM mutashabihat").fetchone()
    if count != len(rows):
        sys.exit(f"فشل التحقق النهائي: أُدرج {count} صف متشابهات != المصدر {len(rows)}")
