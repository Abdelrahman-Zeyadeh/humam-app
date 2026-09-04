import 'package:flutter/material.dart';

import 'app_accent_colors.dart';
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

/// اللوحات الثابتة المتاحة
const List<MushafColorPalette> kMushafPalettes = [
  MushafColorPalette(
    id: 'default',
    label: 'متوافق مع ثيم التطبيق (تلقائي)',
    bgLight: AppColors.paper,
    fgLight: AppColors.ink,
    bgDark: AppColors.paperDark,
    fgDark: kMushafNightFg,
  ),
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
    id: 'slate',
    label: 'أزرق ليلي',
    bgLight: Color(0xFFEAEFF5),
    fgLight: AppColors.navy,
    bgDark: AppColors.navyDeep,
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'sand',
    label: 'رملي',
    bgLight: AppColors.goldSoft,
    fgLight: Color(0xFF4A3B1E),
    bgDark: Color(0xFF2A2214),
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'rose',
    label: 'عنّابي دافئ',
    bgLight: Color(0xFFF7ECEC),
    fgLight: Color(0xFF4A1620),
    bgDark: Color(0xFF241014),
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'mint',
    label: 'نعناعي فاتح',
    bgLight: Color(0xFFE9F6F1),
    fgLight: Color(0xFF0D3B2E),
    bgDark: Color(0xFF10231D),
    fgDark: kMushafNightFg,
  ),
  MushafColorPalette(
    id: 'charcoal',
    label: 'رمادي فحمي',
    bgLight: Color(0xFFEDEDF0),
    fgLight: Color(0xFF202126),
    bgDark: Color(0xFF16171B),
    fgDark: kMushafNightFg,
  ),
];

MushafColorPalette mushafPaletteById(String id, {String? accentId}) {
  if (id == 'default' || id == 'theme') {
    final acc = appAccentColorById(accentId ?? kDefaultAccentColorId);
    // **بطلب صريح: خط المصحف بالوضع الليلي يبقى أبيض ثابت دايماً** بغضّ
    // النظر عن لون التمييز المختار — كان كل باقة توليّن `fgDark` بنفسها
    // (أخضر للزمردي، كريمي دافئ للعنبري...) فيبان الخط "بيتغيّر" مع كل
    // تبديل لون. الخلفية (`bgDark`) بقيت متمايزة عمداً (تعطي أجواء الثيم
    // بلا المساس بوضوح/ثبات النص).
    const fgDarkFixed = Colors.white;
    return switch (acc.id) {
      'emerald' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (زمردي)',
        bgLight: Color(0xFFF2F7F4),
        fgLight: Color(0xFF13382C),
        bgDark: Color(0xFF0F1A16),
        fgDark: fgDarkFixed,
      ),
      'amber' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (عنبري)',
        bgLight: Color(0xFFFAF6EE),
        fgLight: Color(0xFF38230B),
        bgDark: Color(0xFF1C140A),
        fgDark: fgDarkFixed,
      ),
      'parchment' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (صحراوي)',
        bgLight: Color(0xFFFBF8F2),
        fgLight: Color(0xFF36281E),
        bgDark: Color(0xFF1E1712),
        fgDark: fgDarkFixed,
      ),
      'blue' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (نيلي)',
        bgLight: Color(0xFFF2F6FA),
        fgLight: Color(0xFF102842),
        bgDark: Color(0xFF0D1824),
        fgDark: fgDarkFixed,
      ),
      'teal' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (فيروزي)',
        bgLight: Color(0xFFF0F7F6),
        fgLight: Color(0xFF0D3330),
        bgDark: Color(0xFF0C1A19),
        fgDark: fgDarkFixed,
      ),
      'purple' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (أرجواني)',
        bgLight: Color(0xFFF8F2FA),
        fgLight: Color(0xFF331640),
        bgDark: Color(0xFF1A0E21),
        fgDark: fgDarkFixed,
      ),
      'obsidian' => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (فحمي)',
        bgLight: Color(0xFFF4F5F7),
        fgLight: Color(0xFF1A1D20),
        bgDark: Color(0xFF121417),
        fgDark: fgDarkFixed,
      ),
      _ => const MushafColorPalette(
        id: 'theme',
        label: 'متوافق مع الثيم (كحلي وذهبي)',
        bgLight: AppColors.paper,
        fgLight: AppColors.ink,
        bgDark: AppColors.paperDark,
        fgDark: fgDarkFixed,
      ),
    };
  }

  return kMushafPalettes.firstWhere(
    (p) => p.id == id,
    orElse: () => kMushafPalettes.first,
  );
}
