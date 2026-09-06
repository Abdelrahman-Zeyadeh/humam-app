import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';
import 'user_database.dart' show AyahNote;
import 'user_providers.dart';
import 'user_repository.dart';

/// علامات مرجعية وآخر صفحة قراءة وسلسلة الأيام — واجهة رقيقة فوق
/// [UserRepository] (`user.db` بـdrift). كانت تُخزَّن مباشرة بـ
/// `SharedPreferences`؛ الهجرة كاملة الآن (`prefs_migration.dart`)، هذه
/// الفئة أُبقيت بنفس التوقيعات تماماً لتفادي تغيير كل الشاشات المستهلِكة.
class UserPrefs {
  UserPrefs(this._repo);
  final UserRepository _repo;

  Set<int> get bookmarkedAyahIds => _repo.bookmarkedAyahIds;

  Future<void> toggleBookmark(int ayahId) => _repo.toggleBookmark(ayahId);

  bool isBookmarked(int ayahId) => _repo.isBookmarked(ayahId);

  int? get lastReadPage => _repo.lastReadPage;

  Future<void> setLastReadPage(int page) => _repo.setLastReadPage(page);

  int get streakDays => _repo.streakDays;

  bool get readToday => _repo.readToday;

  Future<void> bumpStreakIfNewDay() => _repo.bumpStreakIfNewDay();

  // --- سلاسل استمرار مستقلة لكل نشاط (راجع UserCategories) ---

  int streakDaysFor(String category) => _repo.streakDaysFor(category);

  bool completedTodayFor(String category) => _repo.completedTodayFor(category);

  Future<void> bumpCategoryStreakIfNewDay(String category) =>
      _repo.bumpCategoryStreakIfNewDay(category);

  Future<void> reloadCategoryStreaks() => _repo.reloadCategoryStreaks();

  /// إتمام آخر ٧ أيام (اليوم آخرها) — راجع `UserRepository.weekCompletionFor`.
  Future<List<bool>> weekCompletionFor(String category) =>
      _repo.weekCompletionFor(category);

  /// إتمام الأيام الثابتة من السبت إلى الجمعة للأسبوع الحالي
  Future<List<bool>> fixedWeekCompletionFor(String category) =>
      _repo.fixedWeekCompletionFor(category);

  // --- تذكيرات أنشطة عامة (راجع UserRepository) ---

  bool reminderEnabledFor(String category) =>
      _repo.reminderEnabledFor(category);
  int? reminderHourFor(String category) => _repo.reminderHourFor(category);
  int reminderMinuteFor(String category) => _repo.reminderMinuteFor(category);

  Future<void> setActivityReminder(
    String category, {
    required bool enabled,
    int? hour,
    int? minute,
  }) => _repo.setActivityReminder(
    category,
    enabled: enabled,
    hour: hour,
    minute: minute,
  );

  // --- تذكير قيام الليل ---

  bool get qiyamEnabled => _repo.qiyamEnabled;
  int? get qiyamHour => _repo.qiyamHour;
  int get qiyamMinute => _repo.qiyamMinute;

  Future<void> setQiyamReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) => _repo.setQiyamReminder(enabled: enabled, hour: hour, minute: minute);

  // --- صوت الأذان (المؤذن) ---

  String get adhanVoiceId => _repo.adhanVoiceId;

  Future<void> setAdhanVoiceId(String id) => _repo.setAdhanVoiceId(id);

  int prayerOffsetFor(String prayerKey) => _repo.prayerOffsetFor(prayerKey);
  Future<void> setPrayerOffsetFor(String prayerKey, int minutes) =>
      _repo.setPrayerOffsetFor(prayerKey, minutes);

  int get preAdhanMinutes => _repo.preAdhanMinutes;
  Future<void> setPreAdhanMinutes(int minutes) =>
      _repo.setPreAdhanMinutes(minutes);

  int iqamahMinutesFor(String prayerKey) => _repo.iqamahMinutesFor(prayerKey);
  Future<void> setIqamahMinutesFor(String prayerKey, int minutes) =>
      _repo.setIqamahMinutesFor(prayerKey, minutes);

  String adhanVoiceFor(String prayerKey) => _repo.adhanVoiceFor(prayerKey);
  Future<void> setAdhanVoiceFor(String prayerKey, String voiceId) =>
      _repo.setAdhanVoiceFor(prayerKey, voiceId);

  String adhanModeFor(String prayerKey) => _repo.adhanModeFor(prayerKey);
  Future<void> setAdhanModeFor(String prayerKey, String mode) =>
      _repo.setAdhanModeFor(prayerKey, mode);

  // --- فواصل المصحف (راجع BookmarkTypes) ---

  int? activityBookmarkAyah(String type) => _repo.activityBookmarkAyah(type);

  Future<void> setActivityBookmark(String type, int ayahId) =>
      _repo.setActivityBookmark(type, ayahId);

  Future<void> clearActivityBookmark(String type) =>
      _repo.clearActivityBookmark(type);

  // --- أقسام مفضَّلة من مكتبة حصن المسلم ---

  bool isAzkarFavorite(int categoryId) => _repo.isAzkarFavorite(categoryId);

  Set<int> get azkarFavoriteCategoryIds => _repo.azkarFavoriteCategoryIds;

  Future<void> toggleAzkarFavorite(int categoryId) =>
      _repo.toggleAzkarFavorite(categoryId);

  // --- عدد آيات جلسات قيام الليل ---

  Future<int> qiyamAyahCountFor(String dateKey) =>
      _repo.qiyamAyahCountFor(dateKey);

  Future<int> addQiyamAyahCount(String dateKey, int delta) =>
      _repo.addQiyamAyahCount(dateKey, delta);

  // --- نسخ احتياطي محلي (راجع backup_service.dart) ---

  BackupService get backup => _repo.backup;

  // --- إعداد متابعة "هل صليت؟" (التسجيل نفسه عبر CategoryStreaks الموجود) ---

  bool get prayerCheckinEnabled => _repo.prayerCheckinEnabled;
  int get prayerCheckinFirstDelayMinutes =>
      _repo.prayerCheckinFirstDelayMinutes;

  Future<void> setPrayerCheckinSettings({
    required bool enabled,
    int? firstDelayMinutes,
  }) => _repo.setPrayerCheckinSettings(
    enabled: enabled,
    firstDelayMinutes: firstDelayMinutes,
  );

  // --- تنبيه "أذكار بعد الصلاة" (مستقل عن متابعة "هل صليت؟" أعلاه) ---

  bool get postPrayerAzkarEnabled => _repo.postPrayerAzkarEnabled;
  int get postPrayerAzkarDelayMinutes => _repo.postPrayerAzkarDelayMinutes;

  Future<void> setPostPrayerAzkarSettings({
    required bool enabled,
    int? delayMinutes,
  }) => _repo.setPostPrayerAzkarSettings(
    enabled: enabled,
    delayMinutes: delayMinutes,
  );

  // --- وضع "لا تُزعجني وقت القراءة" (راجع dnd_service.dart) ---

  bool get dndWhileReadingEnabled => _repo.dndWhileReadingEnabled;

  Future<void> setDndWhileReadingEnabled(bool value) =>
      _repo.setDndWhileReadingEnabled(value);

  // --- نسخ احتياطي سحابي دوري تلقائي (راجع CloudSyncController.maybeAutoSync) ---

  bool get autoCloudBackupEnabled => _repo.autoCloudBackupEnabled;

  Future<void> setAutoCloudBackupEnabled(bool value) =>
      _repo.setAutoCloudBackupEnabled(value);

  // --- لوحة ألوان صفحة المصحف ---

  String get mushafPaletteId => _repo.mushafPaletteId;

  Future<void> setMushafPaletteId(String id) => _repo.setMushafPaletteId(id);

  String get mushafNightMode => _repo.mushafNightMode;

  Future<void> setMushafNightMode(String mode) =>
      _repo.setMushafNightMode(mode);

  // --- لون تمييز التطبيق العام ---

  String get accentColorId => _repo.accentColorId;

  Future<void> setAccentColorId(String id) => _repo.setAccentColorId(id);

  // --- اسم المستخدم والملف الشخصي ---
  String get userName => _repo.userName;
  Future<void> setUserName(String name) => _repo.setUserName(name);

  String get userAvatar => _repo.userAvatar;
  Future<void> setUserAvatar(String avatar) => _repo.setUserAvatar(avatar);

  // --- إعداد أذكار وأدعية كل ساعة ---
  bool get hourlyDhikrEnabled => _repo.hourlyDhikrEnabled;
  int get hourlyDhikrStartHour => _repo.hourlyDhikrStartHour;
  int get hourlyDhikrEndHour => _repo.hourlyDhikrEndHour;
  int get hourlyDhikrIntervalHours => _repo.hourlyDhikrIntervalHours;

  Future<void> setHourlyDhikr({
    required bool enabled,
    int? startHour,
    int? endHour,
    int? intervalHours,
  }) => _repo.setHourlyDhikr(
    enabled: enabled,
    startHour: startHour,
    endHour: endHour,
    intervalHours: intervalHours,
  );

  // --- تكرار عام (بالدقائق) لأي تذكير — راجع `UserRepository` ---
  int? reminderIntervalMinutesFor(String category) =>
      _repo.reminderIntervalMinutesFor(category);

  Future<void> setReminderIntervalMinutes(String category, int? minutes) =>
      _repo.setReminderIntervalMinutes(category, minutes);

  // --- ملاحظات الآيات (راجع AyahNotes/ayah_actions_sheet.dart) ---

  Future<String?> noteForAyah(int ayahId) => _repo.noteForAyah(ayahId);

  Future<void> setNoteForAyah(int ayahId, String text) =>
      _repo.setNoteForAyah(ayahId, text);

  Future<void> clearNoteForAyah(int ayahId) => _repo.clearNoteForAyah(ayahId);

  Future<Set<int>> notedAyahIds() => _repo.notedAyahIds();

  Future<List<AyahNote>> allNotes() => _repo.allNotes();

  // --- سجل القراءة/الاستماع/السبحات التراكمي (راجع UserRepository) ---

  Future<void> logReadingSession({
    required int pagesRead,
    int ayahsRead = 0,
    int minutesSpent = 0,
  }) => _repo.logReadingSession(
    pagesRead: pagesRead,
    ayahsRead: ayahsRead,
    minutesSpent: minutesSpent,
  );

  Future<void> logAudioSeconds(int seconds) => _repo.logAudioSeconds(seconds);

  Future<void> logTasbihCompletion(String azkarKey, int count) =>
      _repo.logTasbihCompletion(azkarKey, count);

  Future<({int pages, int ayahs, int minutes})> getReadingLog(int days) =>
      _repo.getReadingLog(days);

  Future<int> getAudioMinutes(int days) => _repo.getAudioMinutes(days);

  Future<DateTime?> getTasbihLastCompleted(String azkarKey) =>
      _repo.getTasbihLastCompleted(azkarKey);

  Future<({int pages, int minutes, int azkarCount, int prayersConfirmed})>
  eveningSummaryStatsToday() => _repo.eveningSummaryStatsToday();

  // --- استعادة/دمج من مزامنة سحابية اختيارية (راجع UserRepository) ---

  Future<void> restoreKhatmaPlansIfEmpty(List<Map<String, dynamic>> plans) =>
      _repo.restoreKhatmaPlansIfEmpty(plans);

  Future<void> restoreHifzPlansIfEmpty(List<Map<String, dynamic>> plans) =>
      _repo.restoreHifzPlansIfEmpty(plans);

  Future<void> mergeBookmarksFromCloud(List<int> ayahIds) =>
      _repo.mergeBookmarksFromCloud(ayahIds);

  Future<void> mergeAzkarFavoritesFromCloud(List<int> categoryIds) =>
      _repo.mergeAzkarFavoritesFromCloud(categoryIds);
}

/// `SharedPreferences` تبقى للإعدادات البسيطة فقط (تصميم-النظام.md
/// القرار المعماري #٦) — علم الهجرة ووضع الثيم، لا بيانات مستخدم حقيقية.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'يُهيَّأ بـ overrideWithValue داخل main() قبل تشغيل التطبيق',
  );
});

final userPrefsProvider = Provider<UserPrefs>((ref) {
  return UserPrefs(ref.watch(userRepositoryProvider));
});

/// إشعار بسيط يُعاد بناؤه عند تبديل علامة — الودجتات يلي بتراقب علامات
/// آية معيّنة تستخدم `bookmarkVersionProvider` لإجبار إعادة القراءة من
/// [UserPrefs] (التخزين نفسه متزامن عبر الذاكرة المؤقتة، لا حاجة لـ Stream).
class BookmarkVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final bookmarkVersionProvider = NotifierProvider<BookmarkVersionNotifier, int>(
  BookmarkVersionNotifier.new,
);

/// نفس نمط `bookmarkVersionProvider` — يجبر إعادة قراءة `noteForAyah` بعد
/// حفظ/حذف ملاحظة (`ayah_actions_sheet.dart`)، بما إنها استعلام مباشر من
/// القرص عند الطلب لا ذاكرة مؤقتة (`FutureProvider.family` بلا هذا لا يعيد
/// الجلب تلقائياً بعد كتابة خارجية).
class AyahNoteVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final ayahNoteVersionProvider = NotifierProvider<AyahNoteVersionNotifier, int>(
  AyahNoteVersionNotifier.new,
);

/// نفس نمط `bookmarkVersionProvider` — إجبار إعادة بناء الودجتات المراقِبة
/// لسلاسل الاستمرار المستقلة (`streakDaysFor`/`completedTodayFor`) أو
/// إعداد قيام الليل بعد أي تغيير، بما إنها كلها بذاكرة مؤقتة متزامنة بلا
/// Stream خاص بها.
class CategoryStreakVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final categoryStreakVersionProvider =
    NotifierProvider<CategoryStreakVersionNotifier, int>(
      CategoryStreakVersionNotifier.new,
    );

/// نفس النمط — إجبار إعادة بناء قائمة مكتبة الأذكار عند تبديل تفضيل.
class AzkarFavoriteVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final azkarFavoriteVersionProvider =
    NotifierProvider<AzkarFavoriteVersionNotifier, int>(
      AzkarFavoriteVersionNotifier.new,
    );

/// نفس النمط — إجبار إعادة بناء منتقي صوت الأذان (`settings_screen.dart`)
/// عند تبديل الصوت المختار.
class AdhanVoiceVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final adhanVoiceVersionProvider =
    NotifierProvider<AdhanVoiceVersionNotifier, int>(
      AdhanVoiceVersionNotifier.new,
    );

/// نفس النمط — إجبار إعادة بناء الودجتات المراقِبة لفواصل المصحف
/// (`ActivityBookmarks`) بعد ضبط/حذف أي منها.
class ActivityBookmarkVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final activityBookmarkVersionProvider =
    NotifierProvider<ActivityBookmarkVersionNotifier, int>(
      ActivityBookmarkVersionNotifier.new,
    );

/// نفس النمط — إجبار إعادة بناء صفحة المصحف عند تبديل لوحة الألوان
/// (`settings_screen.dart` → `mushaf_screen.dart`/`mushaf_page_widget.dart`).
class MushafPaletteVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final mushafPaletteVersionProvider =
    NotifierProvider<MushafPaletteVersionNotifier, int>(
      MushafPaletteVersionNotifier.new,
    );

/// نفس النمط — إجبار إعادة بناء `MaterialApp` (`main.dart`) عند تبديل لون
/// تمييز التطبيق (`settings_screen.dart`).
class AccentColorVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final accentColorVersionProvider =
    NotifierProvider<AccentColorVersionNotifier, int>(
      AccentColorVersionNotifier.new,
    );

class UserNameVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final userNameVersionProvider = NotifierProvider<UserNameVersionNotifier, int>(
  UserNameVersionNotifier.new,
);

class HourlyDhikrVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final hourlyDhikrVersionProvider =
    NotifierProvider<HourlyDhikrVersionNotifier, int>(
      HourlyDhikrVersionNotifier.new,
    );
