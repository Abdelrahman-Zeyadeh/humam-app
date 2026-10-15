import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart' show HifzPlan, UserRepository;

export 'user_repository.dart' show HifzPlan;

/// خطط الحفظ — واجهة رقيقة فوق [UserRepository]، نفس نمط `khatma_prefs.dart`
/// إلا أنها تدير **قائمة** خطط لا خطة واحدة (راجع توثيق `HifzPlan`).
class HifzPrefs {
  HifzPrefs(this._repo);
  final UserRepository _repo;

  List<HifzPlan> get plans => _repo.hifzPlans;

  Future<HifzPlan> start({required int fromAyahId, required int toAyahId}) =>
      _repo.startHifzPlan(fromAyahId: fromAyahId, toAyahId: toAyahId);

  Future<void> cancel(int planId) => _repo.cancelHifzPlan(planId);

  Future<void> updateCurrentAyah(int planId, int ayahId) => _repo.updateHifzCurrentAyah(planId, ayahId);

  // --- مراجعة ذكية (SRS، راجع HifzAyahReviews) ---

  Future<int> dueReviewCount(int planId) => _repo.dueHifzAyahCountForPlan(planId);

  Future<List<int>> dueReviewAyahIds(int planId) => _repo.dueHifzAyahIdsForPlan(planId);

  Future<void> gradeReview(int planId, int ayahId, int quality) =>
      _repo.gradeHifzAyahReview(planId, ayahId, quality);

  bool get reminderEnabled => _repo.hifzEnabled;
  int? get reminderHour => _repo.hifzHour;
  int get reminderMinute => _repo.hifzMinute;

  Future<void> setReminder({required bool enabled, int? hour, int? minute}) =>
      _repo.setHifzReminder(enabled: enabled, hour: hour, minute: minute);

  /// راجع توثيق `UserRepository.hifzReviewedToday`.
  Future<bool> reviewedToday() => _repo.hifzReviewedToday();

  /// خريطة إتقان الحفظ لكافة الآيات المسجلة
  Future<Map<int, String>> allMasteryMap() => _repo.allHifzMasteryMap();

  /// تعيين حالة إتقان آية محددة ('mastered' | 'needsReview' | 'unmemorized')
  Future<void> setAyahMasteryStatus(int ayahId, String status) =>
      _repo.setAyahMasteryStatus(ayahId, status);

  /// تعيين حالة إتقان مجموعة آيات دفعة واحدة (لسورة كاملة أو نطاق)
  Future<void> setMultipleAyahsMasteryStatus(List<int> ayahIds, String status) =>
      _repo.setMultipleAyahsMasteryStatus(ayahIds, status);
}

final hifzPrefsProvider = Provider<HifzPrefs>((ref) {
  return HifzPrefs(ref.watch(userRepositoryProvider));
});

/// نفس نمط `khatmaVersionProvider` — تخزين متزامن عبر الذاكرة المؤقتة،
/// فنجبر إعادة البناء يدوياً بعد أي تغيير عبر `bump()`.
class HifzVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final hifzVersionProvider = NotifierProvider<HifzVersionNotifier, int>(HifzVersionNotifier.new);
