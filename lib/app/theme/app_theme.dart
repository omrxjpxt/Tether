import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccentPrimary,
        secondary: AppColors.lightAccentSecondary,
        surface: AppColors.lightSurfacePrimary,
        surfaceContainerHighest: AppColors.lightSurfaceSecondary,
        error: AppColors.destructive,
        onPrimary: AppColors.lightSurfacePrimary,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        onError: AppColors.lightSurfacePrimary,
        outline: AppColors.lightTextTertiary,
        outlineVariant: AppColors.lightBorder,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.headingLarge,
        titleLarge: AppTypography.headingSection,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.secondary,
        labelSmall: AppTypography.metadata,
      ).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      dividerColor: AppColors.lightBorder,
      splashColor: AppColors.lightAccentPrimary.withValues(alpha: 0.06),
      highlightColor: AppColors.lightAccentPrimary.withValues(alpha: 0.04),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurfacePrimary,
        elevation: 0,
        indicatorColor: AppColors.lightAccentSecondary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.metadata.copyWith(
              color: AppColors.lightAccentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return AppTypography.metadata.copyWith(
            color: AppColors.lightTextTertiary,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.lightAccentPrimary,
              size: 22,
            );
          }
          return const IconThemeData(
            color: AppColors.lightTextTertiary,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.lightAccentPrimary, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextTertiary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: AppTypography.secondary.copyWith(
          color: AppColors.lightSurfacePrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.lightAccentSecondary,
        side: const BorderSide(color: AppColors.lightBorder),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large + 4),
        ),
        titleTextStyle: AppTypography.headingSection.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccentPrimary,
        secondary: AppColors.darkAccentSecondary,
        surface: AppColors.darkSurfacePrimary,
        surfaceContainerHighest: AppColors.darkSurfaceSecondary,
        error: AppColors.destructive,
        onPrimary: AppColors.darkSurfacePrimary,
        onSecondary: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        onError: AppColors.darkSurfacePrimary,
        outline: AppColors.darkTextTertiary,
        outlineVariant: AppColors.darkBorder,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.headingLarge,
        titleLarge: AppTypography.headingSection,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.secondary,
        labelSmall: AppTypography.metadata,
      ).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      dividerColor: AppColors.darkBorder,
      splashColor: AppColors.darkAccentPrimary.withValues(alpha: 0.08),
      highlightColor: AppColors.darkAccentPrimary.withValues(alpha: 0.05),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfacePrimary,
        elevation: 0,
        indicatorColor: AppColors.darkAccentSecondary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.metadata.copyWith(
              color: AppColors.darkAccentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return AppTypography.metadata.copyWith(
            color: AppColors.darkTextTertiary,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.darkAccentPrimary,
              size: 22,
            );
          }
          return const IconThemeData(
            color: AppColors.darkTextTertiary,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.darkAccentPrimary, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkTextPrimary,
        contentTextStyle: AppTypography.secondary.copyWith(
          color: AppColors.darkBackground,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.darkAccentSecondary,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.secondary.copyWith(color: AppColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large + 4),
        ),
        titleTextStyle: AppTypography.headingSection.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}
