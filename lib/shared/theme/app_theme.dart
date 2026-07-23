import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Duraciones de animacion del sistema.
abstract final class AppDurations {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const pulse = Duration(milliseconds: 1600); // punto "en curso"
}

/// Bordes estandar.
abstract final class AppBorders {
  static const side = BorderSide(color: AppColors.border);
  static const sideStrong = BorderSide(color: AppColors.borderStrong);
  static const sideActive = BorderSide(color: AppColors.borderActive);
}

/// ThemeData Material 3 del sistema. Toda la app consume este tema;
/// los widgets del design system solo leen tokens (AppColors, AppTextStyles...).
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.success,
      onSecondary: AppColors.onAccent,
      error: AppColors.danger,
      onError: AppColors.onAccent,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainer,
      surfaceContainer: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.sans,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.headlineLarge,
        headlineSmall: AppTextStyles.headline,
        titleMedium: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySecondary,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.headline,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: AppBorders.side,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size(64, 52),
          textStyle: const TextStyle(
              fontFamily: AppTextStyles.sans, fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.control, borderSide: AppBorders.side),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.control, borderSide: AppBorders.sideActive),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.control,
            borderSide: BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.control,
            borderSide: BorderSide(color: AppColors.danger)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        contentTextStyle: AppTextStyles.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardLarge, side: AppBorders.side),
      ),
    );
  }
}
