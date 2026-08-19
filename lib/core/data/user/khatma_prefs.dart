import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_prefs.dart';

/// خطة ختمة نشطة واحدة: تاريخ البدء وعدد الأيام المستهدف. الورد اليومي
/// والتقدّم يُحسبان، لا يُخزَّنان. مؤقت بـ SharedPreferences إلى حين
/// `user.db` — نفس ملاحظة `UserPrefs`.
class KhatmaPlan {
  const KhatmaPlan({required this.startDate, required this.targetDays});
  final DateTime startDate;
  final int targetDays;

  int get dailyPages => (604 / targetDays).ceil();

  DateTime get expectedEndDate => startDate.add(Duration(days: targetDays));

  int get daysElapsed {
    final d = DateTime.now().difference(startDate).inDays + 1;
    return d.clamp(1, targetDays);
  }

  /// الصفحة المتوقّع الوصول إليها اليوم لو الالتزام تام بالورد اليومي.
  int get expectedPageByNow => (daysElapsed * dailyPages).clamp(1, 604);
}

class KhatmaPrefs {
  KhatmaPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kStart = 'khatma_start_date_millis';
  static const _kTargetDays = 'khatma_target_days';

  KhatmaPlan? get activePlan {
    final startMillis = _prefs.getInt(_kStart);
    final targetDays = _prefs.getInt(_kTargetDays);
    if (startMillis == null || targetDays == null) return null;
    return KhatmaPlan(startDate: DateTime.fromMillisecondsSinceEpoch(startMillis), targetDays: targetDays);
  }

  Future<void> start(int targetDays) async {
    await _prefs.setInt(_kStart, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setInt(_kTargetDays, targetDays);
  }

  Future<void> cancel() async {
    await _prefs.remove(_kStart);
    await _prefs.remove(_kTargetDays);
  }
}

final khatmaPrefsProvider = Provider<KhatmaPrefs>((ref) {
  return KhatmaPrefs(ref.watch(sharedPreferencesProvider));
});

/// نفس نمط `bookmarkVersionProvider` — تخزين متزامن بلا Stream، فنجبر
/// إعادة البناء يدوياً بعد بدء/إلغاء الخطة عبر `bump()`.
class KhatmaVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final khatmaVersionProvider = NotifierProvider<KhatmaVersionNotifier, int>(KhatmaVersionNotifier.new);
