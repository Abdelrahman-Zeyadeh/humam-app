import '../../core/data/user/user_prefs.dart';

/// يجلب إحصاءات اليوم من [prefs] ويبنيها نصاً جاهزاً للإشعار مباشرة —
/// نقطة الاستدعاء الموحَّدة لكل من `settings_screen.dart` (عند التفعيل/تغيير
/// الوقت) و`main.dart` (إعادة الجدولة اليومية بكل إقلاع).
Future<String> buildEveningSummaryBodyFor(UserPrefs prefs) async {
  final stats = await prefs.eveningSummaryStatsToday();
  return buildEveningSummaryText(
    pages: stats.pages,
    minutes: stats.minutes,
    azkarCount: stats.azkarCount,
    prayersConfirmed: stats.prayersConfirmed,
    wirdDoneToday: prefs.readToday,
  );
}

/// يبني نص الملخّص المسائي المحفّز — راجع
/// `UserRepository.eveningSummaryStatsToday`/`AdhanNotificationService.
/// scheduleEveningSummary`. سطر أول يلخّص ما تمّ فعلاً اليوم، وسطر ثانٍ
/// إما تهنئة (كل شيء تمّ) أو تذكير بما تبقّى (ورد ناقص/صلاة غير مؤكَّدة).
String buildEveningSummaryText({
  required int pages,
  required int minutes,
  required int azkarCount,
  required int prayersConfirmed,
  required bool wirdDoneToday,
}) {
  final doneParts = <String>[];
  if (pages > 0) doneParts.add('قرأت $pages صفحة');
  if (minutes > 0) doneParts.add('استمعت $minutes دقيقة تلاوة');
  if (azkarCount > 0) doneParts.add('أتممت $azkarCount ذكر/سبحة');
  if (prayersConfirmed > 0) doneParts.add('أكّدت $prayersConfirmed من ٥ صلوات');

  final doneText = doneParts.isEmpty
      ? 'لم تُسجَّل أي عبادة اليوم بعد'
      : doneParts.join('، ');

  final missing = <String>[];
  if (!wirdDoneToday) missing.add('الورد اليومي');
  if (prayersConfirmed < 5) missing.add('${5 - prayersConfirmed} صلوات');

  final missingText = missing.isEmpty
      ? 'أحسنت! أتممت يومك بخير 🌟'
      : 'تبقّى عليك: ${missing.join(' و')}.';

  return '$doneText.\n$missingText';
}
