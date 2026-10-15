import 'dart:async' show unawaited;

import '../../core/data/user/user_prefs.dart';
import '../../core/hijri/hijri_date.dart';
import '../prayer/prayer_times_service.dart';
import '../widget/home_widget_service.dart';
import 'home_dashboard_data.dart';

/// يدفع بيانات لوحة اليوم (آية الفترة/الذكر/الصلاة القادمة أو الإقامة/التاريخ
/// الهجري...) لودجت الشاشة الرئيسية — يدعم عداد الإقامة التنازلي الحي.
void dispatchHomeWidgetSync({
  required HomeDashboardData data,
  required List<PrayerMomentTime>? dayTimes,
  required String? accentId,
  UserPrefs? userPrefs,
}) {
  final now = DateTime.now();

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
    return '$hours:$minutes';
  }

  String formattedHijriToday() {
    final raw = todayHijriWithDayArabic(now);
    return raw.replaceAll(RegExp(r'\s+هـ$'), '');
  }

  // فحص ما إذا كنا حالياً في نافذة إقامة صلاة قائمة
  PrayerMomentTime? recentPrayer;
  if (dayTimes != null && userPrefs != null) {
    for (final t in dayTimes.where((t) => t.moment.isPrayer)) {
      final off = userPrefs.prayerOffsetFor(t.moment.name);
      final adjTime = t.time.add(Duration(minutes: off));
      if (!adjTime.isAfter(now)) {
        recentPrayer = PrayerMomentTime(t.moment, adjTime);
      }
    }
    if (recentPrayer == null) {
      // بعد منتصف الليل وقبل الفجر، الصلاة السابقة هي عشاء الأمس
      final isha = dayTimes.where((t) => t.moment == PrayerMoment.isha).firstOrNull;
      if (isha != null) {
        final off = userPrefs.prayerOffsetFor('isha');
        final yesterdayIshaTime = isha.time.subtract(const Duration(days: 1)).add(Duration(minutes: off));
        if (!yesterdayIshaTime.isAfter(now)) {
          recentPrayer = PrayerMomentTime(PrayerMoment.isha, yesterdayIshaTime);
        }
      }
    }
  }

  final recentIqamahMins = (recentPrayer != null && userPrefs != null)
      ? userPrefs.iqamahMinutesFor(recentPrayer.moment.name)
      : 0;
  final recentIqamahTarget = recentPrayer?.time.add(Duration(minutes: recentIqamahMins));
  final bool inIqamahWindow = recentIqamahTarget != null && now.isBefore(recentIqamahTarget);

  final next2 = dayTimes == null ? null : nextPrayer(dayTimes, now);

  final heroPrayerName = inIqamahWindow
      ? 'إقامة ${recentPrayer!.moment.nameAr}'
      : next2?.moment.nameAr;
  final heroPrayerTime = inIqamahWindow
      ? formatClock(recentIqamahTarget)
      : (next2 == null ? null : formatClock(next2.time));
  final heroPrayerCountdown = inIqamahWindow
      ? 'للإقامة ${formatCountdown(recentIqamahTarget)}'
      : (next2 == null ? null : 'بعد ${formatCountdown(next2.time)}');
  final heroPrayerTargetEpoch = inIqamahWindow
      ? recentIqamahTarget.millisecondsSinceEpoch
      : next2?.time.millisecondsSinceEpoch;
  final heroActiveMoment = inIqamahWindow
      ? recentPrayer!.moment.name
      : next2?.moment.name;

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
      nextPrayerName: heroPrayerName,
      nextPrayerTime: heroPrayerTime,
      nextPrayerCountdown: heroPrayerCountdown,
      nextPrayerTargetEpochMs: heroPrayerTargetEpoch,
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
      timeTomorrowFajrMs: fajr?.time.add(const Duration(days: 1)).millisecondsSinceEpoch,
      activeMoment: heroActiveMoment,
      iqamahFajrMin: userPrefs?.iqamahMinutesFor('fajr') ?? 20,
      iqamahDhuhrMin: userPrefs?.iqamahMinutesFor('dhuhr') ?? 15,
      iqamahAsrMin: userPrefs?.iqamahMinutesFor('asr') ?? 15,
      iqamahMaghribMin: userPrefs?.iqamahMinutesFor('maghrib') ?? 10,
      iqamahIshaMin: userPrefs?.iqamahMinutesFor('isha') ?? 15,
      isInIqamah: inIqamahWindow,
      accentId: accentId,
    ),
  );
}
