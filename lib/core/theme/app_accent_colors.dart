import 'package:flutter/material.dart';

import 'app_colors.dart';

/// باقات ألوان وثيمات التطبيق المتكاملة (الخلفيات، الإطارات، الأزرار، التمييز)
class AppAccentColor {
  const AppAccentColor({
    required this.id,
    required this.label,
    required this.color,
    required this.onColor,
    this.primaryLight = AppColors.navy,
    this.surfaceLight = AppColors.cream,
    this.primaryDark = AppColors.navyDeep,
  });

  final String id;
  final String label;
  final Color color;
  final Color onColor;
  final Color primaryLight;
  final Color surfaceLight;
  final Color primaryDark;
}

const kEmeraldAppAccentColor = AppAccentColor(
  id: 'emerald',
  label: 'الأخضر القرآني الهادئ (نمط منار)',
  color: Color(0xFF1B8A72),
  onColor: Colors.white,
  primaryLight: Color(0xFF135B4C),
  surfaceLight: Color(0xFFF8F5EE), // أبيض على بيج (نمط منار المريح)
  primaryDark: Color(0xFF0C1F1B),
);

const kGoldAppAccentColor = AppAccentColor(
  id: 'gold',
  label: 'الذهبي العاجي (فذكر)',
  color: Color(0xFFC5A059),
  onColor: Colors.white,
  primaryLight: Color(0xFF7A5E2E),
  surfaceLight: Color(0xFFFAF7F0),
  primaryDark: Color(0xFF241C10),
);

const kDefaultAppAccentColor = kEmeraldAppAccentColor;

const List<AppAccentColor> kAppAccentColors = [
  kEmeraldAppAccentColor,
  kGoldAppAccentColor,
];

const String kDefaultAccentColorId = 'emerald';

AppAccentColor appAccentColorById(String id) => kAppAccentColors.firstWhere(
  (c) => c.id == id,
  orElse: () => kDefaultAppAccentColor,
);
