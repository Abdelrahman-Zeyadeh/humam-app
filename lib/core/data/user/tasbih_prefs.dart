import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_prefs.dart';
import 'user_providers.dart';
import 'user_repository.dart';

/// تفضيلات المسبحة الإلكترونية المتقدمة — تدعم الأهداف والحلقات
/// والعداد الإجمالي والتنبيه اللمسي واختيار الذكر.
class TasbihPrefs {
  TasbihPrefs(this._repo, this._prefs);
  final UserRepository _repo;
  final SharedPreferences _prefs;

  static const _kTargetGoal = 'tasbih_target_goal';
  static const _kCompletedCycles = 'tasbih_completed_cycles';
  static const _kTotalCount = 'tasbih_total_count';
  static const _kSelectedPhrase = 'tasbih_selected_phrase';
  static const _kVibrationEnabled = 'tasbih_vibration_enabled';
  static const _kSoundEnabled = 'tasbih_sound_enabled';

  int get count => _repo.tasbihCount;
  Future<void> setCount(int value) => _repo.setTasbihCount(value);

  int get targetGoal => _prefs.getInt(_kTargetGoal) ?? 33;
  Future<void> setTargetGoal(int value) => _prefs.setInt(_kTargetGoal, value);

  int get completedCycles => _prefs.getInt(_kCompletedCycles) ?? 0;
  Future<void> setCompletedCycles(int value) => _prefs.setInt(_kCompletedCycles, value);

  int get totalCount => _prefs.getInt(_kTotalCount) ?? _repo.tasbihCount;
  Future<void> setTotalCount(int value) => _prefs.setInt(_kTotalCount, value);

  String get selectedPhrase => _prefs.getString(_kSelectedPhrase) ?? 'سُبْحَانَ اللَّهِ';
  Future<void> setSelectedPhrase(String value) => _prefs.setString(_kSelectedPhrase, value);

  bool get vibrationEnabled => _prefs.getBool(_kVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool value) => _prefs.setBool(_kVibrationEnabled, value);

  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? false;
  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_kSoundEnabled, value);

  static const _kCustomPhrases = 'tasbih_custom_phrases';

  List<String> get customPhrases => _prefs.getStringList(_kCustomPhrases) ?? [];

  Future<void> addCustomPhrase(String phrase) async {
    final list = List<String>.from(customPhrases);
    if (!list.contains(phrase)) {
      list.add(phrase);
      await _prefs.setStringList(_kCustomPhrases, list);
    }
  }

  Future<void> removeCustomPhrase(String phrase) async {
    final list = List<String>.from(customPhrases);
    list.remove(phrase);
    await _prefs.setStringList(_kCustomPhrases, list);
  }
}

final tasbihPrefsProvider = Provider<TasbihPrefs>((ref) {
  return TasbihPrefs(
    ref.watch(userRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
