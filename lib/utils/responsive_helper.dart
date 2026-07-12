import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities for adaptive UI
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1800;

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if screen is mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  /// Check if screen is tablet (600px - 900px)
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if screen is desktop (>= 900px)
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= tabletBreakpoint;
  }

  /// Check if screen is large desktop (>= 1800px)
  static bool isLargeDesktop(BuildContext context) {
    return screenWidth(context) >= largeDesktopBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  /// Get responsive vertical padding
  static EdgeInsets responsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else {
      return const EdgeInsets.symmetric(vertical: 24);
    }
  }

  /// Get responsive spacing
  static double responsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8;
    } else if (isTablet(context)) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get responsive font size multiplier
  static double responsiveFontMultiplier(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Get number of columns for grid based on screen size
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else if (isDesktop(context) && !isLargeDesktop(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get number of columns for metrics/stats grid
  static int metricsGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else if (isDesktop(context) && !isLargeDesktop(context)) {
      return 4;
    } else {
      return 6;
    }
  }

  /// Get responsive chart height
  static double chartHeight(BuildContext context) {
    if (isMobile(context)) {
      return 200;
    } else if (isTablet(context)) {
      return 250;
    } else {
      return 300;
    }
  }

  /// Get responsive button width for shortcuts
  static double shortcutButtonWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) {
      return (width - 48) / 2; // 2 columns with padding
    } else if (isTablet(context)) {
      return 160;
    } else {
      return 180;
    }
  }

  /// Get responsive card padding
  static EdgeInsets cardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, {double baseSize = 24}) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get responsive max width for content (centered on large screens)
  static double? maxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1400;
    }
    return null;
  }

  /// Wrap content with responsive constraints
  static Widget responsiveContainer(BuildContext context, Widget child) {
    final maxWidth = maxContentWidth(context);
    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
    }
    return child;
  }

  /// Get responsive text style
  static TextStyle? responsiveTextStyle(
    BuildContext context,
    TextStyle? baseStyle, {
    double? mobileMultiplier,
    double? tabletMultiplier,
    double? desktopMultiplier,
  }) {
    if (baseStyle == null) return null;

    double multiplier = 1.0;
    if (isMobile(context)) {
      multiplier = mobileMultiplier ?? 1.0;
    } else if (isTablet(context)) {
      multiplier = tabletMultiplier ?? 1.1;
    } else {
      multiplier = desktopMultiplier ?? 1.2;
    }

    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null
          ? baseStyle.fontSize! * multiplier
          : null,
    );
  }
}




