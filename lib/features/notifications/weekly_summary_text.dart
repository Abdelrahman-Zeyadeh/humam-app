import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../home/weekly_report_screen.dart' show loadWeeklyReportData;

/// يجلب بيانات التقرير الأسبوعي (`loadWeeklyReportData`، نفس مصدر شاشة
/// "تقرير أسبوعي") ويبنيها نصاً جاهزاً لإشعار "ملخّص الأسبوع" — نقطة
/// الاستدعاء الموحَّدة لـ`main.dart` (إعادة الجدولة بكل إقلاع) و
/// `weekly_summary_reminder_row.dart` (عند التفعيل/تغيير الوقت)، بنفس نمط
/// `evening_summary_text.dart` بالضبط لكن على مستوى الأسبوع لا اليوم.
Future<String> buildWeeklySummaryBodyFor(
  UserPrefs prefs,
  KhatmaPrefs khatmaPrefs,
) async {
  final data = await loadWeeklyReportData(prefs, khatmaPrefs);
  return buildWeeklySummaryText(
    overallScorePercent: data.overallScorePercent,
    fardCompletedCount: data.fardCompletedCount,
    khatmaProgressPercent: data.khatmaProgressPercent,
  );
}

/// يبني نص إشعار "ملخّص الأسبوع" — سطر أول بالدرجة الإيمانية الموحَّدة
/// (نفس صيغة `computeOverallScorePercent` التي تجمع الفرائض/الحفظ/الأذكار/
/// القيام/الختمة بمتوسط واحد، راجع توثيقها الكامل بـ`weekly_report_screen.
/// dart`)، وسطر ثانٍ إما تحفيز (درجة عالية) أو دفعة لطيفة (درجة منخفضة)
/// بدل نص محايد لا يتغيّر بتغيّر الأداء.
String buildWeeklySummaryText({
  required int overallScorePercent,
  required int fardCompletedCount,
  required int? khatmaProgressPercent,
}) {
  final parts = <String>['صلّيت $fardCompletedCount من ٣٥ فرضاً هذا الأسبوع'];
  if (khatmaProgressPercent != null) {
    parts.add('وختمتك عند $khatmaProgressPercent%');
  }
  final detailsText = parts.join('، ');

  final String encouragement;
  if (overallScorePercent >= 80) {
    encouragement = 'أسبوع ممتاز، استمر على هالمستوى 🌟';
  } else if (overallScorePercent >= 50) {
    encouragement = 'بداية طيبة، شدّ حيلك الأسبوع الجاي تزيد الدرجة 💪';
  } else {
    encouragement = 'الأسبوع الجاي فرصة جديدة، ابدأ بخطوة صغيرة اليوم 🤍';
  }

  return 'درجتك الإيمانية هالأسبوع: $overallScorePercent%.\n$detailsText.\n$encouragement';
}
