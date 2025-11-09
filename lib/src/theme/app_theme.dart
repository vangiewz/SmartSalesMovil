import 'package:flutter/material.dart';

class AppColors {
  static const Color brandPrimary = Color(0xFFB832FA);
  static const Color brandAccent = Color(0xFFFF4DD2);
  static const Color brandPrimaryDark = Color(0xFF7B1FA2);
  static const Color brandAccentDark = Color(0xFFE91E63);
  static const Color bgBase = Color(0xFFFFF7FF);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D0A3A);
  static const Color textSecondary = Color(0xFF6C5580);
  static const Color success = Color(0xFF24C38B);
  static const Color warning = Color(0xFFF6C445);
  static const Color danger = Color(0xFFFF4E6E);
}

class AppMetrics {
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double elevationCard = 8.0;
  static const double elevationButton = 4.0;
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.bgBase,
      primaryColor: AppColors.brandPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
      ),
      cardColor: AppColors.bgCard,
      // cardTheme removed for SDK compatibility; use cardColor and customize Card widgets locally when needed
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
          ),
        ),
      ),
    );
  }
}
