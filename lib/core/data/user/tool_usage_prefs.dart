import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_prefs.dart';
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

const _kPinnedToolsPrefKey = 'user_pinned_tools_v1';
const _kRecentlyUsedToolsPrefKey = 'user_recently_used_tools_v1';

class PinnedToolsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_kPinnedToolsPrefKey) ?? const [];
  }

  Future<void> togglePin(String toolId) async {
    final current = [...state];
    if (current.contains(toolId)) {
      current.remove(toolId);
    } else {
      current.add(toolId);
    }
    state = current;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kPinnedToolsPrefKey, current);
  }

  bool isPinned(String toolId) => state.contains(toolId);
}

final pinnedToolsProvider =
    NotifierProvider<PinnedToolsNotifier, List<String>>(
      PinnedToolsNotifier.new,
    );

/// الأدوات المستخدمة مؤخراً (آخر ٣-٥ أدوات دون تكرار)
class RecentlyUsedToolsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_kRecentlyUsedToolsPrefKey) ?? const [];
  }

  Future<void> recordUse(String toolId) async {
    final current = state.where((id) => id != toolId).toList();
    current.insert(0, toolId);
    if (current.length > 5) {
      current.removeRange(5, current.length);
    }
    state = current;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kRecentlyUsedToolsPrefKey, current);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kRecentlyUsedToolsPrefKey);
  }
}

final recentlyUsedToolsProvider =
    NotifierProvider<RecentlyUsedToolsNotifier, List<String>>(
      RecentlyUsedToolsNotifier.new,
    );

