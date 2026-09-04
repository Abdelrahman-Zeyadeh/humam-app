import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart' show KhatmaPlan, UserRepository;

export 'user_repository.dart' show KhatmaPlan;

/// خطط الختمة — واجهة رقيقة فوق [UserRepository]. تدير **قائمة** خطط لا
/// خطة واحدة (بطلب صاحب المشروع توحيد سلوك الختمة مع الحفظ) — نفس نمط
/// `hifz_prefs.dart` بالضبط.
class KhatmaPrefs {
  KhatmaPrefs(this._repo);
  final UserRepository _repo;

  List<KhatmaPlan> get activePlans => _repo.khatmaPlans;

  Future<KhatmaPlan> start(int targetDays, {required int startPage}) =>
      _repo.startKhatma(targetDays, startPage: startPage);

  Future<void> cancel(int planId) => _repo.cancelKhatmaPlan(planId);

  Future<void> updateCurrentPage(int planId, int page) =>
      _repo.updateKhatmaCurrentPage(planId, page);
}

final khatmaPrefsProvider = Provider<KhatmaPrefs>((ref) {
  return KhatmaPrefs(ref.watch(userRepositoryProvider));
});

/// نفس نمط `hifzVersionProvider` — تخزين متزامن عبر الذاكرة المؤقتة،
/// فنجبر إعادة البناء يدوياً بعد بدء/إلغاء خطة عبر `bump()`.
class KhatmaVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final khatmaVersionProvider = NotifierProvider<KhatmaVersionNotifier, int>(
  KhatmaVersionNotifier.new,
);
