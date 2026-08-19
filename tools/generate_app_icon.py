#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
يولّد أيقونة التطبيق (assets/icon/icon.png، ١٠٢٤×١٠٢٤) برمجياً — رسم
هندسي بحت (محراب/قوس مسجد مبسّط + نجمة ثمانية الرؤوس)، لا نص ولا صورة
مستوردة، بألوان الهوية المعتمدة (AppColors: navy/gold). هندسة معمارية
عامة (قوس مدوّر) لا ترمز لنص أو مصدر ديني محدَّد — لا خطر تخمين محتوى.

الاستخدام:
    python tools/generate_app_icon.py
(يحتاج Pillow: python -m pip install Pillow)

بعدها: flutter pub run flutter_launcher_icons لتوليد كل قياسات المنصّات.
"""
from PIL import Image, ImageDraw
import math

SIZE = 1024
NAVY = (11, 37, 69, 255)       # AppColors.navy #0B2545
GOLD = (201, 162, 75, 255)     # AppColors.gold #C9A24B

img = Image.new("RGBA", (SIZE, SIZE), NAVY)
draw = ImageDraw.Draw(img)

cx = SIZE // 2

# قوس المحراب (إطار ذهبي حول فراغ نفس لون الخلفية) — نصف دائرة أعلى
# القوس + مستطيل للرجلين، بنفس نصف القطر لينسجما بلا فاصل مرئي.
# الأبعاد محسوبة لتتمركز الشكل عمودياً بهامش متساوٍ أعلى وأسفل القماشة.
radius_outer = 280
straight_leg_height = 260
base_thickness = 20
total_height = radius_outer + straight_leg_height + base_thickness
margin = (SIZE - total_height) // 2  # هامش علوي/سفلي متساوٍ

dome_top_y = margin
leg_top_y = dome_top_y + radius_outer
leg_bottom_y = leg_top_y + straight_leg_height

# القوس الخارجي (ذهبي كامل)
draw.pieslice(
    [cx - radius_outer, leg_top_y - radius_outer, cx + radius_outer, leg_top_y + radius_outer],
    180, 360, fill=GOLD,
)
draw.rectangle([cx - radius_outer, leg_top_y, cx + radius_outer, leg_bottom_y], fill=GOLD)

# الفراغ الداخلي (بلون الخلفية) — يترك إطاراً ذهبياً بسماكة موحّدة.
inset = 74
radius_inner = radius_outer - inset
leg_top_y_inner = leg_top_y + inset
leg_bottom_y_inner = leg_bottom_y - inset
draw.pieslice(
    [cx - radius_inner, leg_top_y_inner - radius_inner, cx + radius_inner, leg_top_y_inner + radius_inner],
    180, 360, fill=NAVY,
)
draw.rectangle([cx - radius_inner, leg_top_y_inner, cx + radius_inner, leg_bottom_y_inner], fill=NAVY)

# قاعدة القوس (عتبة أفقية ذهبية تحته لإغلاق الشكل من الأسفل).
draw.rectangle([cx - radius_outer, leg_bottom_y - base_thickness, cx + radius_outer, leg_bottom_y], fill=GOLD)


def star_points(center, r_outer, r_inner, points, rotation_deg=0):
    pts = []
    n = points * 2
    for i in range(n):
        r = r_outer if i % 2 == 0 else r_inner
        angle = math.radians(rotation_deg + i * 360 / n)
        pts.append((center[0] + r * math.sin(angle), center[1] - r * math.cos(angle)))
    return pts


# نجمة ثمانية الرؤوس (شكل هندسي عام — لا رمزية نصّية) داخل فراغ المحراب،
# بمنتصف ارتفاع الفراغ الداخلي (بين قمة القبة الداخلية وقاعدتها).
inner_dome_top_y = leg_top_y_inner - radius_inner
star_center = (cx, (inner_dome_top_y + leg_bottom_y_inner) // 2)
draw.polygon(star_points(star_center, 92, 40, 8), fill=GOLD)

img.save("assets/icon/icon.png")
print("تم: assets/icon/icon.png (1024x1024)")
