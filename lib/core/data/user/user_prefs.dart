import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين مستخدم بسيط عبر `SharedPreferences` — علامات مرجعية وآخر صفحة
/// قراءة فقط. مؤقت إلى حين `user.db` (drift) بمرحلة التخزين والهجرة؛
/// المفاتيح هنا مصمَّمة لتُقرأ بسهولة لاحقاً عند الهجرة، لا تُعاد تسميتها.
class UserPrefs {
  UserPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kBookmarks = 'bookmarked_ayah_ids';
  static const _kLastPage = 'last_read_page';

  Set<int> get bookmarkedAyahIds =>
      (_prefs.getStringList(_kBookmarks) ?? const []).map(int.parse).toSet();

  Future<void> toggleBookmark(int ayahId) async {
    final current = bookmarkedAyahIds;
    if (!current.remove(ayahId)) current.add(ayahId);
    await _prefs.setStringList(_kBookmarks, current.map((e) => '$e').toList());
  }

  bool isBookmarked(int ayahId) => bookmarkedAyahIds.contains(ayahId);

  int? get lastReadPage => _prefs.getInt(_kLastPage);

  Future<void> setLastReadPage(int page) => _prefs.setInt(_kLastPage, page);

  // --- سلسلة أيام القراءة المتتالية ---
  // تُحدَّث مرة واحدة بأول تنقّل صفحة بكل يوم (راجع _bumpStreakIfNewDay).
  static const _kStreakCount = 'reading_streak_days';
  static const _kStreakLastDay = 'reading_streak_last_day'; // yyyy-mm-dd

  int get streakDays => _prefs.getInt(_kStreakCount) ?? 0;

  /// يُستدعى عند كل تغيير صفحة بالمصحف. يزيد السلسلة يوماً واحداً بأول
  /// زيارة كل يوم تقويمي، ويصفّرها لو انقطع يوم كامل أو أكثر بين آخر
  /// زيارة واليوم — لا حساب دقيق بالساعات، فقط تاريخ التقويم المحلي.
  Future<void> bumpStreakIfNewDay() async {
    final today = _dateKey(DateTime.now());
    final lastDay = _prefs.getString(_kStreakLastDay);
    if (lastDay == today) return; // زيارة تانية بنفس اليوم — لا تغيير

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final continued = lastDay == yesterday;
    final newCount = continued ? streakDays + 1 : 1;

    await _prefs.setInt(_kStreakCount, newCount);
    await _prefs.setString(_kStreakLastDay, today);
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('يُهيَّأ بـ overrideWithValue داخل main() قبل تشغيل التطبيق');
});

final userPrefsProvider = Provider<UserPrefs>((ref) {
  return UserPrefs(ref.watch(sharedPreferencesProvider));
});

/// إشعار بسيط يُعاد بناؤه عند تبديل علامة — الودجتات يلي بتراقب علامات
/// آية معيّنة تستخدم `bookmarkVersionProvider` لإجبار إعادة القراءة من
/// [UserPrefs] (التخزين نفسه متزامن، لا حاجة لـ FutureProvider).
class BookmarkVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final bookmarkVersionProvider = NotifierProvider<BookmarkVersionNotifier, int>(BookmarkVersionNotifier.new);
