import 'package:flutter/material.dart';

import 'app_colors.dart';

/// لوحة ألوان صفحة المصحف: خلفية/نص لكل من الوضعين الفاتح والداكن.
class MushafColorPalette {
  const MushafColorPalette({
    required this.id,
    required this.label,
    required this.bgLight,
    required this.fgLight,
    required this.bgDark,
    required this.fgDark,
  });

  final String id;
  final String label;
  final Color bgLight;
  final Color fgLight;
  final Color bgDark;
  final Color fgDark;

  Color bg(bool isDark) => isDark ? bgDark : bgLight;
  Color fg(bool isDark) => isDark ? fgDark : fgLight;
}

/// لون خط موحَّد للوضع الداكن **بكل الباقات الثابتة الثمانية** — بطلب صاحب
/// المشروع "لو يكون الوضع الليلي مفعّل خلي خط المصحف لونه واضح لكل
/// الثيمات... توحيد لون واحد". قبلاً كل باقة تلوّن `fgDark` بنفسها (أخضر
/// فاتح للعشبية، وردي للعنّابية...) فيبان النص "مختلف الوضوح" حسب الباقة
/// المختارة؛ أبيض ثابت أوضح خيار عالخلفيات الداكنة كلها بلا استثناء.
const Color kMushafNightFg = Colors.white;

/// اللوحات الثابتة المتاحة (٤ ألوان هادئة للمصحف)
const List<MushafColorPalette> kMushafPalettes = [
  MushafColorPalette(
    id: 'cream',
    label: 'أبيض دافئ',
    bgLight: AppColors.cream,
    fgLight: AppColors.ink,
    bgDark: AppColors.surfaceDark,
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'sage',
    label: 'أخضر هادئ',
    bgLight: Color(0xFFEFF3EA),
    fgLight: Color(0xFF2A3B2E),
    bgDark: Color(0xFF1B2420),
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'sepia',
    label: 'ورق المصحف العاجي الفاخر',
    bgLight: Color(0xFFFAF3E3),
    fgLight: Color(0xFF261D12),
    bgDark: Color(0xFF1E170E),
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'amoled',
    label: 'الأسود المطلق',
    bgLight: Color(0xFFF7F8F9),
    fgLight: Color(0xFF111215),
    bgDark: Color(0xFF000000),
    fgDark: Color(0xFFFFFFFF),
  ),
];

MushafColorPalette mushafPaletteById(String id, {String? accentId}) {
  return switch (id) {
    'cream' || 'default' || 'theme' => kMushafPalettes[0],
    'sage' || 'mint' => kMushafPalettes[1],
    'sepia' || 'sand' || 'rose' => kMushafPalettes[2],
    'amoled' || 'slate' || 'charcoal' => kMushafPalettes[3],
    _ => kMushafPalettes.firstWhere(
        (p) => p.id == id,
        orElse: () => kMushafPalettes.first,
      ),
  };
}
