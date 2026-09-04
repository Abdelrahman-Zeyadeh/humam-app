import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final fastingPrefsProvider = Provider<FastingPrefs>((ref) => FastingPrefs());

class FastingVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final fastingVersionProvider = NotifierProvider<FastingVersionNotifier, int>(
  FastingVersionNotifier.new,
);

class FastingPrefs {
  static const _kLoggedFastsKey = 'humam_logged_fasts_v1';
  static const _kEveReminderKey = 'humam_fasting_eve_reminder_enabled';
  static const _kSuhoorReminderKey = 'humam_fasting_suhoor_reminder_enabled';

  Future<Set<String>> getLoggedFasts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kLoggedFastsKey) ?? [];
    return list.toSet();
  }

  Future<bool> isFasted(DateTime date) async {
    final key = _formatDateKey(date);
    final set = await getLoggedFasts();
    return set.contains(key);
  }

  Future<void> toggleFast(DateTime date) async {
    final key = _formatDateKey(date);
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_kLoggedFastsKey) ?? []).toSet();
    if (set.contains(key)) {
      set.remove(key);
    } else {
      set.add(key);
    }
    await prefs.setStringList(_kLoggedFastsKey, set.toList());
  }

  Future<int> totalFastsThisYear() async {
    final set = await getLoggedFasts();
    final currentYear = DateTime.now().year.toString();
    return set.where((k) => k.startsWith(currentYear)).length;
  }

  Future<bool> isEveReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEveReminderKey) ?? true;
  }

  Future<void> setEveReminderEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEveReminderKey, val);
  }

  Future<bool> isSuhoorReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSuhoorReminderKey) ?? true;
  }

  Future<void> setSuhoorReminderEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSuhoorReminderKey, val);
  }

  static String _formatDateKey(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
