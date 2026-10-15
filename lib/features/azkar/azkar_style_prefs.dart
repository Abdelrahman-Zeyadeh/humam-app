import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart' show sharedPreferencesProvider;

/// أنماط عرض الأذكار المتاحة للمستخدم
enum AzkarViewStyle {
  /// الشكل الحديث (بطاقات تفاعلية مطابقة للتصميم المعتمد بالصورة)
  modern('الشكل الحديث (بطاقات تفاعلية)'),

  /// الشكل الكلاسيكي المدمج
  classic('الشكل الكلاسيكي');

  const AzkarViewStyle(this.label);
  final String label;

  static AzkarViewStyle fromString(String? key) {
    if (key == 'classic') return AzkarViewStyle.classic;
    return AzkarViewStyle.modern; // الافتراضي هو الحديث كما بالصورة
  }
}

const _kAzkarViewStyleKey = 'azkar_view_style_selection';

class AzkarViewStyleNotifier extends Notifier<AzkarViewStyle> {
  @override
  AzkarViewStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_kAzkarViewStyleKey);
    return AzkarViewStyle.fromString(saved);
  }

  Future<void> setStyle(AzkarViewStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kAzkarViewStyleKey, style.name);
  }

  Future<void> toggle() async {
    final next = state == AzkarViewStyle.modern
        ? AzkarViewStyle.classic
        : AzkarViewStyle.modern;
    await setStyle(next);
  }
}

final azkarViewStyleProvider =
    NotifierProvider<AzkarViewStyleNotifier, AzkarViewStyle>(
      AzkarViewStyleNotifier.new,
    );
