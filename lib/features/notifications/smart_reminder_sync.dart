import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/user/hifz_prefs.dart';
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

/// نفس فكرة [syncDailyWirdReminder] بالضبط لتذكير الحفظ — لو راجع المستخدم
/// آية حفظ واحدة على الأقل اليوم (`HifzPrefs.reviewedToday`) نُلغي تذكير
/// الحفظ المجدوَل (سواء كان دوّاراً بالتصميم القديم `scheduleHifzReminder`
/// أو بفاصل مخصَّص `scheduleRepeatingReminder` — نُلغي كلا المسارين
/// احتياطاً، `cancel*` بلا أثر لو غير مجدوَل أصلاً). يُعاد تفعيله تلقائياً
/// بأول إقلاع بيوم جديد (`main.dart` يعيد تعبئة تذكير الحفظ بكل إقلاع لو
/// مفعَّل، راجع توثيقه هناك) — نفس القيد المعروف بتذكير الورد اليومي: لا
/// إلغاء فوري لو راجع المستخدم بعد آخر إقلاع/مراجعة بنفس اليوم بلا استدعاء
/// لاحق لهذي الدالة.
///
/// يُستدعى من `hifz_review_screen.dart._grade` مباشرة بعد كل تقييم مراجعة.
Future<void> syncHifzReminder(HifzPrefs hifzPrefs) async {
  try {
    if (!hifzPrefs.reminderEnabled || hifzPrefs.reminderHour == null) return;
    if (!await hifzPrefs.reviewedToday()) return;

    final svc = AdhanNotificationService.instance;
    await svc.cancelHifzReminder();
    await svc.cancelRepeatingReminder(UserCategories.hifz);
  } catch (e) {
    debugPrint('مزامنة تذكير الحفظ الذكي فشلت: $e');
  }
}

/// الأنشطة المرشَّحة لـ"تذكير ذكي بالورد الفائت" — الورد اليومي ومراجعة
/// الحفظ (طلب أصلي بالمواصفات) + أذكار الصباح/المساء/النوم (طلب لاحق:
/// "ضيف عليها أذكار الصباح والمسا والنوم"). كلها تشترك بنفس بنية سلسلة
/// الاستمرار المستقلة (`UserRepository._categoryStreakLastDay`)، فنفس
/// المنطق يعمل للجميع بلا تخصيص لكل فئة.
const _kMissedActivityCategories = [
  UserCategories.dailyWird,
  UserCategories.hifz,
  UserCategories.morningAzkar,
  UserCategories.eveningAzkar,
  UserCategories.nightAzkar,
];

const _kMissedActivityLabels = {
  UserCategories.dailyWird: 'الورد اليومي',
  UserCategories.hifz: 'مراجعة الحفظ',
  UserCategories.morningAzkar: 'أذكار الصباح',
  UserCategories.eveningAzkar: 'أذكار المساء',
  UserCategories.nightAzkar: 'أذكار النوم',
};

/// معرّفات إشعار اقتراح تخفيف الخطة — ثابتة (٥ فئات فقط، لا حاجة لخريطة
/// hash كالتحديات الجماعية) وبعيدة عن كل مدايات إشعارات المشروع الأخرى.
const _kMissedActivityNotifIdBase = 13300;

String _lastMissedSuggestionDateKey(String category) =>
    'missed_activity_suggestion_last_date_$category';

/// **تذكير ذكي بالورد/النشاط الفائت** — بديل عن تكرار نفس رسالة التذكير
/// العادية يومياً بلا وعي، لو المستخدم فوّت نشاطاً معيّناً **يومين متتاليين
/// على الأقل** (لا يوم واحد فقط — طبيعي وغير مقلق). عوض تكرار "حان وقت..."
/// نرسل اقتراحاً مختلف الصياغة: مراجعة/تخفيف هدف الخطة. مبني بالكامل فوق
/// `UserRepository.daysSinceLastCompletionFor` الموجود أصلاً — بلا جدول
/// جديد، فقط علم "آخر تاريخ اقتُرح فيه" بـ`SharedPreferences` لتفادي إرسال
/// نفس الاقتراح كل مرة يُفتح فيها التطبيق بنفس اليوم (مرّة واحدة كحدّ أقصى
/// باليوم لكل فئة، لا مرّة واحدة للأبد — لو استمر التفويت لأيام إضافية
/// يستحق تذكيراً جديداً).
///
/// يُستدعى من `main.dart` بجانب [syncDailyWirdReminder] بكل إقلاع.
Future<void> syncMissedActivityReminders(UserPrefs prefs) async {
  try {
    final sp = await SharedPreferences.getInstance();
    final todayKey = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

    for (final category in _kMissedActivityCategories) {
      if (!prefs.reminderEnabledFor(category)) continue;

      final missedDays = prefs.daysSinceLastCompletionFor(category);
      // `null` = لم يُنجَز إطلاقاً بعد (مستخدم جديد) — ليس "تفويتاً" يستحق
      // اقتراحاً. يوم واحد فقط طبيعي جداً (قد يكون نفس اليوم لم ينتهِ بعد
      // بالنسبة لوقت التذكير المعتاد) — نبدأ الاقتراح من يومين فأكثر.
      if (missedDays == null || missedDays < 2) continue;

      final lastSuggestedKey = _lastMissedSuggestionDateKey(category);
      if (sp.getString(lastSuggestedKey) == todayKey) continue;

      final label = _kMissedActivityLabels[category] ?? category;
      await AdhanNotificationService.instance.showInstantAlert(
        id: _kMissedActivityNotifIdBase + _kMissedActivityCategories.indexOf(category),
        title: 'فاتك "$label" منذ $missedDays أيام',
        body: 'ما رح نكرر عليك نفس التذكير — جرّب تخفّف هدفك اليومي بهالنشاط من الإعدادات، أسهل من التوقف كلياً',
      );
      await sp.setString(lastSuggestedKey, todayKey);
    }
  } catch (e) {
    debugPrint('مزامنة تذكير الورد الفائت الذكي فشلت: $e');
  }
}
