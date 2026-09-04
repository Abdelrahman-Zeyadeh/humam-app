/// تنسيق وقت عربي "١٢:٣٠ م" (١٢ ساعة + ص/م) — كانت هذه الدالة مكرَّرة
/// حرفياً بثلاثة ملفات (`qiyam_screen.dart`، `hifz_screen.dart`،
/// `settings_screen.dart`) قبل توحيدها هون عند إضافة استخدام رابع
/// (ويدجت الشاشة الرئيسية، `home_widget_service.dart`) — نفس "قاعدة
/// الإبهام" المتَّبعة بالمشروع: تعميم النمط عند التكرار الثالث فما فوق.
String formatTimeOfDay(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'ص' : 'م';
  final m = minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}
