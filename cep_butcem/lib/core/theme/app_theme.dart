import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const primary = Color(0xFF6C4CF2); // #6C4CF2
  static const secondaryButton = Color(0xFFCFC3FF); // Giriş Yap

  // Light mode
  static const bgLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF111827);
  static const mutedLight = Color(0xFF6B7280);

  // Dark mode
  static const bgDark = Color(0xFF0B0B12);
  static const cardDark = Color(0xFF141425);
  static const textDark = Color(0xFFF3F4F6);
  static const mutedDark = Color(0xFF9CA3AF);

  // Onboarding indicators
  static const indicatorActive = Color(0xFFFF8A00);
  static const indicatorInactive = Color(0xFFFFC38A);
}

class AppTheme {
  /// LIGHT THEME
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.cardLight,
        onSurface: AppColors.textLight,

        // ✅ EKLENENLER
        background: AppColors.bgLight,
        onBackground: AppColors.textLight,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textLight,
          height: 1.35,
        ),
      ),
    );
  }

  /// DARK THEME
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.cardDark,
        onSurface: AppColors.textDark,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textDark,
          height: 1.35,
        ),
      ),
    );
  }
}
