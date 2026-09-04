import 'package:hijri/hijri_calendar.dart';

/// مناسبة هجرية واحدة — عنوان + سطر ترحيبي قصير، بلا أي فتوى/حكم فقهي
/// إضافي (نفس قيد "لا نص/تصنيف ديني من التخمين" بالمشروع). قائمة المناسبات
/// هون أسماء تقويمية بلا خلاف بين المذاهب (بداية رمضان، عيدان، يوم عرفة،
/// عاشوراء، الليالي الوترية بالعشر الأواخر) — لا تواريخ اجتهادية إضافية.
class HijriOccasion {
  const HijriOccasion({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

/// حساب محلي بالكامل عبر `hijri_calendar.dart` (نفس خوارزمية أم القرى
/// الجدولية المستخدمة أصلاً بـ`todayHijriArabic()`) — بلا استدعاء شبكة.
/// راجع نفس تحفّظ الدقّة الموثَّق هناك (تقريب بيوم واحد أحياناً عن رؤية
/// الهلال الفعلية).
HijriOccasion? hijriOccasionFor(DateTime date) {
  final cal = HijriCalendar.fromDate(date);
  final m = cal.hMonth;
  final d = cal.hDay;

  if (m == 9 && d == 1) {
    return const HijriOccasion(title: 'بداية شهر رمضان المبارك', subtitle: 'رمضان كريم — تقبّل الله منّا ومنكم');
  }
  if (m == 9 && d >= 21 && d.isOdd) {
    return const HijriOccasion(title: 'ليلة وترية من العشر الأواخر', subtitle: 'من الليالي المرجوّة لليلة القدر');
  }
  if (m == 10 && d == 1) {
    return const HijriOccasion(title: 'عيد الفطر المبارك', subtitle: 'كل عام وأنتم بخير');
  }
  if (m == 12 && d == 9) {
    return const HijriOccasion(title: 'يوم عرفة', subtitle: 'يُستحبّ صيامه لغير الحاجّ');
  }
  if (m == 12 && d == 10) {
    return const HijriOccasion(title: 'عيد الأضحى المبارك', subtitle: 'كل عام وأنتم بخير');
  }
  if (m == 1 && d == 10) {
    return const HijriOccasion(title: 'يوم عاشوراء', subtitle: 'يُستحبّ صيامه');
  }
  return null;
}

/// `true` لو `date` يقع بشهر رمضان هجرياً — يُستخدم لتفعيل تذكير
/// السحور/الإمساك التلقائي (`AdhanNotificationService`).
bool isRamadan(DateTime date) => HijriCalendar.fromDate(date).hMonth == 9;
