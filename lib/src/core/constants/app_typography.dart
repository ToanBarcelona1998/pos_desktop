import 'package:flutter/material.dart';

/// Application typography constants
abstract final class AppTypography {
  // Font family
  static const String fontFamily = 'Cairo';

  // Font sizes
  static const double fontSizeXxs = 10.0;
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 24.0;
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeDisplayLg = 48.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;

  // Font weights
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Text styles - Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeDisplayLg,
    fontWeight: weightBold,
    height: lineHeightTight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeDisplay,
    fontWeight: weightBold,
    height: lineHeightTight,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxl,
    fontWeight: weightSemiBold,
    height: lineHeightTight,
  );

  // Text styles - Headline
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxl,
    fontWeight: weightSemiBold,
    height: lineHeightNormal,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXl,
    fontWeight: weightSemiBold,
    height: lineHeightNormal,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: weightSemiBold,
    height: lineHeightNormal,
  );

  // Text styles - Title
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: weightMedium,
    height: lineHeightNormal,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: weightMedium,
    height: lineHeightNormal,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: weightMedium,
    height: lineHeightNormal,
  );

  // Text styles - Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: weightRegular,
    height: lineHeightNormal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: weightRegular,
    height: lineHeightNormal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: weightRegular,
    height: lineHeightNormal,
  );

  // Text styles - Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: weightMedium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: weightMedium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxs,
    fontWeight: weightMedium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );

  // Text styles - Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: weightRegular,
    height: lineHeightNormal,
  );

  // Text styles - Button
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: weightSemiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );
}

