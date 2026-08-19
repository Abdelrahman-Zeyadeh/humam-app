#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يحمّل بيانات الحزب/الرُّبع/تصنيف السجدة/ترتيب النزول من ملفات
`tools/raw/quran-metadata-{hizb,rub,sajda,surah-name}.sqlite` — مصدرها
QUL (`qul.tarteel.ai`، قسم Resources، يتطلب حساباً)، حمّلها صاحب المشروع
يدوياً بتاريخ ٢٠٢٦-٠٨-١٩. **رخصتها لم تُراجَع بعد** — نفس تحفّظ خط/تخطيط
QCF V2 نفسه (راجع بند ١ بالقائمة الموحّدة قبل النشر بـ tools/raw/README.md)،
لا نص ديني هنا أصلاً (فهرسة/تصنيف رقمي بحت)، لكن يبقى مصدرها غير محسوم
الترخيص كباقي أصول QUL.
"""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path


def _load_unit_lookup(sqlite_path: Path, table: str, number_col: str) -> dict[tuple[int, int], int]:
    """يرجع {(سورة, آية): رقم الوحدة} من جدول فيه عمود verse_mapping JSON
    بصيغة {"رقم_سورة": "أول_آية-آخر_آية", ...} لكل وحدة (حزب/ربع/جزء)."""
    conn = sqlite3.connect(sqlite_path)
    rows = conn.execute(f"SELECT {number_col}, verse_mapping FROM {table}").fetchall()
    conn.close()

    lookup: dict[tuple[int, int], int] = {}
    for number, mapping_json in rows:
        mapping = json.loads(mapping_json)
        for surah_str, range_str in mapping.items():
            surah = int(surah_str)
            start_str, end_str = range_str.split("-")
            for ayah in range(int(start_str), int(end_str) + 1):
                lookup[(surah, ayah)] = number
    return lookup


def load_hizb_lookup(raw_dir: Path) -> dict[tuple[int, int], int]:
    return _load_unit_lookup(raw_dir / "quran-metadata-hizb.sqlite", "hizbs", "hizb_number")


def load_rub_lookup(raw_dir: Path) -> dict[tuple[int, int], int]:
    return _load_unit_lookup(raw_dir / "quran-metadata-rub.sqlite", "rub", "rub_number")


def load_sajda_lookup(raw_dir: Path) -> dict[tuple[int, int], str]:
    """يرجع {(سورة, آية): 'optional' | 'required'} — تصنيف حقيقي بدل
    علامة منطقية بلا تفصيل كما كان بمصدر info.json السابق."""
    conn = sqlite3.connect(raw_dir / "quran-metadata-sajda.sqlite")
    rows = conn.execute("SELECT verse_key, sajdah_type FROM sajdah").fetchall()
    conn.close()

    lookup: dict[tuple[int, int], str] = {}
    for verse_key, sajdah_type in rows:
        surah_str, ayah_str = verse_key.split(":")
        lookup[(int(surah_str), int(ayah_str))] = sajdah_type
    return lookup


def load_revelation_order_lookup(raw_dir: Path) -> dict[int, int]:
    """يرجع {رقم_السورة: ترتيب_النزول} (١=العلق أول ما نزل...١١٤=الناس)."""
    conn = sqlite3.connect(raw_dir / "quran-metadata-surah-name.sqlite")
    rows = conn.execute("SELECT id, revelation_order FROM chapters").fetchall()
    conn.close()
    return dict(rows)
