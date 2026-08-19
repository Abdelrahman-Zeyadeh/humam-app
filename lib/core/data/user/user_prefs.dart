import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> bumpStreakIfNewDay() => _repo.bumpStreakIfNewDay();

  // --- سلاسل استمرار مستقلة لكل نشاط (راجع UserCategories) ---

  int streakDaysFor(String category) => _repo.streakDaysFor(category);

  bool completedTodayFor(String category) => _repo.completedTodayFor(category);

  Future<void> bumpCategoryStreakIfNewDay(String category) => _repo.bumpCategoryStreakIfNewDay(category);

  // --- تذكير قيام الليل ---

  bool get qiyamEnabled => _repo.qiyamEnabled;
  int? get qiyamHour => _repo.qiyamHour;
  int get qiyamMinute => _repo.qiyamMinute;

  Future<void> setQiyamReminder({required bool enabled, int? hour, int? minute}) =>
      _repo.setQiyamReminder(enabled: enabled, hour: hour, minute: minute);

  // --- أقسام مفضَّلة من مكتبة حصن المسلم ---

  bool isAzkarFavorite(int categoryId) => _repo.isAzkarFavorite(categoryId);

  Set<int> get azkarFavoriteCategoryIds => _repo.azkarFavoriteCategoryIds;

  Future<void> toggleAzkarFavorite(int categoryId) => _repo.toggleAzkarFavorite(categoryId);
}

/// `SharedPreferences` تبقى للإعدادات البسيطة فقط (تصميم-النظام.md
/// القرار المعماري #٦) — علم الهجرة ووضع الثيم، لا بيانات مستخدم حقيقية.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('يُهيَّأ بـ overrideWithValue داخل main() قبل تشغيل التطبيق');
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

final bookmarkVersionProvider = NotifierProvider<BookmarkVersionNotifier, int>(BookmarkVersionNotifier.new);

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
    NotifierProvider<CategoryStreakVersionNotifier, int>(CategoryStreakVersionNotifier.new);

/// نفس النمط — إجبار إعادة بناء قائمة مكتبة الأذكار عند تبديل تفضيل.
class AzkarFavoriteVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final azkarFavoriteVersionProvider =
    NotifierProvider<AzkarFavoriteVersionNotifier, int>(AzkarFavoriteVersionNotifier.new);
