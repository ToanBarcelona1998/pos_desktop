import 'package:flutter/material.dart';

/// Responsive utility for flexible sizing based on screen dimensions
/// Designed for POS devices and windows with different screen sizes
class ResponsiveUtils {
  // Base design dimensions (reference size for scaling)
  // Using a common POS device/window size as base
  static const double baseWidth = 1920.0; // Common desktop/POS width
  static const double baseHeight = 1080.0; // Common desktop/POS height
  
  // Minimum scale factor to prevent too small UI
  static const double minScale = 0.8;
  // Maximum scale factor to prevent too large UI
  static const double maxScale = 1.3;

  /// Get the scale factor based on screen width
  /// Uses the smaller dimension (width or height) to ensure UI fits
  static double getScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final width = size.width;
    final height = size.height;
    
    // Use the smaller dimension to ensure UI fits on screen
    final smallerDimension = width < height ? width : height;
    final baseDimension = baseWidth < baseHeight ? baseWidth : baseHeight;
    
    // Calculate scale factor
    double scale = smallerDimension / baseDimension;
    
    // Clamp scale factor between min and max
    scale = scale.clamp(minScale, maxScale);
    
    return scale;
  }

  /// Get scale factor based on width only
  static double getWidthScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    double scale = width / baseWidth;
    return scale.clamp(minScale, maxScale);
  }

  /// Get scale factor based on height only
  static double getHeightScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height;
    double scale = height / baseHeight;
    return scale.clamp(minScale, maxScale);
  }

  /// Scale a value based on screen size
  static double scale(BuildContext context, double value) {
    return value * getScaleFactor(context);
  }

  /// Scale spacing value
  static double scaleSpacing(BuildContext context, double spacing) {
    return scale(context, spacing);
  }

  /// Scale font size
  static double scaleFontSize(BuildContext context, double fontSize) {
    return scale(context, fontSize);
  }

  /// Scale icon size
  static double scaleIconSize(BuildContext context, double iconSize) {
    return scale(context, iconSize);
  }

  /// Scale size (for buttons, inputs, etc.)
  static double scaleSize(BuildContext context, double size) {
    return scale(context, size);
  }

  /// Check if screen is small (for compact layouts)
  static bool isSmallScreen(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    return width < 1024;
  }

  /// Check if screen is medium (tablet/POS device)
  static bool isMediumScreen(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    return width >= 1024 && width < 1920;
  }

  /// Check if screen is large (desktop/window)
  static bool isLargeScreen(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    return width >= 1920;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final scale = getScaleFactor(context);
    return EdgeInsets.all(16 * scale);
  }

  /// Get responsive margin based on screen size
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final scale = getScaleFactor(context);
    return EdgeInsets.all(8 * scale);
  }
}

