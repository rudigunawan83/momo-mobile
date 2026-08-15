import 'package:flutter/material.dart';

/// Momo AI Design System - Colors
class MomoColors {
  MomoColors._(); // Private constructor

  // Brand Colors
  static const Color primaryBlue = Color(0xFF1683FF);
  static const Color primaryBlueDark = Color(0xFF0056CC);
  static const Color primaryBlueLight = Color(0xFF4FA3FF);

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF7F5EF); // Warm cream
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color.fromARGB(230, 255, 255, 255); // Glassmorphism white

  // Text Colors
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color textGrayLight = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // Gradient & Overlay
  static const Color glassOverlay = Color.fromARGB(20, 255, 255, 255);
  static const Color shadowColor = Color.fromARGB(30, 0, 0, 0);

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color thinking = Color(0xFF1683FF);
  static const Color speaking = Color(0xFFFFC107);

  // Special
  static const Color momoGlow = Color(0xFF1683FF); // Blue glow for Momo
}

/// Momo AI Design System - Typography
class MomoTypography {
  MomoTypography._();

  // Display/Heading styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: MomoColors.textBlack,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: MomoColors.textBlack,
    letterSpacing: -0.3,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: MomoColors.textBlack,
  );

  // Heading styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: MomoColors.textBlack,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MomoColors.textBlack,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MomoColors.textBlack,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: MomoColors.textBlack,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MomoColors.textBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MomoColors.textGray,
    height: 1.4,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: MomoColors.textBlack,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MomoColors.textBlack,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: MomoColors.textGray,
    letterSpacing: 0.1,
  );
}

/// Momo AI Design System - Spacing
class MomoSpacing {
  MomoSpacing._();

  // Base spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Common padding/margin
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
}

/// Momo AI Design System - Border Radius
class MomoRadius {
  MomoRadius._();

  // Radius values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 32.0;
  static const double pill = 50.0;
  static const double circle = 1000.0;
}

/// Momo AI Design System - Shadows
class MomoShadows {
  MomoShadows._();

  // Light shadow for subtle depth
  static const BoxShadow light = BoxShadow(
    color: MomoColors.shadowColor,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  // Medium shadow
  static const BoxShadow medium = BoxShadow(
    color: MomoColors.shadowColor,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // Large shadow for elevated components
  static const BoxShadow large = BoxShadow(
    color: MomoColors.shadowColor,
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  // Glow shadow for robot/special elements
  static const BoxShadow glow = BoxShadow(
    color: Color.fromARGB(80, 22, 131, 255),
    blurRadius: 20,
    offset: Offset(0, 0),
    spreadRadius: 2,
  );

  static const List<BoxShadow> lightList = [light];
  static const List<BoxShadow> mediumList = [medium];
  static const List<BoxShadow> largeList = [large];
  static const List<BoxShadow> glowList = [glow];
}

/// Momo AI Design System - Glassmorphism
class MomoGlass {
  MomoGlass._();

  // Standard glass effect parameters
  static const double standardBlur = 10.0;
  static const double standardOpacity = 0.85;
  static const double standardBorderOpacity = 0.2;

  // Light glass
  static const double lightBlur = 5.0;
  static const double lightOpacity = 0.9;

  // Strong glass
  static const double strongBlur = 20.0;
  static const double strongOpacity = 0.7;
}
