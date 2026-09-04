import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/tajweed/tajweed_data.dart';

void main() {
  group('موسوعة أحكام التجويد (TajweedData)', () {
    test('تحتوي على جميع الأحكام الأساسية برواية حفص عن عاصم', () {
      expect(TajweedData.allRules.isNotEmpty, isTrue);
      expect(TajweedData.allRules.length, greaterThanOrEqualTo(8));

      // التحقق من وجود أبواب التجويد الجوهرية
      final categories = TajweedData.allRules.map((r) => r.category).toSet();
      expect(categories.contains('أحكام النون الساكنة والتنوين'), isTrue);
      expect(categories.contains('أحكام الميم الساكنة'), isTrue);
      expect(categories.contains('أحكام المدود'), isTrue);
      expect(categories.contains('صفات ومخارج الحروف'), isTrue);
    });

    test('كل حكم يحتوي على تعريف، حروف، شرح، وأمثلة قرآنية صالحة', () {
      for (final rule in TajweedData.allRules) {
        expect(rule.title.isNotEmpty, isTrue);
        expect(rule.definition.isNotEmpty, isTrue);
        expect(rule.letters.isNotEmpty, isTrue);
        expect(rule.explanation.isNotEmpty, isTrue);
        expect(rule.examples.isNotEmpty, isTrue);

        for (final ex in rule.examples) {
          expect(ex.surah.isNotEmpty, isTrue);
          expect(ex.ayah, greaterThan(0));
          expect(ex.versePart.isNotEmpty, isTrue);
          expect(ex.highlightedWord.isNotEmpty, isTrue);
        }
      }
    });

    test('علامات الوقف والضبط في المصحف تحتوي على الرموز القرآنية الستة الأساسية', () {
      expect(TajweedData.stopMarks.length, greaterThanOrEqualTo(6));
      final symbols = TajweedData.stopMarks.map((m) => m.symbol).toList();
      expect(symbols.contains('مـ'), isTrue);
      expect(symbols.contains('لا'), isTrue);
      expect(symbols.contains('ج'), isTrue);
      expect(symbols.contains('صلى'), isTrue);
      expect(symbols.contains('قلى'), isTrue);
    });
  });
}
