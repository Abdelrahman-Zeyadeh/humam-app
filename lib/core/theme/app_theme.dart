import 'package:flutter/material.dart';
import 'app_accent_colors.dart';
import 'app_colors.dart';

const String _kCairoFamily = 'Cairo';

abstract final class AppTheme {
  static ThemeData light({AppAccentColor accent = kDefaultAppAccentColor}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent.primaryLight,
        onPrimary: Colors.white,
        secondary: accent.color,
        onSecondary: accent.onColor,
        surface: accent.surfaceLight,
        onSurface: AppColors.ink,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: accent.surfaceLight,
      fontFamily: _kCairoFamily,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: accent.surfaceLight,
        foregroundColor: accent.primaryLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accent.primaryLight),
        titleTextStyle: TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: accent.primaryLight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accent.color,
        unselectedItemColor: AppColors.inkSoft,
        selectedLabelStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 6,
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

  static ThemeData dark({AppAccentColor accent = kDefaultAppAccentColor}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent.color,
        onPrimary: accent.onColor,
        secondary: accent.color,
        onSecondary: accent.onColor,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.inkOnDark,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: accent.primaryDark,
      fontFamily: _kCairoFamily,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: accent.primaryDark,
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
        selectedItemColor: accent.color,
        unselectedItemColor: AppColors.inkSoftOnDark,
        selectedLabelStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _kCairoFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 6,
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
