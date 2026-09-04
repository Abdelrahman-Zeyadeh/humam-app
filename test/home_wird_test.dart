// اختبار حساب "ورد اليوم" (home_screen.dart.wirdPagesForToday) — دالة نقيّة
// بلا قاعدة بيانات: (٦٠٤ - الصفحة الحالية) ÷ الأيام المتبقّية من مدّة
// الخطة الأصلية، مع "حساب جديد تلقائياً" لو انتهت المدّة الأصلية.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/user/user_repository.dart' show KhatmaPlan;
import 'package:humam_app/features/home/home_screen.dart' show wirdPagesForToday;

void main() {
  test('خطة بدأت اليوم بهدف ٣٠ يوماً من الصفحة ١: ورد اليوم = ٦٠٤/٣٠ مقرَّب لأعلى', () {
    final plan = KhatmaPlan(
      id: 1,
      startDate: DateTime.now(),
      targetDays: 30,
      startPage: 1,
      currentPage: 1,
    );
    expect(wirdPagesForToday(plan), (604 / 30).ceil());
  });

  test('لا صفحات متبقّية (وصل ٦٠٤) — ورد اليوم صفر', () {
    final plan = KhatmaPlan(
      id: 2,
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      targetDays: 10,
      startPage: 1,
      currentPage: 604,
    );
    expect(wirdPagesForToday(plan), 0);
  });

  test('متأخّر عن الجدول — ورد اليوم يرتفع تلقائياً ليعوّض التأخّر', () {
    // خطة ١٠ أيام من الصفحة ١، بعد ٥ أيام (نصف المدّة) المفروض الوصول
    // لمنتصف ٦٠٤ تقريباً، لكن التقدّم الفعلي وقف عند ١٠٠ فقط — ورد اليوم
    // يجب أن يعكس الحاجة لتعويض التأخّر (أعلى من الوتيرة الأصلية ٦٠.٤).
    final plan = KhatmaPlan(
      id: 3,
      startDate: DateTime.now().subtract(const Duration(days: 4)),
      targetDays: 10,
      startPage: 1,
      currentPage: 100,
    );
    final originalPace = (604 / 10).ceil(); // ٦١
    expect(wirdPagesForToday(plan), greaterThan(originalPace));
  });

  test('انتهت المدّة الأصلية ولم تكتمل الختمة — "حساب جديد تلقائياً" (يرجع لوتيرة الخطة الأصلية، لا قسمة كل الصفحات على يوم واحد)', () {
    final plan = KhatmaPlan(
      id: 4,
      startDate: DateTime.now().subtract(const Duration(days: 40)),
      targetDays: 30,
      startPage: 1,
      currentPage: 100,
    );
    // بلا الحل الدفاعي: (٦٠٤-١٠٠) ÷ ١ = ٥٠٤ صفحة — رقم غير معقول.
    expect(wirdPagesForToday(plan), lessThan(504));
    // القيمة المتوقَّعة = وتيرة الخطة الأصلية `dailyPages`.
    expect(wirdPagesForToday(plan), plan.dailyPages);
  });
}
