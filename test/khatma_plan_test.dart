import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/user/user_repository.dart' show KhatmaPlan;

/// اختبارات `KhatmaPlan` — صنف بيانات نقي (لا قاعدة بيانات ولا شبكة) بعدة
/// حسابات مركّبة (نِسَب تقدّم، تواريخ متوقَّعة، حدود قصوى) كان بلا أي
/// اختبار آلي رغم أنه يغذّي التقرير الأسبوعي مباشرة (راجع
/// `weekly_report_screen.dart`: `khatmaProgressPercent`).
void main() {
  group('totalPagesToRead / dailyPages', () {
    test('البدء من الصفحة ١ يعطي ٦٠٤ صفحة كاملة', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 30,
        startPage: 1,
        currentPage: 1,
      );
      expect(plan.totalPagesToRead, 604);
      expect(plan.dailyPages, (604 / 30).ceil());
    });

    test('البدء من صفحة متأخرة يقلّل العدد الكلي المطلوب بشكل صحيح', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 10,
        startPage: 500,
        currentPage: 500,
      );
      expect(plan.totalPagesToRead, 105); // 604 - 500 + 1
      expect(plan.dailyPages, 11); // ceil(105 / 10)
    });
  });

  group('progress', () {
    test('عند نقطة البداية بالضبط ⇒ تقدّم قريب من الصفر (أول صفحة محتسبة)', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 30,
        startPage: 1,
        currentPage: 1,
      );
      // (1 - 1 + 1) / 604 — أول صفحة تُحتسَب كتقدّم مقروء لا صفر مطلق.
      expect(plan.progress, closeTo(1 / 604, 0.0001));
    });

    test('عند آخر صفحة (الختمة اكتملت) ⇒ تقدّم = 1.0 بالضبط', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 30,
        startPage: 1,
        currentPage: 604,
      );
      expect(plan.progress, 1.0);
    });

    test('currentPage تجاوز 604 خطأً لا يرفع التقدّم فوق 1.0 (clamp)', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 30,
        startPage: 1,
        currentPage: 700,
      );
      expect(plan.progress, 1.0);
    });

    test('currentPage أقل من startPage خطأً لا ينزل التقدّم تحت 0.0 (clamp)', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime(2026, 1, 1),
        targetDays: 30,
        startPage: 100,
        currentPage: 50,
      );
      expect(plan.progress, 0.0);
    });
  });

  group('daysElapsed', () {
    test('يوم البدء نفسه ⇒ يوم واحد منقضٍ على الأقل، لا صفر', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime.now(),
        targetDays: 30,
        startPage: 1,
        currentPage: 1,
      );
      expect(plan.daysElapsed, 1);
    });

    test('تجاوز موعد انتهاء الخطة بكثير لا يرفع daysElapsed فوق targetDays (clamp)', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime.now().subtract(const Duration(days: 100)),
        targetDays: 30,
        startPage: 1,
        currentPage: 1,
      );
      expect(plan.daysElapsed, 30);
    });
  });

  group('expectedPageByNow', () {
    test('الصفحة المتوقّعة لا تتجاوز ٦٠٤ حتى لو الخطة متأخرة جداً (clamp)', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        targetDays: 10,
        startPage: 1,
        currentPage: 1,
      );
      expect(plan.expectedPageByNow, 604);
    });

    test('الصفحة المتوقّعة لا تقل عن startPage يوم البدء نفسه', () {
      final plan = KhatmaPlan(
        id: 1,
        startDate: DateTime.now(),
        targetDays: 30,
        startPage: 200,
        currentPage: 200,
      );
      expect(plan.expectedPageByNow, greaterThanOrEqualTo(200));
    });
  });

  test('expectedEndDate = startDate + targetDays بالضبط', () {
    final start = DateTime(2026, 3, 1);
    final plan = KhatmaPlan(
      id: 1,
      startDate: start,
      targetDays: 40,
      startPage: 1,
      currentPage: 1,
    );
    expect(plan.expectedEndDate, DateTime(2026, 4, 10));
  });
}
