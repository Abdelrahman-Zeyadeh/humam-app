import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_prefs.dart';

/// تفضيلات الاستماع المحفوظة: القارئ المختار وسرعة التشغيل. مؤقت
/// بـ SharedPreferences — نفس ملاحظة `UserPrefs`.
class AudioPrefs {
  AudioPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kReciterId = 'audio_reciter_id';
  static const _kSpeed = 'audio_playback_speed';

  String get reciterId => _prefs.getString(_kReciterId) ?? 'husary';

  Future<void> setReciterId(String id) => _prefs.setString(_kReciterId, id);

  double get speed => _prefs.getDouble(_kSpeed) ?? 1.0;

  Future<void> setSpeed(double speed) => _prefs.setDouble(_kSpeed, speed);
}

final audioPrefsProvider = Provider<AudioPrefs>((ref) {
  return AudioPrefs(ref.watch(sharedPreferencesProvider));
});
