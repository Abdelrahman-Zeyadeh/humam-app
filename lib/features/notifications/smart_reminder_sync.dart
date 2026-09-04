import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import 'adhan_notification_service.dart';

/// يجعل تذكير "الورد اليومي" واعياً بإنجاز اليوم الفعلي بدل تذكير ثابت
/// يتكرّر كل يوم بنفس الوقت بلا وعي (سلوكه السابق، مطابق حرفياً لتذكيرَي
/// أذكار الصباح/المساء اللذين ما زالا هيك عمداً — لا مفهوم "إنجاز جزئي"
/// واضح لهما بنفس بساطة القراءة).
///
/// **الفكرة**: لا حاجة لجدولة جديدة أو قناة إشعار جديدة — نعيد استخدام
/// [AdhanNotificationService.scheduleActivityReminder]/`cancelActivityReminder`
/// الموجودتين أصلاً بالضبط (نفس القناة/المعرّف/التصميم الذي شاشة الإعدادات
/// تستخدمه عند التفعيل اليدوي). فقط: لو المستخدم قرأ اليوم فعلاً
/// (`UserPrefs.readToday`) نُلغي التذكير المجدوَل حالياً (يبقى ملغياً حتى
/// إعادة تفعيله تلقائياً بأول تشغيل بيوم جديد، حين يصفَّر `readToday` من
/// جديد)، وإلا نُبقيه/نعيد تفعيله كالمعتاد.
///
/// يُستدعى من مكانين: `main.dart` (إعادة تقييم بكل إقلاع، نفس نمط
/// `scheduleEveningSummary`) و`mushaf_screen.dart._flushReadingLog`
/// (إلغاء فوري لحظة تسجيل قراءة فعلية، لا انتظار الإقلاع التالي).
///
/// **قيد معروف موثَّق (لا حل كامل بلا مهمة خلفية حقيقية)**: لو قرأ
/// المستخدم وردَه بعد آخر مرة فُتح فيها التطبيق أو سُجِّلت قراءة بنفس
/// اليوم، بلا إعادة فتح لاحقة، يبقى التذكير المجدوَل مسبقاً يُطلَق بوقته
/// المحدَّد رغم إنجاز الورد فعلياً — نفس القيد الموثَّق أصلاً لبقية إشعارات
/// هذا الملف (لا مهمة خلفية `WorkManager`/مشابه بالمشروع).
Future<void> syncDailyWirdReminder(UserPrefs prefs) async {
  try {
    final enabled = prefs.reminderEnabledFor(UserCategories.dailyWird);
    final hour = prefs.reminderHourFor(UserCategories.dailyWird);
    if (!enabled || hour == null) return;

    if (prefs.readToday) {
      await AdhanNotificationService.instance.cancelActivityReminder(UserCategories.dailyWird);
    } else {
      await AdhanNotificationService.instance.scheduleActivityReminder(
        UserCategories.dailyWird,
        hour: hour,
        minute: prefs.reminderMinuteFor(UserCategories.dailyWird),
      );
    }
  } catch (e) {
    debugPrint('مزامنة تذكير الورد اليومي الذكي فشلت: $e');
  }
}
