import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.itemBackground,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.slate100,
      cardColor: AppColors.itemBackground,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.slate900),
        bodyLarge: TextStyle(color: AppColors.slate900),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.slate100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.borderDark,
      cardColor: AppColors.surfaceDark,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.slate100),
        bodyLarge: TextStyle(color: AppColors.slate100),
      ),
    );
  }
}
