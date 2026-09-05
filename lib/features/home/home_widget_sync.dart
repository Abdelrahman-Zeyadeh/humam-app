import 'dart:async' show unawaited;

import '../../core/hijri/hijri_date.dart';
import '../prayer/prayer_times_service.dart';
import '../widget/home_widget_service.dart';
import 'home_dashboard_data.dart';

/// يدفع بيانات لوحة اليوم (آية الفترة/الذكر/الصلاة القادمة/التاريخ
/// الهجري...) لودجت الشاشة الرئيسية — استُخرجت من `HomeScreen.build`
/// أثناء تفكيك `home_screen.dart` بلا أي تغيير سلوكي، فقط أصبحت دالة
/// مستقلة تُستدعى من الودجت بدل closure محلي بالـbuild.
void dispatchHomeWidgetSync({
  required HomeDashboardData data,
  required List<PrayerMomentTime>? dayTimes,
  required String? accentId,
}) {
  final now = DateTime.now();
  final next2 = dayTimes == null ? null : nextPrayer(dayTimes, now);

  String formatClock(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String formatCountdown(DateTime target) {
    final diff = target.difference(now);
    if (diff.isNegative) return '';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return 'بعد $hours:$minutes';
  }

  String formattedHijriToday() {
    final raw = todayHijriWithDayArabic(now);
    return raw.replaceAll(RegExp(r'\s+هـ$'), '');
  }

  final fajr = dayTimes?.where((t) => t.moment == PrayerMoment.fajr).firstOrNull;
  final sunrise = dayTimes
      ?.where((t) => t.moment == PrayerMoment.sunrise)
      .firstOrNull;
  final dhuhr = dayTimes?.where((t) => t.moment == PrayerMoment.dhuhr).firstOrNull;
  final asr = dayTimes?.where((t) => t.moment == PrayerMoment.asr).firstOrNull;
  final maghrib = dayTimes
      ?.where((t) => t.moment == PrayerMoment.maghrib)
      .firstOrNull;
  final isha = dayTimes?.where((t) => t.moment == PrayerMoment.isha).firstOrNull;

  unawaited(
    updateHumamHomeWidget(
      ayahText: data.ayahOfDay.textUthmani,
      ayahRef: '${data.ayahOfDaySurah} - ${data.ayahOfDay.ayah}',
      dhikrText: data.dhikrOfDay,
      hijriDate: formattedHijriToday(),
      nextPrayerName: next2?.moment.nameAr,
      nextPrayerTime: next2 == null ? null : formatClock(next2.time),
      nextPrayerCountdown: next2 == null ? null : formatCountdown(next2.time),
      nextPrayerTargetEpochMs: next2?.time.millisecondsSinceEpoch,
      timeFajr: fajr != null ? formatClock(fajr.time) : null,
      timeSunrise: sunrise != null ? formatClock(sunrise.time) : null,
      timeDhuhr: dhuhr != null ? formatClock(dhuhr.time) : null,
      timeAsr: asr != null ? formatClock(asr.time) : null,
      timeMaghrib: maghrib != null ? formatClock(maghrib.time) : null,
      timeIsha: isha != null ? formatClock(isha.time) : null,
      timeFajrMs: fajr?.time.millisecondsSinceEpoch,
      timeSunriseMs: sunrise?.time.millisecondsSinceEpoch,
      timeDhuhrMs: dhuhr?.time.millisecondsSinceEpoch,
      timeAsrMs: asr?.time.millisecondsSinceEpoch,
      timeMaghribMs: maghrib?.time.millisecondsSinceEpoch,
      timeIshaMs: isha?.time.millisecondsSinceEpoch,
      activeMoment: next2?.moment.name,
      accentId: accentId,
    ),
  );
}
