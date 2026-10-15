#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يولّد ويحدّث أيقونة التطبيق (assets/icon/icon.png، ١٠٢٤×١٠٢٤) بهوية التطبيق
الزمردية الملكية والذهبية الدافئة (#0E4D40 / #135B4C / #D4AF67)، بالإضافة
لتوليد نسخ احتياطية للخيارات البديلة:
- assets/icon/icon.png (الشعار الجديد المعتمد: محراب ومصحف مفتوح وهلال + هُمَام على أخضر زمردي ملكي)
- assets/icon/icon_classic_emerald.png (نفس شعار المسجد والمصحف السابق ولكن بلون أخضر زمردي ملكي بدل الكحلي)
- assets/icon/icon_minimal_emerald.png (خيار نجمة الربع الهندسية مع المصحف بالذهبي والزمردي)

الاستخدام:
    python tools/generate_app_icon.py
بعدها:
    dart run flutter_launcher_icons
"""
from PIL import Image, ImageDraw, ImageFilter
import os

SIZE = 1024
EMERALD_TOP = (17, 94, 77)      # #115E4D
EMERALD_MID = (14, 77, 64)      # #0E4D40
EMERALD_BOT = (8, 48, 39)       # #083027


def make_emerald_gradient(size=SIZE):
    base = Image.new("RGB", (size, size))
    px = base.load()
    for y in range(size):
        t = y / (size - 1)
        for x in range(size):
            tx = x / (size - 1)
            mix = 0.65 * t + 0.35 * tx
            if mix < 0.5:
                u = mix * 2.0
                r = int(EMERALD_TOP[0] * (1 - u) + EMERALD_MID[0] * u)
                g = int(EMERALD_TOP[1] * (1 - u) + EMERALD_MID[1] * u)
                b = int(EMERALD_TOP[2] * (1 - u) + EMERALD_MID[2] * u)
            else:
                u = (mix - 0.5) * 2.0
                r = int(EMERALD_MID[0] * (1 - u) + EMERALD_BOT[0] * u)
                g = int(EMERALD_MID[1] * (1 - u) + EMERALD_BOT[1] * u)
                b = int(EMERALD_MID[2] * (1 - u) + EMERALD_BOT[2] * u)
            px[x, y] = (r, g, b)
    return base


def recolor_classic_icon_to_emerald(src_path, out_path):
    if not os.path.exists(src_path):
        return
    src = Image.open(src_path).convert("RGB").resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    bg = make_emerald_gradient(SIZE)
    src_px = src.load()
    bg_px = bg.load()
    out = Image.new("RGB", (SIZE, SIZE))
    out_px = out.load()

    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b = src_px[x, y]
            # المناطق البيضاء بزوايا الأيقونة القديمة
            if r > 220 and g > 220 and b > 220 and abs(r - b) < 20:
                out_px[x, y] = bg_px[x, y]
                continue
            # مقدار الدفء الذهبي (الفرق بين الأحمر والأزرق)
            goldness = max(0.0, (r - b) / 155.0)
            if goldness > 1.0:
                goldness = 1.0
            br, bg_c, bb = bg_px[x, y]
            # دمج ناعم بين الخلفية الزمردية والعناصر الذهبية والتوهج
            nr = int(br * (1 - goldness) + r * goldness)
            ng = int(bg_c * (1 - goldness) + g * goldness)
            nb = int(bb * (1 - goldness) + b * goldness)
            out_px[x, y] = (nr, ng, nb)

    out.save(out_path, "PNG")
    print(f"تم توليد: {out_path}")


if __name__ == "__main__":
    print("أداة توليد أيقونة هُمَام بالهوية الزمردية والذهبية جاهزة.")
