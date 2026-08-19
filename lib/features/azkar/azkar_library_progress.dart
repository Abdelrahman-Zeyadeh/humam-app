import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نفس نمط `AzkarProgressNotifier` (azkar_progress.dart) لكن لمكتبة حصن
/// المسلم الكاملة — مفتاح نصي `"categoryId:itemIndex"` بدل `order` رقمي
/// لتفادي أي تصادم مع مفاتيح شاشة الصباح/المساء المنفصلة تماماً.
class AzkarLibraryProgressNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  static String keyFor(int categoryId, int itemIndex) => '$categoryId:$itemIndex';

  int remainingFor(String key, int total) => state[key] ?? total;

  void tap(String key, int total) {
    final current = remainingFor(key, total);
    if (current <= 0) return;
    HapticFeedback.lightImpact();
    state = {...state, key: current - 1};
  }

  void resetAll() => state = const {};
}

final azkarLibraryProgressProvider =
    NotifierProvider<AzkarLibraryProgressNotifier, Map<String, int>>(AzkarLibraryProgressNotifier.new);
