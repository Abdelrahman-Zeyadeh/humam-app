import 'package:shared_preferences/shared_preferences.dart';

import 'user_repository.dart';

const _kMigratedFlag = 'migrated_user_db_v1';

/// هجرة تُنفَّذ **مرة واحدة فقط** لكل جهاز: تنقل مفاتيح `SharedPreferences`
/// القديمة (من قبل إضافة `user.db` بـdrift) إلى قاعدة البيانات الجديدة.
///
/// **لا تحذف المفاتيح القديمة** — تبقى شبكة أمان لإصدارين حسب
/// تصميم-النظام.md §٢.٥. العلم `migrated_user_db_v1` (بـSharedPreferences
/// نفسها، عمداً — لا user.db، لتفادي مشكلة الدجاجة والبيضة) يمنع إعادة
/// التنفيذ بكل إقلاع.
Future<void> migrateSharedPreferencesToUserDb({
  required SharedPreferences prefs,
  required UserRepository repo,
}) async {
  if (prefs.getBool(_kMigratedFlag) == true) return;

  // --- علامات مرجعية (كانت UserPrefs._kBookmarks) ---
  // ملاحظة: `isBookmarked` تقرأ ذاكرة مؤقتة تُملأ بـ[UserRepository.preload]
  // الذي يشتغل *بعد* هذي الدالة بـ`main()` — فهي فارغة هون دائماً، ولا
  // فائدة من فحصها. `toggleBookmark` نفسها آمنة الاستدعاء مرة واحدة لكل
  // معرّف على قاعدة فارغة (تتحقق من الصف الحقيقي بقاعدة البيانات قبل
  // الإدراج)، وهذي الدالة كلها لا تُنفَّذ إلا مرة واحدة أصلاً (علم الهجرة).
  final bookmarkIds =
      (prefs.getStringList('bookmarked_ayah_ids') ?? const []).map(int.tryParse).whereType<int>();
  for (final id in bookmarkIds) {
    await repo.addBookmarkIfAbsent(id);
  }

  // --- آخر صفحة وسلسلة الأيام (UserPrefs) + خطة الختمة (KhatmaPrefs) ---
  final khatmaStartMillis = prefs.getInt('khatma_start_date_millis');
  await repo.restoreMigratedData(
    lastPage: prefs.getInt('last_read_page'),
    streakDays: prefs.getInt('reading_streak_days'),
    streakLastDay: prefs.getString('reading_streak_last_day'),
    khatmaStartDate: khatmaStartMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(khatmaStartMillis),
    khatmaTargetDays: prefs.getInt('khatma_target_days'),
  );

  // --- إعدادات الصوت (AudioPrefs) ---
  final reciterId = prefs.getString('audio_reciter_id');
  if (reciterId != null) await repo.setReciterId(reciterId);
  final speed = prefs.getDouble('audio_playback_speed');
  if (speed != null) await repo.setSpeed(speed);

  // --- الموقع لمواقيت الصلاة/القبلة (LocationPrefs) ---
  final lat = prefs.getDouble('prayer_lat');
  final lon = prefs.getDouble('prayer_lon');
  final cityName = prefs.getString('prayer_city_name');
  if (lat != null && lon != null && cityName != null) {
    await repo.setLocation(lat: lat, lon: lon, cityName: cityName);
  }
  final calcMethod = prefs.getString('prayer_calc_method');
  if (calcMethod != null) await repo.setCalculationMethod(calcMethod);

  // --- المسبحة (TasbihPrefs) ---
  final tasbihCount = prefs.getInt('tasbih_count');
  if (tasbihCount != null) await repo.setTasbihCount(tasbihCount);

  await prefs.setBool(_kMigratedFlag, true);
}

const _kMigratedAdhanPrefsFlag = 'migrated_adhan_prefs_v1';

/// هجرة منفصلة **بعلم مستقل** عن [migrateSharedPreferencesToUserDb] —
/// أُضيفت لاحقاً بعد أن كان `_kMigratedFlag` قد يكون `true` فعلاً على
/// أجهزة هاجرت الدفعة الأولى، فإعادة استخدام نفس العلم كانت ستمنع تنفيذ
/// هذه الدفعة الجديدة إطلاقاً على تلك الأجهزة. تنقل تفضيلات إشعارات
/// الأذان (`AdhanNotificationPrefs` القديمة) إلى `AdhanNotificationSettings`
/// بـ`user.db`. **لا تحذف المفاتيح القديمة** — نفس قاعدة §٢.٥.
Future<void> migrateAdhanNotificationPrefs({
  required SharedPreferences prefs,
  required UserRepository repo,
}) async {
  if (prefs.getBool(_kMigratedAdhanPrefsFlag) == true) return;

  final master = prefs.getBool('adhan_notifications_enabled');
  if (master != null) await repo.setAdhanNotifEnabled('master', master);

  for (final prayer in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
    final enabled = prefs.getBool('adhan_enabled_$prayer');
    if (enabled != null) await repo.setAdhanNotifEnabled(prayer, enabled);
  }

  await prefs.setBool(_kMigratedAdhanPrefsFlag, true);
}
