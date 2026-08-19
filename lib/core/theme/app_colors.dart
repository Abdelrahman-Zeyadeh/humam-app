import 'package:flutter/material.dart';

/// هوية هُمَام البصرية المعتمدة. لا تُغيَّر هذه القيم بلا قرار واعٍ —
/// راجع "تصميم-النظام.md" و"تصميم هُمَام الأولي" (الكانفاس المعتمد) قبل أي تعديل.
abstract final class AppColors {
  // الألوان الأساسية
  static const navy = Color(0xFF0B2545);
  static const navyDeep = Color(0xFF071A33);
  static const blue = Color(0xFF164B7A);
  static const gold = Color(0xFFC9A24B);
  static const goldSoft = Color(0xFFE7D2A0);

  // الخلفيات
  static const paper = Color(0xFFF6EEDA); // خلفية صفحة المصحف الورقية
  static const cream = Color(0xFFFBF6EC); // خلفية شاشات التطبيق العامة

  // النصوص
  static const ink = Color(0xFF1C2B3A);
  static const inkSoft = Color(0xFF5B6B7C);

  // لمسات محدودة
  static const teal = Color(0xFF2F8F82);
  static const purple = Color(0xFF6E5B95);

  static const line = Color(0x1A0B2545); // navy بشفافية 10%

  // الوضع الليلي — دافئة لا سوداء صريحة، بنفس الهوية
  static const paperDark = Color(0xFF221D16); // خلفية صفحة المصحف الليلية
  static const surfaceDark = Color(0xFF0F1E33); // أفتح قليلاً من navyDeep لبطاقات/أشرطة
  static const inkOnDark = Color(0xFFEDE6D8);
  static const inkSoftOnDark = Color(0xFFAFA391);
  static const lineDark = Color(0x22EDE6D8); // inkOnDark بشفافية 13%
}
