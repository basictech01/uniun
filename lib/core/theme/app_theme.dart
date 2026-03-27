import 'package:flutter/material.dart';

/// UNIUN design system colors — sourced directly from the design HTML.
abstract class AppColors {
  static const primary = Color(0xFF005AB6);
  static const primaryContainer = Color(0xFF1672DF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFFEFCFF);

  static const secondary = Color(0xFF475F89);
  static const secondaryContainer = Color(0xFFB8CFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF415882);

  static const tertiary = Color(0xFF934700);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFB85A00);
  static const onTertiaryContainer = Color(0xFFFFFBFF);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF414753);

  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8F9FB);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceContainerHighest = Color(0xFFE1E2E4);

  static const outline = Color(0xFF727785);
  static const outlineVariant = Color(0xFFC1C6D5);

  static const inverseSurface = Color(0xFF2E3132);
  static const inverseOnSurface = Color(0xFFF0F1F3);
  static const inversePrimary = Color(0xFFABC7FF);

  // Gradient used on primary action buttons
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.onTertiaryContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.inversePrimary,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.outline),
        ),
      );
}
