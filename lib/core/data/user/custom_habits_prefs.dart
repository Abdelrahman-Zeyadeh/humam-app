import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart' show CustomHabit, UserRepository;

export 'user_repository.dart' show CustomHabit;

/// عادات مخصّصة — واجهة رقيقة فوق [UserRepository]، نفس نمط `hifz_prefs.dart`
/// (قائمة عادات لا عادة واحدة، راجع توثيق [CustomHabit]).
class CustomHabitsPrefs {
  CustomHabitsPrefs(this._repo);
  final UserRepository _repo;

  List<CustomHabit> get habits => _repo.customHabits;

  Future<CustomHabit> create({
    required String title,
    int targetDaily = 1,
    int? reminderHour,
    int reminderMinute = 0,
  }) => _repo.createCustomHabit(
    title: title,
    targetDaily: targetDaily,
    reminderHour: reminderHour,
    reminderMinute: reminderMinute,
  );

  Future<void> delete(int habitId) => _repo.deleteCustomHabit(habitId);

  Future<void> setReminder(
    int habitId, {
    required bool enabled,
    int? hour,
    int? minute,
  }) => _repo.setCustomHabitReminder(
    habitId,
    enabled: enabled,
    hour: hour,
    minute: minute,
  );

  Future<int> progressToday(int habitId) =>
      _repo.customHabitProgressToday(habitId);

  Future<int> addProgress(int habitId, {int delta = 1}) =>
      _repo.addCustomHabitProgress(habitId, delta: delta);

  Future<int> streakDays(int habitId, int targetDaily) =>
      _repo.customHabitStreakDays(habitId, targetDaily);
}

final customHabitsPrefsProvider = Provider<CustomHabitsPrefs>((ref) {
  return CustomHabitsPrefs(ref.watch(userRepositoryProvider));
});

/// نفس نمط `hifzVersionProvider` — تخزين متزامن عبر الذاكرة المؤقتة، فنجبر
/// إعادة البناء يدوياً بعد أي تغيير عبر `bump()`.
class CustomHabitsVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final customHabitsVersionProvider =
    NotifierProvider<CustomHabitsVersionNotifier, int>(
      CustomHabitsVersionNotifier.new,
    );
