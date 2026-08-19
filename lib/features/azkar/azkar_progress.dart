import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// العدّ المتبقّي لكل ذكر بالجلسة الحالية فقط (`order -> remaining`) — لا
/// يُحفظ بين فتحات التطبيق، تماماً متل `revealedAyahsProvider` بوضع الحفظ:
/// أداة تدريب لحظية لا سجلّ دائم.
class AzkarProgressNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {};

  int remainingFor(int order, int total) => state[order] ?? total;

  void tap(int order, int total) {
    final current = remainingFor(order, total);
    if (current <= 0) return;
    HapticFeedback.lightImpact();
    state = {...state, order: current - 1};
  }

  void resetAll() => state = const {};
}

final azkarProgressProvider = NotifierProvider<AzkarProgressNotifier, Map<int, int>>(
  AzkarProgressNotifier.new,
);
