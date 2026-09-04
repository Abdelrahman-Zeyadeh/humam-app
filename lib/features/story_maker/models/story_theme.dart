import 'package:flutter/material.dart';

class StoryTheme {
  final String id;
  final String name;
  final List<Color> backgroundColors;
  final Alignment beginAlignment;
  final Alignment endAlignment;
  final Color textColor;
  final Color accentColor;
  final Color frameColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;
  final bool isDark;

  const StoryTheme({
    required this.id,
    required this.name,
    required this.backgroundColors,
    this.beginAlignment = Alignment.topCenter,
    this.endAlignment = Alignment.bottomCenter,
    required this.textColor,
    required this.accentColor,
    required this.frameColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    this.isDark = true,
  });

  static const List<StoryTheme> presets = [
    StoryTheme(
      id: 'royal_navy',
      name: 'كحلي ملكي',
      backgroundColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      textColor: Colors.white,
      accentColor: Color(0xFFD4AF37),
      frameColor: Color(0x33D4AF37),
      badgeBackgroundColor: Color(0x33000000),
      badgeTextColor: Color(0xFFFFE082),
      isDark: true,
    ),
    StoryTheme(
      id: 'emerald',
      name: 'زمردي قرآني',
      backgroundColors: [Color(0xFF062A1A), Color(0xFF0B3B24), Color(0xFF144D31)],
      textColor: Color(0xFFF1F8F4),
      accentColor: Color(0xFF81C784),
      frameColor: Color(0x3381C784),
      badgeBackgroundColor: Color(0x26000000),
      badgeTextColor: Color(0xFFA5D6A7),
      isDark: true,
    ),
    StoryTheme(
      id: 'kaaba_gold',
      name: 'كسوة الكعبة',
      backgroundColors: [Color(0xFF0A0A0A), Color(0xFF14120B), Color(0xFF241E0F)],
      textColor: Color(0xFFFFF8E7),
      accentColor: Color(0xFFFFD700),
      frameColor: Color(0x4DFFD700),
      badgeBackgroundColor: Color(0x40000000),
      badgeTextColor: Color(0xFFFFE082),
      isDark: true,
    ),
    StoryTheme(
      id: 'parchment',
      name: 'مخطوطة عثمانية',
      backgroundColors: [Color(0xFFFBF8F1), Color(0xFFF3EDE0), Color(0xFFE8DECA)],
      textColor: Color(0xFF2C2416),
      accentColor: Color(0xFF8D6E63),
      frameColor: Color(0x338D6E63),
      badgeBackgroundColor: Color(0x1A000000),
      badgeTextColor: Color(0xFF5D4037),
      isDark: false,
    ),
    StoryTheme(
      id: 'midnight_black',
      name: 'أسود لؤلؤي',
      backgroundColors: [Color(0xFF111111), Color(0xFF1C1C1C), Color(0xFF282828)],
      textColor: Color(0xFFEDEDED),
      accentColor: Color(0xFFE5A93C),
      frameColor: Color(0x26E5A93C),
      badgeBackgroundColor: Color(0x33FFFFFF),
      badgeTextColor: Color(0xFFFFD54F),
      isDark: true,
    ),
    StoryTheme(
      id: 'royal_purple',
      name: 'أرجواني ملكي',
      backgroundColors: [Color(0xFF1B0B2E), Color(0xFF2C164A), Color(0xFF3F2068)],
      textColor: Color(0xFFF8F0FF),
      accentColor: Color(0xFFE1BEE7),
      frameColor: Color(0x33E1BEE7),
      badgeBackgroundColor: Color(0x33000000),
      badgeTextColor: Color(0xFFF3E5F5),
      isDark: true,
    ),
    StoryTheme(
      id: 'golden_dawn',
      name: 'شفق ذهبي',
      backgroundColors: [Color(0xFF2C1914), Color(0xFF4A2511), Color(0xFF6B3A19)],
      textColor: Color(0xFFFFF8E7),
      accentColor: Color(0xFFFFD54F),
      frameColor: Color(0x33FFD54F),
      badgeBackgroundColor: Color(0x33000000),
      badgeTextColor: Color(0xFFFFE082),
      isDark: true,
    ),
    StoryTheme(
      id: 'ocean_teal',
      name: 'أزرق تركوازي',
      backgroundColors: [Color(0xFF04202C), Color(0xFF0C3B4E), Color(0xFF165B72)],
      textColor: Color(0xFFE0F7FA),
      accentColor: Color(0xFF80DEEA),
      frameColor: Color(0x3380DEEA),
      badgeBackgroundColor: Color(0x33000000),
      badgeTextColor: Color(0xFFB2EBF2),
      isDark: true,
    ),
    StoryTheme(
      id: 'pure_minimal',
      name: 'أبيض ناصع',
      backgroundColors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA), Color(0xFFF1F3F5)],
      textColor: Color(0xFF1A1A1A),
      accentColor: Color(0xFF00796B),
      frameColor: Color(0x2600796B),
      badgeBackgroundColor: Color(0x14000000),
      badgeTextColor: Color(0xFF004D40),
      isDark: false,
    ),
  ];
}
