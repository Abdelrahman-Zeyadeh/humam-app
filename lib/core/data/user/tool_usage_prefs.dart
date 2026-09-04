import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart' show UserRepository;

/// إحصاء استخدام أدوات شاشة "أدواتي" — واجهة رقيقة فوق [UserRepository]،
/// نفس نمط `custom_habits_prefs.dart`.
class ToolUsagePrefs {
  ToolUsagePrefs(this._repo);
  final UserRepository _repo;

  Future<void> recordTap(String toolId) => _repo.recordToolTap(toolId);

  Future<List<String>> mostUsed({int limit = 4}) =>
      _repo.mostUsedToolIds(limit: limit);
}

final toolUsagePrefsProvider = Provider<ToolUsagePrefs>((ref) {
  return ToolUsagePrefs(ref.watch(userRepositoryProvider));
});

/// نفس نمط `customHabitsVersionProvider` — `mostUsedToolIds` استعلام
/// مباشر غير مراقَب تلقائياً بأي Stream، فنجبر إعادة بناء صف "الأكثر
/// استخدامًا" يدوياً بعد كل ضغطة عبر `bump()`.
class ToolUsageVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final toolUsageVersionProvider =
    NotifierProvider<ToolUsageVersionNotifier, int>(
      ToolUsageVersionNotifier.new,
    );

/// أعلى ٤ أدوات استخداماً بشاشة "أدواتي" — راجع `UserRepository.
/// mostUsedToolIds`. `toolUsageVersionProvider` يُجبر إعادة الجلب بعد كل
/// ضغطة (`bump()` يُستدعى من `_ToolItem.onTap`).
final mostUsedToolIdsProvider = FutureProvider<List<String>>((ref) {
  ref.watch(toolUsageVersionProvider);
  return ref.read(toolUsagePrefsProvider).mostUsed();
});
