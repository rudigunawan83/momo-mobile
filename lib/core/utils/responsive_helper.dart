import 'package:flutter/material.dart';

/// Responsive helper untuk berbagai ukuran layar
class ResponsiveHelper {
  static const double mobileMaxWidth = 600;
  static const double tabletMinWidth = 600;
  static const double tabletMaxWidth = 1000;
  static const double desktopMinWidth = 1000;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMinWidth && width < desktopMinWidth;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMinWidth;

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get safe padding untuk notch/safe area
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.fromLTRB(
      mediaQuery.padding.left,
      mediaQuery.padding.top,
      mediaQuery.padding.right,
      mediaQuery.padding.bottom,
    );
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, double) builder;
  final double minWidth;
  final double maxWidth;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
    this.minWidth = 0,
    this.maxWidth = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < minWidth || width > maxWidth) {
          return const SizedBox.shrink();
        }
        return builder(context, width);
      },
    );
  }
}
