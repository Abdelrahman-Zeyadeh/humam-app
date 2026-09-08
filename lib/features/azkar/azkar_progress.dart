import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'azkar_repository.dart' show AzkarPeriod;

/// مفتاح تقدّم الذكر: `order` وحده **غير كافٍ** — ١٦ من ٣٤ ذكراً بمصدر
/// البيانات نوعها `0` (صباح ومساء معاً، راجع `Dhikr.appliesTo`) فتظهر
/// بنفس `order` بشاشتَي الصباح والمساء معاً. المفتاح هون `(period, order)`
/// يفصل تقدّم كل فترة تماماً — كان قبلاً `order` فقط، فتحديد ذكر مشترك
/// "تم" بالصباح كان يظهر "تم" تلقائياً بالمساء أيضاً (بلاغ صاحب المشروع).
typedef AzkarProgressKey = (AzkarPeriod period, int order);

class AzkarProgressNotifier extends Notifier<Map<AzkarProgressKey, int>> {
  @override
  Map<AzkarProgressKey, int> build() => const {};

  int remainingFor(AzkarPeriod period, int order, int total) =>
      state[(period, order)] ?? total;

  void tap(AzkarPeriod period, int order, int total) {
    final key = (period, order);
    final current = state[key] ?? total;
    if (current <= 0) return;
    if (current == 1) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    state = {...state, key: current - 1};
  }

  /// إعادة ضبط **فترة واحدة فقط** (زر التصفير بشاشة الصباح لا يلمس تقدّم
  /// المساء، والعكس) — بخلاف السلوك القديم اللي كان يصفّر كل شي معاً.
  void resetPeriod(AzkarPeriod period) {
    state = {
      for (final e in state.entries)
        if (e.key.$1 != period) e.key: e.value,
    };
  }
}

final azkarProgressProvider =
    NotifierProvider<AzkarProgressNotifier, Map<AzkarProgressKey, int>>(
      AzkarProgressNotifier.new,
    );
