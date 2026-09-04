#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يحوّل نسخة PDF رسمية من مجمع الملك فهد (صور صفحات ممسوحة بلا طبقة نص —
راجع tools/mushaf/README.md) لصور صفحات WebP + طبقة صناديق آيات (مو كلمات:
الضغط/وضع الحفظ بالتطبيق الحالي نفسه يعملان بدقة آية لا كلمة، راجع
mushaf_page_widget.dart — والفصل الآلي لكلمات مبررة بالكشيدة غير موثوق).

المنهجية (كل مرحلة قابلة للتحقق البصري، طُوّرت ونُقّحت بـ
tools/mushaf/dev/build_mushaf_images_prototype.py):
  1. عزل صندوق المحتوى (نص أبيض/أسود) عن الإطار الزخرفي الملوّن بقياس
     التشبّع اللوني بشرائح مركزية.
  2. كشف حزم الأسطر (بروفايل حبر أسود صفّي داخل صندوق المحتوى).
  3. كشف علامات نهاية الآية كمكوّنات حبر ملوّنة (تُدمَج قوساها العلوي
     والسفلي بالتقارب الرأسي).
  4. تقسيم كل سطر لقطع آيات: **لا يعتمد على `words.line_no`** (ثبت أنه لا
     يطابق دائماً تفاف الأسطر الفعلي بطبعة PDF معيّنة) — بدل هيك، مؤشر
     يمشي على ترتيب آيات الصفحة الكامل (`ayahs.id`، موثوق) ويستهلك آية
     لكل علامة مكتشفة فعلياً بالسطر (من اليمين لليسار)، راجع
     `build_page_ayah_boxes`.

**صفحات خاصة مستثناة حالياً** (تحتاج معالجة مخصّصة لاحقاً، راجع نقاش
الخطة): ١ و٢ (تصميم دائري لصفحتي الافتتاح)، والصفحات متعددة رؤوس السور
(587, 591, 595-604) — صورها تُحفَظ عادي بس بلا صناديق آيات (طبقة تفاعل
فاضية، الودجت يتعامل معها بلا كراش أصلاً).

الاستخدام:
    python tools/build_mushaf_page_images.py --edition normal \
        --pdf "tools/mushaf/الحجم العادي (الأخضر).pdf" --pdf-offset 2

يفشل بخطأ واضح لأي صفحة "عادية" (غير بالقائمة المستثناة) ما تطابق فيها
عدد الأسطر/الآيات المتوقع — لا يُكتب صندوق خاطئ صامتاً أبداً.
"""
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

import numpy as np
import pymupdf
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "assets" / "quran" / "quran.db"

MUSHAF_PAGE_COUNT = 604
# أبعاد الصفحة الفعلية (بالنقاط) تختلف جوهرياً بين نسخ PDF (تحقّقت: normal
# ٣٨٢×٥٤٧، premium ٤٥٤×٦٥٢، jawamie ٥٥٣×٧٩٤ — تنسيقات طباعة مختلفة فعلياً
# لا مجرد اختلاف دقة مسح). كل الثوابت البكسلية تحت (SAT_THRESHOLD حتى
# NO_TRAILING_TEXT_MARGIN) عُيّرت على عرض ~1531px تحديداً (نسخة normal
# بـZoom=4) — لتبقى صالحة لأي نسخة PDF بلا معايرة يدوية منفصلة، نحسب
# عامل التكبير ديناميكياً لكل نسخة يستهدف نفس العرض المرجعي دايماً.
TARGET_PAGE_WIDTH_PX = 1531
WEBP_QUALITY = 80

SAT_THRESHOLD = 30
LINE_INK_THRESHOLD = 25
MARKER_MIN_AREA = 100  # فلتر ثانوي فقط الآن (MARKER_MIN_HEIGHT هو الفاصل الحقيقي) — يبقى كخط دفاع أول رخيص
MARKER_MIN_HEIGHT = 30  # علامة الآية الحقيقية طولها ٦٦-٦٩px ثابتاً بكل صفحة/نسخة فحصناها؛ ضجيج (نقاط زخرفية) طوله ٨-١٥px بس — فرق طول أوثق بكثير من فرق مساحة (كان يتشابه أحياناً، راجع صفحة ١٨٧)
MARKER_MERGE_Y_GAP = 80

# صفحات فيها تصميم دائري خاص أو أكثر من رأس سورة بنفس الصفحة — تُستثنى من
# التحقق الصارم مؤقتاً (صورتها تُحفظ، صناديقها فاضية لحد معالجتها لاحقاً).
KNOWN_SPECIAL_PAGES = {1, 2, 587, 591, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604}


def render_page(doc: pymupdf.Document, mushaf_page: int, pdf_offset: int, tmp_path: Path) -> Image.Image:
    idx = mushaf_page + pdf_offset
    page = doc[idx]
    zoom = TARGET_PAGE_WIDTH_PX / page.rect.width
    pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=False)
    pix.save(str(tmp_path))
    img = Image.open(tmp_path).convert("RGB")
    img.load()
    return img


BORDER_FRAC_THRESHOLD = 0.15  # نسبة بكسلات ملوّنة بالصف/العمود تُعتبر "داخل الإطار الزخرفي"


MIN_BORDER_EXIT_RUN = 15  # الإطار الزخرفي فيه فجوات بيضاء داخلية صغيرة (بين وحدات الزخرفة، أو قبل خط حدّي داخلي صلب) — لا تُعتبر خروجاً فعلياً من الإطار إلا لو استمرت لهالطول


def _find_border_inner_edge(frac: np.ndarray, n: int, from_start: bool) -> int | None:
    """يمسح من حافة الصورة للداخل: يتخطى الهامش الأبيض، يدخل الإطار
    الزخرفي الملوّن (أول نطاق `frac` عالي يلاقيه)، ويرجّع أول نقطة بعد
    خروجه منه فعلياً — أي حافة صندوق المحتوى الداخلية من هالجهة. الخروج
    "الفعلي" يحتاج نطاق منخفض مستمر ≥`MIN_BORDER_EXIT_RUN` بكسل (وإلا فجوة
    بيضاء صغيرة داخل نمط الزخرفة، أو قبل خط حدّي داخلي صلب — راجع نقاش
    صفحة ٣ نسخة normal، فجوة 2px بس قبل خط أخضر صلب 7px) بتُخرِج الماسح
    قبل أوانه فيبقى جزء من الإطار داخل صندوق المحتوى. مقاوم لأي عنصر
    ملوّن داخل صندوق المحتوى نفسه (علامة آية، لافتة سورة بمنتصف الصفحة)
    مهما كبر حجمه، لأنه ما بيدخل الصندوق من الأساس — بعكس منهج "أطول نطاق
    نظيف" السابق اللي كان ينكسر بأي انقطاع داخلي (راجع نقاش صفحة ٥٨/٥٣٤).
    """
    idxs = range(n) if from_start else range(n - 1, -1, -1)
    state = "before_border"
    low_run_start = None
    for i in idxs:
        high = frac[i] > BORDER_FRAC_THRESHOLD
        if state == "before_border":
            if high:
                state = "in_border"
        elif state == "in_border":
            if not high:
                if low_run_start is None:
                    low_run_start = i
                run_len = (i - low_run_start + 1) if from_start else (low_run_start - i + 1)
                if run_len >= MIN_BORDER_EXIT_RUN:
                    return low_run_start
            else:
                low_run_start = None
    return None


def find_content_box(img: Image.Image) -> tuple[int, int, int, int] | None:
    arr = np.array(img).astype(np.int32)
    h, w, _ = arr.shape
    sat = arr.max(axis=2) - arr.min(axis=2)
    colored = sat > SAT_THRESHOLD

    cx0, cx1 = int(w * 0.25), int(w * 0.75)
    row_frac = colored[:, cx0:cx1].mean(axis=1)
    top = _find_border_inner_edge(row_frac, h, from_start=True)
    bot = _find_border_inner_edge(row_frac, h, from_start=False)
    if top is None or bot is None or bot <= top:
        return None

    cy0, cy1 = top + 20, bot - 20
    if cy1 <= cy0:
        return None
    col_frac = colored[cy0:cy1, :].mean(axis=0)
    left = _find_border_inner_edge(col_frac, w, from_start=True)
    right = _find_border_inner_edge(col_frac, w, from_start=False)
    if left is None or right is None or right <= left:
        return None
    return left, top, right, bot


def _line_bands_at_threshold(rp: np.ndarray, h: int, threshold: int) -> list[tuple[int, int]]:
    in_band = rp > threshold
    bands = []
    start = None
    for y in range(h):
        if in_band[y] and start is None:
            start = y
        elif not in_band[y] and start is not None:
            bands.append((start, y))
            start = None
    if start is not None:
        bands.append((start, h))
    merged: list[list[int]] = []
    for b in bands:
        if merged and b[0] - merged[-1][1] < 8:
            merged[-1][1] = b[1]
        else:
            merged.append(list(b))
    return [tuple(b) for b in merged if b[1] - b[0] > 20]


def find_line_bands(content_img: Image.Image, expected_count: int | None = None) -> list[tuple[int, int]]:
    """يكشف حزم الأسطر عبر بروفايل حبر صفّي. بعض الأسطر المتجاورة (سطر
    فيه نازلات حروف طويلة تلامس صاعدات السطر التالي تقريباً) ما تنفصل
    بعتبة ثابتة — لو مرّرنا `expected_count` (عدد الأسطر المعروف من
    قاعدة البيانات)، نجرّب عتبات أعلى تدريجياً لحد ما نلاقي وحدة تعطي
    العدد المطلوب بالضبط، بدل الاعتماد على رقم سحري وحيد يفشل بصفحات
    معيّنة (راجع نقاش المحادثة — صفحات فيها اندماج سطرين).
    """
    arr = np.array(content_img.convert("L"))
    h, _ = arr.shape
    ink = arr < 120
    rp = ink.sum(axis=1)

    bands = _line_bands_at_threshold(rp, h, LINE_INK_THRESHOLD)
    if expected_count is None or len(bands) == expected_count:
        return bands
    for threshold in range(LINE_INK_THRESHOLD + 5, 251, 5):
        candidate = _line_bands_at_threshold(rp, h, threshold)
        if len(candidate) == expected_count:
            return candidate
    return bands  # فشل التكيّف — نرجّع أفضل محاولة، يفشل التحقق اللاحق بوضوح


def find_banner_bands(content_img: Image.Image, count: int) -> list[tuple[int, int]]:
    """يكشف لافتات اسم سورة زخرفية بمنتصف صندوق المحتوى (انتقال بين
    سورتين قصيرتين بنفس الصفحة) — كثافة لونية عالية جداً بالصف (نمط
    زخرفي مليان) بعكس علامة آية بسيطة (نقطة صغيرة، نسبة تشبّع منخفضة
    بالصف كله). يرجّع أعلى `count` نطاق حسب الارتفاع، مرتّبة عمودياً.
    """
    arr = np.array(content_img).astype(np.int32)
    h, w, _ = arr.shape
    sat = arr.max(axis=2) - arr.min(axis=2)
    colored = sat > SAT_THRESHOLD
    cx0, cx1 = int(w * 0.1), int(w * 0.9)
    frac = colored[:, cx0:cx1].mean(axis=1)
    high = frac > 0.3
    runs: list[list[int]] = []
    start = None
    for y in range(h):
        if high[y] and start is None:
            start = y
        elif not high[y] and start is not None:
            runs.append([start, y])
            start = None
    if start is not None:
        runs.append([start, h])
    merged: list[list[int]] = []
    for r in runs:
        if merged and r[0] - merged[-1][1] < 10:
            merged[-1][1] = r[1]
        else:
            merged.append(r)
    candidates = [tuple(b) for b in merged if b[1] - b[0] > 20]
    candidates.sort(key=lambda b: b[1] - b[0], reverse=True)
    return sorted(candidates[:count])


def find_markers(content_img: Image.Image, min_area: int = MARKER_MIN_AREA) -> list[tuple[int, int, int, int]]:
    arr = np.array(content_img).astype(np.int32)
    sat = arr.max(axis=2) - arr.min(axis=2)
    colored = (sat > SAT_THRESHOLD).astype(np.uint8)
    labeled, _n = ndimage.label(colored, structure=np.ones((3, 3)))
    objs = ndimage.find_objects(labeled)
    comps = []
    for sl in objs:
        if sl is None:
            continue
        y0, y1 = sl[0].start, sl[0].stop
        x0, x1 = sl[1].start, sl[1].stop
        if (y1 - y0) * (x1 - x0) < min_area:
            continue
        if (y1 - y0) < MARKER_MIN_HEIGHT:
            # فلتر أوثق من المساحة وحدها: علامة الآية الحقيقية طولها
            # ثابت جداً بكل الصفحات وكل النسخ اللي فحصناها (٦٦-٦٩px) —
            # أي عنصر ملوّن أقصر بكثير (نقطة زخرفية فوق كلمة، فاصلة صغيرة)
            # مهما كانت مساحته قريبة من علامة حقيقية (يصير عريض بدل طويل).
            continue
        comps.append([x0, y0, x1, y1])

    comps.sort(key=lambda c: (c[0], c[1]))
    merged: list[list[int]] = []
    used = [False] * len(comps)
    for i, c in enumerate(comps):
        if used[i]:
            continue
        group = [c]
        used[i] = True
        for j in range(i + 1, len(comps)):
            if used[j]:
                continue
            c2 = comps[j]
            x_overlap = min(c[2], c2[2]) - max(c[0], c2[0])
            if x_overlap > 5 and abs(c2[1] - c[1]) < MARKER_MERGE_Y_GAP:
                group.append(c2)
                used[j] = True
        x0 = min(g[0] for g in group)
        y0 = min(g[1] for g in group)
        x1 = max(g[2] for g in group)
        y1 = max(g[3] for g in group)
        merged.append([x0, y0, x1, y1])
    return [tuple(m) for m in merged]


def line_ink_x_range(content_img: Image.Image, y0: int, y1: int) -> tuple[int, int] | None:
    arr = np.array(content_img.convert("L"))
    band = arr[y0:y1, :] < 120
    colp = band.sum(axis=0)
    nz = np.nonzero(colp)[0]
    if len(nz) == 0:
        return None
    return int(nz.min()), int(nz.max())


class PageBuildError(Exception):
    pass


# أقصى فرق (px) بين حافة أقصى علامة يسار وحافة حبر السطر اليسرى عشان
# نعتبر "ما فيه نص متبقي بعدها" (السطر ينتهي بالضبط عند العلامة، لا مقطع
# متابعة). قيمة صغيرة تحتمل هامش تنعيم/عداد بكسل بسيط فقط.
NO_TRAILING_TEXT_MARGIN = 50


def _make_box(ayah_id: int, x0: int, x1: int, y0: int, y1: int, left: int, top: int, fw: int, fh: int) -> dict:
    abs_x0 = left + x0
    abs_x1 = left + x1
    abs_y0 = top + y0
    abs_y1 = top + y1
    return {
        "ayah_id": ayah_id,
        "x": abs_x0 / fw,
        "y": abs_y0 / fh,
        "w": (abs_x1 - abs_x0) / fw,
        "h": (abs_y1 - abs_y0) / fh,
    }


def build_page_ayah_boxes(
    conn: sqlite3.Connection,
    full_img: Image.Image,
    content_box: tuple[int, int, int, int],
    page: int,
    marker_min_area: int = MARKER_MIN_AREA,
) -> list[dict]:
    """يبني صناديق الآيات اعتماداً على **ترتيب الآيات الكامل بالصفحة**
    (موثوق، من `ayahs.id`) وعدد العلامات المكتشفة فعلياً بكل سطر بالصورة
    — لا يعتمد على `words.line_no` إطلاقاً، لأنه ثبت عملياً أنه لا يطابق
    دائماً تفاف الأسطر الفعلي بطبعة PDF معيّنة (فرق سطر واحد أحياناً بين
    تخطيط QCF الحي وهاي الطبعة المطبوعة تحديداً).
    """
    left, top, right, bot = content_box
    content_img = full_img.crop(content_box)
    fw, fh = full_img.size

    line_types = conn.execute(
        "select line_no, line_type from page_lines where page=? order by line_no", (page,)
    ).fetchall()
    # اسم السورة (surah_name) بأول الصفحة (line_no=1) بإطار زخرفي منفصل
    # بذاته — صندوق المحتوى يستثنيه تلقائياً (نفس منطق استثناء الإطار
    # الخارجي، لا صندوق آية له أصلاً). لكن اسم سورة **بمنتصف الصفحة**
    # (انتقال بين سورتين قصيرتين بنفس الصفحة، لا إطار زخرفي منفصل) بيظهر
    # كسطر حبر عادي بالصورة — يُحسَب ضمن العدد المتوقع (بلا صندوق آية له،
    # زي البسملة بالضبط) وإلا ينكسر العدّ.
    content_line_types = [lt for lt in line_types if not (lt[1] == "surah_name" and lt[0] == 1)]
    mid_surah_lines = [lt for lt in content_line_types if lt[1] == "surah_name"]

    # اسم سورة بمنتصف الصفحة مو دايماً لافتة زخرفية ملوّنة — بعض الطبعات
    # (لاحظنا بـnormal، صفحة ٧٦ مثلاً) بترسمها كسطر نص عادي بلا زخرفة.
    # نجرّب الأسلوب البسيط أول (كل الأسطر بما فيها اسم السورة = سطر حبر
    # عادي واحد)، ولو فشل ووجد اسم سورة بمنتصف الصفحة، نجرّب عزل لافتة
    # ملوّنة كبديل (نمط premium/jawamie، راجع نقاش صفحة ٥٣٤).
    line_bands = find_line_bands(content_img, expected_count=len(content_line_types))
    if len(line_bands) != len(content_line_types) and mid_surah_lines:
        text_line_types = [lt for lt in content_line_types if lt[1] != "surah_name"]
        banner_bands = find_banner_bands(content_img, len(mid_surah_lines))
        if len(banner_bands) != len(mid_surah_lines):
            raise PageBuildError(
                f"اكتُشف {len(line_bands)} سطر بس المتوقع {len(content_line_types)}، ولقيت "
                f"{len(banner_bands)} لافتة سورة ملوّنة بس المتوقع {len(mid_surah_lines)}"
            )
        masked_img = content_img.copy()
        draw_arr = np.array(masked_img)
        for by0, by1 in banner_bands:
            draw_arr[by0:by1, :] = 255
        masked_img = Image.fromarray(draw_arr)

        text_bands = find_line_bands(masked_img, expected_count=len(text_line_types))
        if len(text_bands) != len(text_line_types):
            raise PageBuildError(
                f"اكتُشف {len(text_bands)} سطر نصي بس المتوقع {len(text_line_types)} (بعد استثناء اللافتات)"
            )
        line_bands = sorted(list(banner_bands) + list(text_bands), key=lambda b: b[0])
    elif len(line_bands) != len(content_line_types):
        raise PageBuildError(
            f"اكتُشف {len(line_bands)} سطر بس المتوقع {len(content_line_types)} (بعد استثناء اسم السورة الأول)"
        )

    markers = find_markers(content_img, min_area=marker_min_area)
    ayah_sequence = [
        row[0] for row in conn.execute("select id from ayahs where page=? order by id", (page,)).fetchall()
    ]
    if not ayah_sequence:
        raise PageBuildError("لا آيات مسجّلة لهذه الصفحة بجدول ayahs")

    boxes: list[dict] = []
    cursor = 0  # مؤشر على ayah_sequence — الآية "المفتوحة" حالياً (بدأت ولسا ما خلصت)

    for (line_no, line_type), (y0, y1) in zip(content_line_types, line_bands):
        if line_type != "ayah":
            continue

        line_markers = [m for m in markers if y0 - 10 <= (m[1] + m[3]) / 2 <= y1 + 10]
        line_markers.sort(key=lambda m: m[0])  # تصاعدي x (يسار أولاً)
        k = len(line_markers)

        ink_range = line_ink_x_range(content_img, y0, y1)
        if ink_range is None:
            raise PageBuildError(f"سطر {line_no} بلا حبر إطلاقاً")
        lx0, lx1 = ink_range

        if cursor >= len(ayah_sequence):
            raise PageBuildError(f"سطر {line_no} — علامات أكتر من الآيات المتاحة بالصفحة")

        if k == 0:
            # السطر كامل يخص الآية المفتوحة حالياً، تستمر بالسطر التالي
            ayah_id = ayah_sequence[cursor]
            boxes.append(_make_box(ayah_id, lx0, lx1, y0, y1, left, top, fw, fh))
            continue

        # k علامة => k آية تنتهي بهاد السطر، بالترتيب من اليمين لليسار
        bounds = [m[0] for m in line_markers]  # الحافة اليسرى لكل علامة (تصاعدي x)
        seg_x1 = lx1  # حد يمين القطعة الحالية (يبدأ من أقصى يمين السطر)
        for i in range(k):
            marker_x = bounds[k - 1 - i]  # من الأقصى يمين للأقصى يسار
            if cursor >= len(ayah_sequence):
                raise PageBuildError(f"سطر {line_no} — علامات أكتر من الآيات المتاحة بالصفحة")
            ayah_id = ayah_sequence[cursor]
            cursor += 1
            boxes.append(_make_box(ayah_id, marker_x, seg_x1, y0, y1, left, top, fw, fh))
            seg_x1 = marker_x

        # نص متبقٍ بعد (يسار) آخر علامة؟ يخص الآية التالية (تبدأ هون وتستمر بالسطر الجاي)
        if seg_x1 - lx0 > NO_TRAILING_TEXT_MARGIN:
            if cursor >= len(ayah_sequence):
                raise PageBuildError(f"سطر {line_no} — نص متبقٍ بلا آية تالية متاحة")
            ayah_id = ayah_sequence[cursor]
            boxes.append(_make_box(ayah_id, lx0, seg_x1, y0, y1, left, top, fw, fh))
            # ما نزيد cursor — هاي الآية لسا مفتوحة، بتكمل بالسطر التالي

    return boxes


def main() -> None:
    # بايثون بويندوز بيستخدم ترميز الطرفية الافتراضي (مو UTF-8) لما stdout
    # يكون موجَّه لملف/أنبوب (> أو |) — بيتلف كل نص عربي صامتاً بدل ما
    # يفشل. نجبره UTF-8 صراحة (بلا ما نكسر لو الوصف غير مدعوم أصلاً).
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass

    ap = argparse.ArgumentParser()
    ap.add_argument("--edition", required=True, help="معرّف النسخة (مثلاً normal)")
    ap.add_argument("--pdf", required=True, help="مسار ملف PDF المصدر")
    ap.add_argument("--pdf-offset", type=int, required=True, help="فهرس PDF (0-based) = رقم صفحة المصحف + هالقيمة")
    ap.add_argument("--out-dir", default=None, help="افتراضياً tools/mushaf/out/<edition>")
    ap.add_argument("--pages", default=None, help="نطاق اختياري مثل 1-10 (افتراضياً كل الصفحات)")
    ap.add_argument(
        "--marker-min-area",
        type=int,
        default=MARKER_MIN_AREA,
        help=(
            "أصغر مساحة (px) لمكوّن ملوّن يُعتبر جزء علامة آية — يختلف "
            "جوهرياً بين النسخ (تحقّق تجريبياً: normal~15-350، premium/"
            "jawamie~800+ بسبب علامات وقف ملوّنة أصغر بنفس النسخة). عاير "
            "لكل نسخة جديدة عبر فحص توزيع مساحات المكوّنات الملوّنة أول."
        ),
    )
    args = ap.parse_args()

    out_dir = Path(args.out_dir) if args.out_dir else ROOT / "tools" / "mushaf" / "out" / args.edition
    pages_dir = out_dir / "pages"
    pages_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = out_dir / "_render_tmp.png"

    if args.pages:
        a, b = args.pages.split("-")
        page_range = range(int(a), int(b) + 1)
    else:
        page_range = range(1, MUSHAF_PAGE_COUNT + 1)

    conn = sqlite3.connect(DB_PATH)
    doc = pymupdf.open(args.pdf)

    layout: dict[str, list[dict]] = {}
    failures: list[tuple[int, str]] = []
    ok_count = 0

    for page in page_range:
        full_img = render_page(doc, page, args.pdf_offset, tmp_path)
        webp_path = pages_dir / f"{page:03d}.webp"
        full_img.save(webp_path, "WEBP", quality=WEBP_QUALITY)

        if page in KNOWN_SPECIAL_PAGES:
            failures.append((page, "معروفة مسبقاً كصفحة خاصة (مؤجّلة)"))
            continue

        content_box = find_content_box(full_img)
        if content_box is None:
            failures.append((page, "تعذّر عزل صندوق المحتوى"))
            continue
        try:
            boxes = build_page_ayah_boxes(conn, full_img, content_box, page, marker_min_area=args.marker_min_area)
        except PageBuildError as e:
            failures.append((page, str(e)))
            continue

        layout[str(page)] = boxes
        ok_count += 1

    if tmp_path.exists():
        tmp_path.unlink()

    layout_path = out_dir / "layout.json"
    layout_path.write_text(json.dumps(layout, ensure_ascii=False), encoding="utf-8")

    total = len(page_range)
    report_lines = [
        f"تم: {ok_count} صفحة ناجحة (طبقة آيات كاملة) من أصل {total}",
        f"الصور: {pages_dir}",
        f"الطبقة: {layout_path}",
    ]
    if failures:
        report_lines.append("")
        report_lines.append(f"{len(failures)} صفحة بلا طبقة آيات (صورتها محفوظة، بس بلا صناديق تفاعل):")
        for p, reason in failures:
            report_lines.append(f"  صفحة {p}: {reason}")

    # نكتب التقرير كملف UTF-8 صريح دايماً — بغض النظر عن ترميز الطرفية
    # (لو stdout موجَّه لملف/أنبوب بويندوز بيتلف النص العربي صامتاً وإلا).
    report_path = out_dir / "build_report.txt"
    report_path.write_text("\n".join(report_lines), encoding="utf-8")

    for line in report_lines:
        print(line)


if __name__ == "__main__":
    main()
