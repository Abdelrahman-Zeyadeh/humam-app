import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart';

/// عدّاد المسبحة الإلكترونية — يُحفظ بين تشغيلات التطبيق (بخلاف عدّ
/// الأذكار بالجلسة) — واجهة رقيقة فوق [UserRepository]. كانت تُخزَّن
/// بـSharedPreferences؛ الهجرة كاملة الآن، أُبقيت بنفس التوقيعات.
class TasbihPrefs {
  TasbihPrefs(this._repo);
  final UserRepository _repo;

  int get count => _repo.tasbihCount;

  Future<void> setCount(int value) => _repo.setTasbihCount(value);
}

final tasbihPrefsProvider = Provider<TasbihPrefs>((ref) {
  return TasbihPrefs(ref.watch(userRepositoryProvider));
});
