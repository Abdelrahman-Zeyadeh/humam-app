#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تطبيع نص عربي للبحث (حذف تشكيل + توحيد حروف متشابهة رسماً) — مشترك بين
`build_quran_db.py` و`build_hadith_db.py`. **يجب** تطبيق نفس المنطق على
مدخل المستخدم وقت البحث (`arabic_normalizer.dart` بطرف Dart).
"""
from __future__ import annotations

import re

_DIACRITICS = re.compile(
    "[" + "".join(
        chr(c) for c in list(range(0x0610, 0x061B)) + list(range(0x064B, 0x0653))
        + list(range(0x0656, 0x065F + 1)) + list(range(0x06D6, 0x06ED + 1))
        + [0x0670]
    ) + "]"
)


def normalize_search_text(text: str) -> str:
    t = _DIACRITICS.sub("", text)
    t = t.replace("ـ", "")  # تطويل
    t = re.sub("[آأإٱ]", "ا", t)  # أإآٱ -> ا
    t = t.replace("ة", "ه")  # ة -> ه
    t = t.replace("ى", "ي")  # ى -> ي
    return t


def strip_diacritics(text: str) -> str:
    return _DIACRITICS.sub("", text).replace("ـ", "")
