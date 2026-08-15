import 'package:flutter/material.dart';
import 'momo_design_system.dart';

/// Momo AI Theme Configuration
class MomoTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: MomoColors.primaryBlue,
        secondary: MomoColors.primaryBlueLight,
        surface: MomoColors.backgroundLight,
        surfaceContainerHighest: MomoColors.surfaceWhite,
        error: MomoColors.error,
        onPrimary: MomoColors.textWhite,
        onSurface: MomoColors.textBlack,
      ),

      // Scaffold
      scaffoldBackgroundColor: MomoColors.backgroundLight,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: MomoColors.backgroundLight,
        foregroundColor: MomoColors.textBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: MomoTypography.headlineMedium,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: MomoTypography.displayLarge,
        displayMedium: MomoTypography.displayMedium,
        displaySmall: MomoTypography.displaySmall,
        headlineLarge: MomoTypography.headlineLarge,
        headlineMedium: MomoTypography.headlineMedium,
        headlineSmall: MomoTypography.headlineSmall,
        bodyLarge: MomoTypography.bodyLarge,
        bodyMedium: MomoTypography.bodyMedium,
        bodySmall: MomoTypography.bodySmall,
        labelLarge: MomoTypography.labelLarge,
        labelMedium: MomoTypography.labelMedium,
        labelSmall: MomoTypography.labelSmall,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MomoColors.primaryBlue,
          foregroundColor: MomoColors.textWhite,
          padding: const EdgeInsets.symmetric(
            horizontal: MomoSpacing.xl,
            vertical: MomoSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MomoRadius.lg),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MomoColors.primaryBlue,
          side: const BorderSide(
            color: MomoColors.primaryBlue,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MomoSpacing.xl,
            vertical: MomoSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MomoRadius.lg),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MomoColors.surfaceGlass,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MomoSpacing.lg,
          vertical: MomoSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MomoRadius.lg),
          borderSide: const BorderSide(
            color: MomoColors.primaryBlueLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MomoRadius.lg),
          borderSide: BorderSide(
            color: MomoColors.primaryBlueLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MomoRadius.lg),
          borderSide: const BorderSide(
            color: MomoColors.primaryBlue,
            width: 2,
          ),
        ),
        hintStyle: MomoTypography.bodyMedium.copyWith(
          color: MomoColors.textGrayLight,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: MomoColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MomoRadius.lg),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: MomoColors.textBlack,
        size: 24,
      ),
    );
  }
}
