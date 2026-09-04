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

const kDefaultAppAccentColor = AppAccentColor(
  id: 'emerald',
  label: 'الزمردي الإسلامي الملكي',
  color: Color(0xFF1B8A72),
  onColor: Colors.white,
  primaryLight: Color(0xFF135D48),
  surfaceLight: Color(0xFFF2F8F5),
  primaryDark: Color(0xFF0D2E24),
);

const List<AppAccentColor> kAppAccentColors = [
  kDefaultAppAccentColor,
  AppAccentColor(
    id: 'gold',
    label: 'الكحلي والذهبي',
    color: AppColors.gold,
    onColor: AppColors.navyDeep,
    primaryLight: AppColors.navy,
    surfaceLight: AppColors.cream,
    primaryDark: AppColors.navyDeep,
  ),
  AppAccentColor(
    id: 'amber',
    label: 'العنبري الدافئ',
    color: Color(0xFFD48B28),
    onColor: Colors.white,
    primaryLight: Color(0xFF704310),
    surfaceLight: Color(0xFFFAF6EE),
    primaryDark: Color(0xFF2E1B06),
  ),
  AppAccentColor(
    id: 'parchment',
    label: 'الصحراوي التراثي',
    color: Color(0xFF8D6E63),
    onColor: Colors.white,
    primaryLight: Color(0xFF533E2D),
    surfaceLight: Color(0xFFFBF8F2),
    primaryDark: Color(0xFF261C14),
  ),
  AppAccentColor(
    id: 'blue',
    label: 'الأزرق النيلي',
    color: Color(0xFF2C5E8A),
    onColor: Colors.white,
    primaryLight: Color(0xFF15406A),
    surfaceLight: Color(0xFFF2F6FA),
    primaryDark: Color(0xFF0F263E),
  ),
  AppAccentColor(
    id: 'teal',
    label: 'الفيروزي الهادئ',
    color: AppColors.teal,
    onColor: Colors.white,
    primaryLight: Color(0xFF005B52),
    surfaceLight: Color(0xFFF0F7F6),
    primaryDark: Color(0xFF042824),
  ),
  AppAccentColor(
    id: 'purple',
    label: 'الأرجواني الملكي',
    color: AppColors.purple,
    onColor: Colors.white,
    primaryLight: Color(0xFF4A255A),
    surfaceLight: Color(0xFFF8F2FA),
    primaryDark: Color(0xFF22112A),
  ),
  AppAccentColor(
    // بطلب صاحب المشروع "الألوان مش منطقية" — `color` (لون معاينة الباقة
    // بشاشة الإعدادات) كان مضبوطاً غلطاً بنفس قيمة `AppColors.gold`
    // (0xFFC9A24B، لون ذهبي) بدل لون فحمي/رمادي غامق يطابق الاسم
    // "الفحمي الهادئ" فعلياً — أُصلح هون لدائرة معاينة رمادية-فحمية حقيقية.
    id: 'obsidian',
    label: 'الفحمي الهادئ',
    color: Color(0xFF3A3F46),
    onColor: Colors.white,
    primaryLight: Color(0xFF212529),
    surfaceLight: Color(0xFFF4F5F7),
    primaryDark: Color(0xFF101216),
  ),
];

const String kDefaultAccentColorId = 'gold';

AppAccentColor appAccentColorById(String id) => kAppAccentColors.firstWhere(
  (c) => c.id == id,
  orElse: () => kAppAccentColors.first,
);
