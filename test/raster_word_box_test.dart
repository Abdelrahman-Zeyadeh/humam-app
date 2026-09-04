// اختبار تفكيك `RasterWordBox.fromJson` — schema صناديق كلمات
// `layout.json` النسخ المصورة (راجع خطة `golden-cuddling-tiger.md`).
// بيانات صحيحة تُفكَّك حرفياً، وبيانات ناقصة/تالفة تُلقي استثناءً واضحاً
// بدل نتيجة صامتة خاطئة — `_rasterLayoutProvider` بـ
// `mushaf_raster_page_widget.dart` يمسك هذا الاستثناء ويرجع خريطة فاضية
// (صفحة بلا صناديق تفاعل بدل كراش الودجت)، فهذا الاختبار يوثّق أن الفشل
// **يُرمى** أصلاً ليكون هناك شيء يُمسَك.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/mushaf/mushaf_raster_page_widget.dart';

void main() {
  group('RasterWordBox.fromJson', () {
    test('بيانات صحيحة تُفكَّك حرفياً بكل الحقول', () {
      final box = RasterWordBox.fromJson({
        'id': 12,
        'ayah_id': 1,
        'x': 0.12,
        'y': 0.05,
        'w': 0.08,
        'h': 0.03,
      });

      expect(box.id, 12);
      expect(box.ayahId, 1);
      expect(box.x, 0.12);
      expect(box.y, 0.05);
      expect(box.w, 0.08);
      expect(box.h, 0.03);
    });

    test('أرقام صحيحة (int) بحقول x/y/w/h تُقبَل وتُحوَّل لـdouble (JSON لا يفرّق دائماً)', () {
      final box = RasterWordBox.fromJson({
        'id': 1,
        'ayah_id': 1,
        'x': 0,
        'y': 0,
        'w': 1,
        'h': 1,
      });

      expect(box.x, 0.0);
      expect(box.w, 1.0);
    });

    test('حقل ناقص (x مفقود) يُلقي استثناءً بدل قيمة افتراضية صامتة خاطئة', () {
      expect(
        () => RasterWordBox.fromJson({'id': 1, 'ayah_id': 1, 'y': 0.1, 'w': 0.1, 'h': 0.1}),
        throwsA(isA<TypeError>()),
      );
    });

    test('نوع خاطئ (id نص بدل رقم) يُلقي استثناءً بدل تفسير صامت خاطئ', () {
      expect(
        () => RasterWordBox.fromJson({'id': 'twelve', 'ayah_id': 1, 'x': 0, 'y': 0, 'w': 0, 'h': 0}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
