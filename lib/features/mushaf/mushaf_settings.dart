import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';

const _kThemeModeKey = 'app_theme_mode'; // 'system' | 'light' | 'dark'

/// وضع الثيم العام للتطبيق — مُحفَّظ بـ`SharedPreferences` (إعداد بسيط،
/// لا بيانات مستخدم، فيبقى هون حسب القرار المعماري #٦ بتصميم-النظام.md
/// بدل `user.db`). كان بلا حفظ إطلاقاً (TODO سابق)؛ انسدّت الفجوة
/// ٢٠٢٦-٠٨-١٩ مع هجرة بيانات المستخدم لـdrift.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_kThemeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    state = next;
    ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, next.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// درجات حجم خط المصحف. التخطيط بخط QCF يملأ عرض السطر دايماً (`FittedBox`
/// بـ `fitWidth`) فلا معنى لرقم بكسل مباشر؛ نتحكم بالحجم عبر الهامش الجانبي
/// (هامش أقل ⇐ عرض أوسع للسطر ⇐ خط أكبر بصرياً).
enum MushafTextSize {
  small(horizontalPadding: 28),
  medium(horizontalPadding: 12),
  large(horizontalPadding: 2);

  const MushafTextSize({required this.horizontalPadding});
  final double horizontalPadding;

  MushafTextSize get next => switch (this) {
        MushafTextSize.small => MushafTextSize.medium,
        MushafTextSize.medium => MushafTextSize.large,
        MushafTextSize.large => MushafTextSize.small,
      };
}

class MushafTextSizeNotifier extends Notifier<MushafTextSize> {
  @override
  MushafTextSize build() => MushafTextSize.medium;

  void cycle() => state = state.next;
}

final mushafTextSizeProvider =
    NotifierProvider<MushafTextSizeNotifier, MushafTextSize>(MushafTextSizeNotifier.new);

/// وضع الحفظ: يخفي كل سطور الآيات خلف غطاء، وتُكشَف آية واحدة بالضغط
/// عليها (نفس الغليفات الحقيقية المرسومة أصلاً — لا نص بديل ولا تخمين).
/// حالة جلسة فقط، لا تُحفظ بين تشغيلات التطبيق.
class MemorizationModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    if (!state) ref.read(revealedAyahsProvider.notifier).hideAll();
  }
}

final memorizationModeProvider = NotifierProvider<MemorizationModeNotifier, bool>(
  MemorizationModeNotifier.new,
);

/// معرّفات الآيات المكشوفة حالياً بوضع الحفظ (تُصفَّر عند إيقاف الوضع أو
/// عند الضغط على "إخفاء الكل").
class RevealedAyahsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void reveal(int ayahId) => state = {...state, ayahId};

  void hideAll() => state = const {};
}

final revealedAyahsProvider = NotifierProvider<RevealedAyahsNotifier, Set<int>>(
  RevealedAyahsNotifier.new,
);
