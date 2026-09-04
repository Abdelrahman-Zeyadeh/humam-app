import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart';

/// تفضيلات الاستماع المحفوظة: القارئ المختار وسرعة التشغيل — واجهة رقيقة
/// فوق [UserRepository]. كانت تُخزَّن بـSharedPreferences؛ الهجرة كاملة
/// الآن، أُبقيت بنفس التوقيعات.
class AudioPrefs {
  AudioPrefs(this._repo);
  final UserRepository _repo;

  String get reciterId => _repo.reciterId;

  Future<void> setReciterId(String id) => _repo.setReciterId(id);

  double get speed => _repo.speed;

  Future<void> setSpeed(double speed) => _repo.setSpeed(speed);

  /// وضع "سماع مباشر" — راجع توثيق `AudioSettings.liveListenEnabled`.
  bool get liveListenEnabled => _repo.liveListenEnabled;

  Future<void> setLiveListenEnabled(bool value) => _repo.setLiveListenEnabled(value);
}

final audioPrefsProvider = Provider<AudioPrefs>((ref) {
  return AudioPrefs(ref.watch(userRepositoryProvider));
});
