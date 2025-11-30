import 'package:flutter/material.dart';

/// Abstract color scheme for the application
abstract class AppColorScheme {
  // Primary colors
  Color get primary;
  Color get primaryLight;
  Color get primaryDark;
  Color get onPrimary;

  // Secondary colors
  Color get secondary;
  Color get secondaryLight;
  Color get secondaryDark;
  Color get onSecondary;

  // Background colors
  Color get background;
  Color get backgroundSecondary;
  Color get backgroundTertiary;
  Color get surface;
  Color get surfaceVariant;

  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textHint;
  Color get textDisabled;

  // Semantic colors
  Color get success;
  Color get onSuccess;
  Color get warning;
  Color get onWarning;
  Color get error;
  Color get onError;
  Color get info;
  Color get onInfo;

  // Border and divider
  Color get border;
  Color get divider;

  // Shadow
  Color get shadow;

  // Overlay
  Color get overlay;

  // Disabled
  Color get disabled;
  Color get onDisabled;

  // Card
  Color get card;

  // Input
  Color get inputBackground;
  Color get inputBorder;
  Color get inputFocusBorder;
}

/// Light theme colors
class LightColorScheme implements AppColorScheme {
  const LightColorScheme();

  @override
  Color get primary => const Color(0xFF2F4664);
  @override
  Color get primaryLight => const Color(0xFF4A6B8A);
  @override
  Color get primaryDark => const Color(0xFF1E2F42);
  @override
  Color get onPrimary => Colors.white;

  @override
  Color get secondary => const Color(0xFF495057);
  @override
  Color get secondaryLight => const Color(0xFF6C757D);
  @override
  Color get secondaryDark => const Color(0xFF343A40);
  @override
  Color get onSecondary => Colors.white;

  @override
  Color get background => const Color(0xFFFFFFFF);
  @override
  Color get backgroundSecondary => const Color(0xFFF9F9F9);
  @override
  Color get backgroundTertiary => const Color(0xFFE8ECF4);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceVariant => const Color(0xFFE2E7F1);

  @override
  Color get textPrimary => const Color(0xFF4A4C4F);
  @override
  Color get textSecondary => const Color(0xFF6C757D);
  @override
  Color get textHint => const Color(0xAA495057);
  @override
  Color get textDisabled => const Color(0xFF9E9E9E);

  @override
  Color get success => const Color(0xFF3CD278);
  @override
  Color get onSuccess => Colors.white;
  @override
  Color get warning => const Color(0xFFFFC837);
  @override
  Color get onWarning => Colors.white;
  @override
  Color get error => const Color(0xFFF0323C);
  @override
  Color get onError => Colors.white;
  @override
  Color get info => const Color(0xFFFF784B);
  @override
  Color get onInfo => Colors.white;

  @override
  Color get border => const Color(0xFFD1D1D1);
  @override
  Color get divider => const Color(0xFFD1D1D1);

  @override
  Color get shadow => const Color(0xFFEAEAEA);

  @override
  Color get overlay => Colors.black.withValues(alpha: 0.5);

  @override
  Color get disabled => const Color(0xFFDCC7FF);
  @override
  Color get onDisabled => Colors.white;

  @override
  Color get card => Colors.white;

  @override
  Color get inputBackground => Colors.white;
  @override
  Color get inputBorder => Colors.black54;
  @override
  Color get inputFocusBorder => const Color(0xFF2F4664);
}

/// Dark theme colors
class DarkColorScheme implements AppColorScheme {
  const DarkColorScheme();

  @override
  Color get primary => const Color(0xFF2F4664);
  @override
  Color get primaryLight => const Color(0xFF4A6B8A);
  @override
  Color get primaryDark => const Color(0xFF1E2F42);
  @override
  Color get onPrimary => Colors.white;

  @override
  Color get secondary => const Color(0xFF00CC77);
  @override
  Color get secondaryLight => const Color(0xFF33D692);
  @override
  Color get secondaryDark => const Color(0xFF00A35F);
  @override
  Color get onSecondary => Colors.white;

  @override
  Color get background => const Color(0xFF464C52);
  @override
  Color get backgroundSecondary => const Color(0xFF37404A);
  @override
  Color get backgroundTertiary => const Color(0xFF303138);
  @override
  Color get surface => const Color(0xFF464C52);
  @override
  Color get surfaceVariant => const Color(0xFF585E63);

  @override
  Color get textPrimary => Colors.white;
  @override
  Color get textSecondary => const Color(0xFFB0B0B0);
  @override
  Color get textHint => const Color(0xFF8E8E8E);
  @override
  Color get textDisabled => const Color(0xFF6E6E6E);

  @override
  Color get success => const Color(0xFF3CD278);
  @override
  Color get onSuccess => Colors.white;
  @override
  Color get warning => const Color(0xFFFFC837);
  @override
  Color get onWarning => Colors.white;
  @override
  Color get error => const Color(0xFFF0323C);
  @override
  Color get onError => Colors.white;
  @override
  Color get info => const Color(0xFFFF784B);
  @override
  Color get onInfo => Colors.white;

  @override
  Color get border => const Color(0xFF5A5A5A);
  @override
  Color get divider => const Color(0xFF5A5A5A);

  @override
  Color get shadow => const Color(0xFF1A1A1A);

  @override
  Color get overlay => Colors.black.withValues(alpha: 0.7);

  @override
  Color get disabled => const Color(0xFFBABABA);
  @override
  Color get onDisabled => Colors.black;

  @override
  Color get card => const Color(0xFF37404A);

  @override
  Color get inputBackground => const Color(0xFF37404A);
  @override
  Color get inputBorder => Colors.white70;
  @override
  Color get inputFocusBorder => const Color(0xFF2F4664);
}





