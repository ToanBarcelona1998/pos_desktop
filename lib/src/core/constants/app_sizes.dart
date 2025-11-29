import 'package:flutter/material.dart';

/// Application size constants
abstract final class AppSizes {
  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;

  // Avatar sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;
  static const double avatarXxl = 96.0;

  // Button heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  // Input heights
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;

  // AppBar height
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 72.0;

  // Bottom navigation height
  static const double bottomNavHeight = 64.0;

  // Card sizes
  static const double cardMinHeight = 80.0;
  static const double cardMaxWidth = 400.0;

  // Modal sizes
  static const double modalWidthSm = 320.0;
  static const double modalWidthMd = 480.0;
  static const double modalWidthLg = 640.0;
  static const double modalWidthXl = 800.0;

  // Sidebar width
  static const double sidebarWidth = 280.0;
  static const double sidebarWidthCollapsed = 72.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerThicknessBold = 2.0;

  // Touch target minimum
  static const double minTouchTarget = 48.0;
}

/// Responsive breakpoints
abstract final class AppBreakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopLarge;
}

