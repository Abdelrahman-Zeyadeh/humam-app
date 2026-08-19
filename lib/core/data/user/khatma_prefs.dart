import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart' show KhatmaPlan, UserRepository;

export 'user_repository.dart' show KhatmaPlan;

/// خطة ختمة نشطة — واجهة رقيقة فوق [UserRepository]. كانت تُخزَّن بـ
/// SharedPreferences؛ الهجرة كاملة الآن، أُبقيت بنفس التوقيعات.
class KhatmaPrefs {
  KhatmaPrefs(this._repo);
  final UserRepository _repo;

  KhatmaPlan? get activePlan => _repo.activePlan;

  Future<void> start(int targetDays) => _repo.startKhatma(targetDays);

  Future<void> cancel() => _repo.cancelKhatma();
}

final khatmaPrefsProvider = Provider<KhatmaPrefs>((ref) {
  return KhatmaPrefs(ref.watch(userRepositoryProvider));
});

/// نفس نمط `bookmarkVersionProvider` — تخزين متزامن عبر الذاكرة المؤقتة،
/// فنجبر إعادة البناء يدوياً بعد بدء/إلغاء الخطة عبر `bump()`.
class KhatmaVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final khatmaVersionProvider = NotifierProvider<KhatmaVersionNotifier, int>(KhatmaVersionNotifier.new);
