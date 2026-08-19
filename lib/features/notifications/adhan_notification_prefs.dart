import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/user/user_prefs.dart';
import '../prayer/prayer_times_service.dart';

/// تفضيلات إشعارات الأذان — إعداد بسيط (SharedPreferences، القرار
/// المعماري #٦ بتصميم-النظام.md)، لا بيانات مستخدم. مبسّطة عمداً بهذا
/// الإصدار لمفتاح واحد لكل صلاة (مفعّل/معطّل) بدل "أذان كامل/تنبيه
/// قصير/صامت" الموصوفة بـ§٢.٦ — لا صوت أذان مرخّص متوفر بعد (نفس فجوة
/// ترخيص QCF، راجع الملاحظة بأعلى `adhan_notification_service.dart`)
/// فلا معنى لتمييز "أذان كامل" حالياً.
class AdhanNotificationPrefs {
  AdhanNotificationPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kMaster = 'adhan_notifications_enabled';
  static const _kPrefix = 'adhan_enabled_';

  bool get masterEnabled => _prefs.getBool(_kMaster) ?? true;

  Future<void> setMasterEnabled(bool value) => _prefs.setBool(_kMaster, value);

  bool isEnabledFor(PrayerMoment moment) => _prefs.getBool('$_kPrefix${moment.name}') ?? true;

  Future<void> setEnabledFor(PrayerMoment moment, bool value) =>
      _prefs.setBool('$_kPrefix${moment.name}', value);

  /// تفعيل فعلي لصلاة معيّنة — يجمع المفتاح العام والخاص معاً، تُستدعى
  /// عند الجدولة الفعلية بدل فحص الاثنين بكل موقع استدعاء.
  bool effectivelyEnabled(PrayerMoment moment) => masterEnabled && isEnabledFor(moment);
}

final adhanNotificationPrefsProvider = Provider<AdhanNotificationPrefs>((ref) {
  return AdhanNotificationPrefs(ref.watch(sharedPreferencesProvider));
});

/// نفس نمط `bookmarkVersionProvider`/`locationVersionProvider` — تخزين
/// متزامن بلا Stream خاص به، فنجبر إعادة البناء يدوياً بعد تبديل التفعيل.
class AdhanNotificationVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final adhanNotificationVersionProvider =
    NotifierProvider<AdhanNotificationVersionNotifier, int>(AdhanNotificationVersionNotifier.new);
