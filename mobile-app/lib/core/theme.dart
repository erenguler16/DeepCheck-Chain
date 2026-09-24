import 'package:flutter/material.dart';
import 'constants.dart';

// DEEPCHECK-CHAIN Tema

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.neonBlue,
        error: AppColors.neonRed,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontMono,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: AppColors.gold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDeep,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontMono,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontMono,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
