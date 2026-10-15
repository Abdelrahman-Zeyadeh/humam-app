import 'package:flutter/material.dart';

/// ألوان مشتركة بين مكوّنات نافذة "مشاركة الآية" (الشيت الرئيسي، المعاينات،
/// ونوافذ الاختيار) — مجمّعة هنا حتى تبقى متطابقة تماماً أينما استُخدمت بدل
/// تكرار قيم الألوان الصريحة (Hex) في كل ملف على حِدة.
class AyahShareColors {
  AyahShareColors._();

  static const primaryGreen = Color(0xFF437A4D);
  static const parchmentBg = Color(0xFFF9F6EE);
  static const parchmentCard = Color(0xFFFAF7F0);
  static const borderTan = Color(0xFFE2D8C3);
  static const goldMushaf = Color(0xFFC5A059);
}

/// أنماط وخلفيات بطاقة المصحف الشريف لمشاركة الآيات والصفحات
enum MushafShareBgTheme {
  parchment(
    label: 'مصحف أصيل',
    iconColor: Color(0xFFFBF8F1),
  ),
  amber(
    label: 'عنبر فذكّر',
    iconColor: Color(0xFF381F0D),
  ),
  royalNight(
    label: 'ليل مذهب',
    iconColor: Color(0xFF1B1E26),
  ),
  emerald(
    label: 'زمرد إسلامي',
    iconColor: Color(0xFF0E3823),
  ),
  whiteMarble(
    label: 'رخام أبيض',
    iconColor: Color(0xFFFAFAFC),
  ),
  ottomanNavy(
    label: 'كحلي فاخر',
    iconColor: Color(0xFF1C2541),
  );

  const MushafShareBgTheme({required this.label, required this.iconColor});
  final String label;
  final Color iconColor;

  bool get isDark => this != parchment && this != whiteMarble;

  Color get textColor => isDark ? const Color(0xFFFFF9EE) : const Color(0xFF1E1912);

  Color get frameBorderColor {
    switch (this) {
      case parchment:
        return const Color(0xFFC5A059);
      case amber:
        return const Color(0xFFE2C974);
      case royalNight:
        return const Color(0xFFD4AF37);
      case emerald:
        return const Color(0xFFE5C07B);
      case whiteMarble:
        return const Color(0xFFB59358);
      case ottomanNavy:
        return const Color(0xFFDFB15B);
    }
  }

  Color get bannerBgColor {
    switch (this) {
      case parchment:
        return const Color(0xFFECE3D0);
      case amber:
        return const Color(0x33D4AF37);
      case royalNight:
        return const Color(0x22D4AF37);
      case emerald:
        return const Color(0x22E5C07B);
      case whiteMarble:
        return const Color(0xFFF0EEE9);
      case ottomanNavy:
        return const Color(0x22DFB15B);
    }
  }

  Color get bannerBorderColor {
    switch (this) {
      case parchment:
        return const Color(0xFF8D7344);
      case amber:
        return const Color(0x88E2C974);
      case royalNight:
        return const Color(0x66D4AF37);
      case emerald:
        return const Color(0x66E5C07B);
      case whiteMarble:
        return const Color(0xFFB59358);
      case ottomanNavy:
        return const Color(0x66DFB15B);
    }
  }

  Color get bannerTextColor {
    return isDark ? const Color(0xFFFFDF88) : const Color(0xFF2C2416);
  }

  Color get endCircleColor {
    return isDark ? frameBorderColor : const Color(0xFF8D7344);
  }

  Decoration get backgroundDecoration {
    switch (this) {
      case parchment:
        return const BoxDecoration(color: Color(0xFFFBF8F1));
      case amber:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
          ),
        );
      case royalNight:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1115), Color(0xFF1B1E26), Color(0xFF0B0D10)],
          ),
        );
      case emerald:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061A10), Color(0xFF0D3320), Color(0xFF05140C)],
          ),
        );
      case whiteMarble:
        return const BoxDecoration(color: Color(0xFFFAFAFC));
      case ottomanNavy:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1128), Color(0xFF1C2541), Color(0xFF070B19)],
          ),
        );
    }
  }
}
