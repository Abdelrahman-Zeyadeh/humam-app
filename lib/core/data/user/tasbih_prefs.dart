import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_prefs.dart';

/// عدّاد المسبحة الإلكترونية — يُحفظ بين تشغيلات التطبيق (بخلاف عدّ
/// الأذكار بالجلسة). مؤقت بـ SharedPreferences — نفس ملاحظة `UserPrefs`.
class TasbihPrefs {
  TasbihPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kCount = 'tasbih_count';

  int get count => _prefs.getInt(_kCount) ?? 0;

  Future<void> setCount(int value) => _prefs.setInt(_kCount, value);
}

final tasbihPrefsProvider = Provider<TasbihPrefs>((ref) {
  return TasbihPrefs(ref.watch(sharedPreferencesProvider));
});
