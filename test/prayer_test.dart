// اختبار وحدة لمنطق مواقيت الصلاة: ترتيب الأوقات، اختيار الصلاة القادمة،
// وسلامة قائمة المدن — بلا شبكة ولا GPS فعلي.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/prayer/cities.dart';
import 'package:humam_app/features/prayer/prayer_times_service.dart';

void main() {
  test('مواقيت مكة ليوم معيّن مرتّبة زمنياً (فجر < شروق < ظهر < عصر < مغرب < عشاء)', () {
    final times = computeDayTimes(
      lat: 21.4225,
      lon: 39.8262,
      date: DateTime(2026, 3, 15),
      methodKey: 'ummAlQura',
    );

    expect(times.length, 6);
    for (var i = 1; i < times.length; i++) {
      expect(
        times[i].time.isAfter(times[i - 1].time),
        isTrue,
        reason: '${times[i].moment.nameAr} يجب أن يأتي بعد ${times[i - 1].moment.nameAr}',
      );
    }
  });

  test('nextPrayer يتجاهل الشروق (ليس صلاة) ويلتقط أول صلاة لسا ما جاءت', () {
    final times = computeDayTimes(
      lat: 24.7136,
      lon: 46.6753,
      date: DateTime(2026, 6, 1),
      methodKey: 'ummAlQura',
    );

    // نطلب الصلاة القادمة من لحظة قبل الفجر بدقيقة — لازم ترجع الفجر نفسه.
    final beforeFajr = times.first.time.subtract(const Duration(minutes: 1));
    final next = nextPrayer(times, beforeFajr);
    expect(next, isNotNull);
    expect(next!.moment, PrayerMoment.fajr);

    // من لحظة بعد الفجر مباشرة — لازم ترجع الظهر (تتخطى الشروق).
    final afterFajr = times.first.time.add(const Duration(minutes: 1));
    final next2 = nextPrayer(times, afterFajr);
    expect(next2!.moment, PrayerMoment.dhuhr);
  });

  test('nextPrayer يرجع null لو كل صلوات اليوم فاتت', () {
    final times = computeDayTimes(
      lat: 21.4225,
      lon: 39.8262,
      date: DateTime(2026, 3, 15),
      methodKey: 'ummAlQura',
    );
    final afterIsha = times.last.time.add(const Duration(hours: 1));
    expect(nextPrayer(times, afterIsha), isNull);
  });

  test('calculationMethodByKey يرجع طريقة صحيحة، ويعود للافتراضي لمفتاح غير معروف', () {
    expect(calculationMethodByKey('egyptian').nameAr, contains('مصري'));
    expect(calculationMethodByKey('غير موجود').key, kCalculationMethods.first.key);
  });

  test('قائمة المدن: أسماء فريدة وإحداثيات ضمن مدى صحيح', () {
    final names = kPrayerCities.map((c) => c.nameAr).toSet();
    expect(names.length, kPrayerCities.length, reason: 'يوجد اسم مدينة مكرّر');
    for (final c in kPrayerCities) {
      expect(c.lat, inInclusiveRange(-90, 90));
      expect(c.lon, inInclusiveRange(-180, 180));
    }
    expect(names, contains('مكة المكرمة'));
  });
}
