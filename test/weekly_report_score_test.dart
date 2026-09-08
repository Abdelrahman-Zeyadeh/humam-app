import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/user/user_repository.dart' show UserCategories;
import 'package:humam_app/features/home/weekly_report_screen.dart';

/// اختبارات "الدرجة الإيمانية الإجمالية" (`computeOverallScorePercent`) —
/// أحدث وأعقد منطق حساب بالتطبيق (يجمع فرائض + حفظ + أذكار + قيام + ختمة
/// برقم واحد)، وكان بلا أي اختبار آلي إطلاقاً قبل هذا الملف رغم أنه أول
/// شيء يراه المستخدم بالتقرير الأسبوعي. راجع توثيق الصيغة الكاملة بـ
/// `WeeklyReportData.overallScorePercent` — هذا الملف يثبّت تلك الصيغة
/// بالاختبار، فأي تغيير غير مقصود بمنطقها (بريفاكتور مثلاً) يُكتشَف فوراً.
void main() {
  final fullWeek = List.filled(7, true);
  final emptyWeek = List.filled(7, false);

  test('كل الأقسام مكتملة بالكامل ولا خطة ختمة ⇒ 100%', () {
    final weeks = {
      UserCategories.fajr: fullWeek,
      UserCategories.dhuhr: fullWeek,
      UserCategories.asr: fullWeek,
      UserCategories.maghrib: fullWeek,
      UserCategories.isha: fullWeek,
      UserCategories.hifz: fullWeek,
      UserCategories.morningAzkar: fullWeek,
      UserCategories.eveningAzkar: fullWeek,
      UserCategories.nightAzkar: fullWeek,
      UserCategories.qiyam: fullWeek,
    };

    final score = computeOverallScorePercent(
      categoryWeeks: weeks,
      khatmaProgressPercent: null,
    );

    expect(score, 100);
  });

  test('كل الأقسام فاضية بالكامل ولا خطة ختمة ⇒ 0%', () {
    final weeks = {
      UserCategories.fajr: emptyWeek,
      UserCategories.dhuhr: emptyWeek,
      UserCategories.asr: emptyWeek,
      UserCategories.maghrib: emptyWeek,
      UserCategories.isha: emptyWeek,
      UserCategories.hifz: emptyWeek,
      UserCategories.morningAzkar: emptyWeek,
      UserCategories.eveningAzkar: emptyWeek,
      UserCategories.nightAzkar: emptyWeek,
      UserCategories.qiyam: emptyWeek,
    };

    final score = computeOverallScorePercent(
      categoryWeeks: weeks,
      khatmaProgressPercent: null,
    );

    expect(score, 0);
  });

  test('خارطة فارغة كلياً (مستخدم جديد بلا أي بيانات) ⇒ 0% بلا استثناء', () {
    final score = computeOverallScorePercent(
      categoryWeeks: const {},
      khatmaProgressPercent: null,
    );
    expect(score, 0);
  });

  test('غياب خطة ختمة نشطة يستبعدها من المتوسط بدل احتسابها صفراً', () {
    // ٤ أقسام (فرائض/حفظ/أذكار/قيام) مكتملة بالكامل، بلا خطة ختمة — لو
    // اعتُبرت الختمة الغائبة "صفر" ضمن متوسط ٥ عناصر لصار الناتج ٨٠% لا
    // ١٠٠%. الصيغة الموثَّقة تستبعدها كلياً من القسمة لا تحتسبها صفراً.
    final weeks = {
      UserCategories.fajr: fullWeek,
      UserCategories.dhuhr: fullWeek,
      UserCategories.asr: fullWeek,
      UserCategories.maghrib: fullWeek,
      UserCategories.isha: fullWeek,
      UserCategories.hifz: fullWeek,
      UserCategories.morningAzkar: fullWeek,
      UserCategories.eveningAzkar: fullWeek,
      UserCategories.nightAzkar: fullWeek,
      UserCategories.qiyam: fullWeek,
    };

    final withoutKhatma = computeOverallScorePercent(
      categoryWeeks: weeks,
      khatmaProgressPercent: null,
    );
    final withFullKhatma = computeOverallScorePercent(
      categoryWeeks: weeks,
      khatmaProgressPercent: 100,
    );

    expect(withoutKhatma, 100);
    expect(withFullKhatma, 100); // إضافة ختمة مكتملة ١٠٠٪ لا تغيّر الدرجة
  });

  test('تقدّم ختمة جزئي يُحتسَب مباشرة كنسبة مئوية ضمن المتوسط', () {
    // كل الأقسام صفر + ختمة ٥٠٪ ⇒ متوسط (0+0+0+0+50)/5 = 10%.
    final score = computeOverallScorePercent(
      categoryWeeks: {
        UserCategories.fajr: emptyWeek,
        UserCategories.dhuhr: emptyWeek,
        UserCategories.asr: emptyWeek,
        UserCategories.maghrib: emptyWeek,
        UserCategories.isha: emptyWeek,
        UserCategories.hifz: emptyWeek,
        UserCategories.morningAzkar: emptyWeek,
        UserCategories.eveningAzkar: emptyWeek,
        UserCategories.nightAzkar: emptyWeek,
        UserCategories.qiyam: emptyWeek,
      },
      khatmaProgressPercent: 50,
    );

    expect(score, 10);
  });

  test('الفرائض الخمسة تُحتسَب كمتوسط واحد لا كخمسة عناصر منفصلة بالمتوسط الكلي', () {
    // فجر فقط مكتمل من ٧/٧ أيام، وباقي الفرائض الأربعة صفر ⇒ متوسط
    // الفرائض = (100+0+0+0+0)/5 = 20%. لو عوملت الفرائض الخمسة كعناصر
    // منفصلة بالمتوسط الكلي (بدل متوسط واحد باسم "fardRate") لظهر رقم
    // مختلف كلياً — هذا الاختبار يثبّت أنها مجمَّعة أولاً.
    final score = computeOverallScorePercent(
      categoryWeeks: {
        UserCategories.fajr: fullWeek,
        UserCategories.dhuhr: emptyWeek,
        UserCategories.asr: emptyWeek,
        UserCategories.maghrib: emptyWeek,
        UserCategories.isha: emptyWeek,
      },
      khatmaProgressPercent: null,
    );

    // (fardRate=20 + hifz=0 + azkarRate=0 + qiyam=0) / 4 = 5%.
    expect(score, 5);
  });

  test('أذكار الصباح/المساء/النوم تُحتسَب كمتوسط واحد ("azkarRate") لا ثلاثة عناصر', () {
    final score = computeOverallScorePercent(
      categoryWeeks: {
        UserCategories.morningAzkar: fullWeek,
        UserCategories.eveningAzkar: emptyWeek,
        UserCategories.nightAzkar: emptyWeek,
      },
      khatmaProgressPercent: null,
    );

    // fardRate=0 (لا بيانات) + hifz=0 + azkarRate=(100+0+0)/3≈33.33 + qiyam=0
    // ⇒ (0+0+33.33+0)/4 ≈ 8.33 → تُقرَّب لـ٨.
    expect(score, 8);
  });

  test('week أسبوع بأيام أقل من ٧ (بيانات جزئية) يُحسَب بنسبته الفعلية لا كصفر', () {
    // ٣ أيام مكتملة من ٥ مُسجَّلة فقط (لا يُفترض دائماً ٧ أيام بالضبط).
    final rate = weekCompletionRate([true, true, true, false, false]);
    expect(rate, closeTo(60, 0.001));
  });

  test('weekCompletionRate يرجع صفر لأسبوع null أو فاضي بلا رمي استثناء', () {
    expect(weekCompletionRate(null), 0);
    expect(weekCompletionRate(const []), 0);
  });

  test('النتيجة دائماً بين 0 و100 (لا تتجاوز الحدود مهما كانت المُدخلات)', () {
    final score = computeOverallScorePercent(
      categoryWeeks: {
        UserCategories.fajr: fullWeek,
        UserCategories.dhuhr: fullWeek,
        UserCategories.asr: fullWeek,
        UserCategories.maghrib: fullWeek,
        UserCategories.isha: fullWeek,
        UserCategories.hifz: fullWeek,
        UserCategories.morningAzkar: fullWeek,
        UserCategories.eveningAzkar: fullWeek,
        UserCategories.nightAzkar: fullWeek,
        UserCategories.qiyam: fullWeek,
      },
      khatmaProgressPercent: 100,
    );
    expect(score, inInclusiveRange(0, 100));
  });
}
