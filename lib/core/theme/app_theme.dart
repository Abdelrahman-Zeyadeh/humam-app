import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ثيم هُمَام: `light()` و`dark()` بنفس الهوية البصرية.
///
/// TODO(أداء): يستخدم GoogleFonts.cairoTextTheme حالياً فيجلب الخط من الشبكة
/// عند أول إقلاع. يجب استبداله بخط Cairo مضمّن كـ asset قبل النشر — هذا مطلوب
/// صراحة في تصميم-النظام.md (فجوة #10) ولا يجوز تأجيله لآخر مرحلة.
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
      fontFamily: GoogleFonts.cairo().fontFamily,
      textTheme: GoogleFonts.cairoTextTheme(),
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.inkSoft,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
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
      fontFamily: GoogleFonts.cairo().fontFamily,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.inkOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.inkOnDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.inkSoftOnDark,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
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
