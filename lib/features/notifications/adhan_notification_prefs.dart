import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_providers.dart';
import '../../core/data/user/user_repository.dart';
import '../prayer/prayer_times_service.dart';

/// تفضيلات إشعارات الأذان — مفتاح واحد لكل صلاة (مفعّل/معطّل) بدل "أذان
/// كامل/تنبيه قصير/صامت" الموصوفة بـ§٢.٦ — لا صوت أذان مرخّص متوفر بعد
/// (نفس فجوة ترخيص QCF، راجع الملاحظة بأعلى `adhan_notification_service.dart`)
/// فلا معنى لتمييز "أذان كامل" حالياً. **مُهاجَرة إلى `user.db`**
/// (`AdhanNotificationSettings`، راجع `user_repository.dart`) —
/// كانت `SharedPreferences` مباشرة، هذا الغلاف يبقي نفس الواجهة العامة
/// حرفياً فلا تحتاج مواقع الاستدعاء أي تعديل.
class AdhanNotificationPrefs {
  AdhanNotificationPrefs(this._repo);
  final UserRepository _repo;

  static const _kMaster = 'master';

  bool get masterEnabled => _repo.adhanNotifEnabled(_kMaster);

  Future<void> setMasterEnabled(bool value) => _repo.setAdhanNotifEnabled(_kMaster, value);

  bool isEnabledFor(PrayerMoment moment) => _repo.adhanNotifEnabled(moment.name);

  Future<void> setEnabledFor(PrayerMoment moment, bool value) =>
      _repo.setAdhanNotifEnabled(moment.name, value);

  /// تفعيل فعلي لصلاة معيّنة — يجمع المفتاح العام والخاص معاً، تُستدعى
  /// عند الجدولة الفعلية بدل فحص الاثنين بكل موقع استدعاء.
  bool effectivelyEnabled(PrayerMoment moment) => masterEnabled && isEnabledFor(moment);

  /// نمط التنبيه المخصّص لكل صلاة ('adhan', 'tone', 'silent', 'off')
  String notificationModeFor(PrayerMoment moment) {
    if (!effectivelyEnabled(moment)) return 'off';
    return _repo.adhanModeFor(moment.name);
  }

  Future<void> setNotificationModeFor(PrayerMoment moment, String mode) async {
    await _repo.setAdhanModeFor(moment.name, mode);
    if (mode == 'off') {
      await setEnabledFor(moment, false);
    } else {
      await setEnabledFor(moment, true);
    }
  }

  // --- تنبيهات السنن والأيام الفاضلة ---
  static const _kSunnahKahf = 'sunnah_kahf';
  static const _kSunnahSalawat = 'sunnah_salawat';
  static const _kSunnahFasting = 'sunnah_fasting';
  static const _kSunnahWhiteDays = 'sunnah_white_days';

  bool get sunnahKahfEnabled => _repo.adhanNotifEnabled(_kSunnahKahf);
  Future<void> setSunnahKahfEnabled(bool value) => _repo.setAdhanNotifEnabled(_kSunnahKahf, value);

  bool get sunnahSalawatEnabled => _repo.adhanNotifEnabled(_kSunnahSalawat);
  Future<void> setSunnahSalawatEnabled(bool value) => _repo.setAdhanNotifEnabled(_kSunnahSalawat, value);

  bool get sunnahFastingEnabled => _repo.adhanNotifEnabled(_kSunnahFasting);
  Future<void> setSunnahFastingEnabled(bool value) => _repo.setAdhanNotifEnabled(_kSunnahFasting, value);

  bool get sunnahWhiteDaysEnabled => _repo.adhanNotifEnabled(_kSunnahWhiteDays);
  Future<void> setSunnahWhiteDaysEnabled(bool value) => _repo.setAdhanNotifEnabled(_kSunnahWhiteDays, value);
}

final adhanNotificationPrefsProvider = Provider<AdhanNotificationPrefs>((ref) {
  return AdhanNotificationPrefs(ref.watch(userRepositoryProvider));
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
