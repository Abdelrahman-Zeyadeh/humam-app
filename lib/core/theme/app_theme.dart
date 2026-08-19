import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ثيم هُمَام: `light()` و`dark()` بنفس الهوية البصرية.
///
/// خط الواجهة Cairo مضمّن كـ asset (`assets/fonts/Cairo-Variable.ttf`،
/// خط متغيّر الوزن SIL OFL 1.1 من `google/fonts`) — لا جلب شبكي عند
/// الإقلاع بعد الآن (كان عبر حزمة `google_fonts` سابقاً، فجوة #10
/// بتصميم-النظام.md، انسدّت ٢٠٢٦-٠٨-١٩).
const String _kCairoFamily = 'Cairo';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navyDeep,
        surface: AppColors.cream,
        onSurface: AppColors.ink,
        error: Color(0xFFB3261E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: _kCairoFamily,
    );

    return base.copyWith(
      // كانت خلفية كحلية غامقة/نص أبيض بكل الشاشات الثانوية (الصلاة،
      // الأذكار، الأحاديث، الختمة، قيام الليل) — أثقل من الهوية المطلوبة.
      // خلفية فاتحة (نفس Cream العامة) ونص/أيقونات كحلية بدلها، بلا لمس
      // الوضع الليلي (`AppTheme.dark()` أسفل، بلا تغيير).
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.navy),
        titleTextStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.inkSoft,
        selectedLabelStyle: TextStyle(fontFamily: _kCairoFamily, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: _kCairoFamily, fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.navyDeep,
        secondary: AppColors.gold,
        onSecondary: AppColors.navyDeep,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.inkOnDark,
        error: Color(0xFFCF6679),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: AppColors.navyDeep,
      fontFamily: _kCairoFamily,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.inkOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.inkOnDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.inkSoftOnDark,
        selectedLabelStyle: const TextStyle(fontFamily: _kCairoFamily, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: _kCairoFamily, fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lineDark, space: 1),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lineDark),
        ),
      ),
    );
  }
}
