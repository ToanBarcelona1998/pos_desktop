import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_radius.dart';

/// Abstract theme builder
abstract class AppThemeBuilder {
  /// Color scheme for this theme
  AppColorScheme get colorScheme;

  /// Whether this is a dark theme
  bool get isDark;

  /// Builds the ThemeData
  ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: Colors.transparent,
      cardColor: colorScheme.card,
      dividerColor: colorScheme.divider,
      disabledColor: colorScheme.disabled,
      highlightColor: Colors.white,
      splashColor: Colors.white.withValues(alpha: 0.4),
      colorScheme: _buildColorScheme(),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      floatingActionButtonTheme: _buildFabTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      navigationRailTheme: _buildNavRailTheme(),
      tabBarTheme: _buildTabBarTheme(),
      dialogTheme: _buildDialogTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      popupMenuTheme: _buildPopupMenuTheme(),
      bottomAppBarTheme: _buildBottomAppBarTheme(),
      sliderTheme: _buildSliderTheme(),
      iconTheme: IconThemeData(color: colorScheme.textPrimary),
    );
  }

  ColorScheme _buildColorScheme() {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      error: colorScheme.error,
      onError: colorScheme.onError,
      surface: colorScheme.surface,
      onSurface: colorScheme.textPrimary,
    );
  }

  TextTheme _buildTextTheme() {
    final color = colorScheme.textPrimary;
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: color),
      displayMedium: AppTypography.displayMedium.copyWith(color: color),
      displaySmall: AppTypography.displaySmall.copyWith(color: color),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: color),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: color),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: color),
      titleLarge: AppTypography.titleLarge.copyWith(color: color),
      titleMedium: AppTypography.titleMedium.copyWith(color: color),
      titleSmall: AppTypography.titleSmall.copyWith(color: color),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: color),
      bodySmall: AppTypography.bodySmall.copyWith(color: color),
      labelLarge: AppTypography.labelLarge.copyWith(color: color),
      labelMedium: AppTypography.labelMedium.copyWith(color: color),
      labelSmall: AppTypography.labelSmall.copyWith(color: color),
    );
  }

  AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.textPrimary, size: 24),
      actionsIconTheme: IconThemeData(color: colorScheme.textPrimary),
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: colorScheme.textPrimary,
      ),
    );
  }

  CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: colorScheme.card,
      shadowColor: colorScheme.shadow,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
    );
  }

  InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.inputBackground,
      hintStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.textHint),
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusSm,
        borderSide: BorderSide(color: colorScheme.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusSm,
        borderSide: BorderSide(color: colorScheme.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusSm,
        borderSide: BorderSide(color: colorScheme.inputFocusBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderRadiusSm,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
        elevation: 2,
      ),
    );
  }

  OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
        side: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  FloatingActionButtonThemeData _buildFabTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
    );
  }

  BottomNavigationBarThemeData _buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    );
  }

  NavigationRailThemeData _buildNavRailTheme() {
    return NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      unselectedIconTheme: IconThemeData(color: colorScheme.textSecondary, size: 24),
      selectedLabelTextStyle: TextStyle(color: colorScheme.primary),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.textSecondary),
      elevation: 3,
    );
  }

  TabBarThemeData _buildTabBarTheme() {
    return TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.textSecondary,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
    );
  }

  SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: colorScheme.textPrimary,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: colorScheme.surface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSm,
      ),
    );
  }

  PopupMenuThemeData _buildPopupMenuTheme() {
    return PopupMenuThemeData(
      color: colorScheme.surface,
      textStyle: AppTypography.bodyMedium.copyWith(
        color: colorScheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSm,
      ),
    );
  }

  BottomAppBarThemeData _buildBottomAppBarTheme() {
    return BottomAppBarThemeData(
      color: colorScheme.surface,
      elevation: 2,
    );
  }

  SliderThemeData _buildSliderTheme() {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.5),
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.3),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary),
    );
  }
}

/// Light theme implementation
class LightThemeBuilder extends AppThemeBuilder {
  @override
  final AppColorScheme colorScheme = const LightColorScheme();

  @override
  bool get isDark => false;
}

/// Dark theme implementation
class DarkThemeBuilder extends AppThemeBuilder {
  @override
  final AppColorScheme colorScheme = const DarkColorScheme();

  @override
  bool get isDark => true;
}

/// Theme provider
class AppThemes {
  static final ThemeData light = LightThemeBuilder().build();
  static final ThemeData dark = DarkThemeBuilder().build();

  static ThemeData getTheme({required bool isDark}) {
    return isDark ? dark : light;
  }

  static AppColorScheme getColorScheme({required bool isDark}) {
    return isDark ? const DarkColorScheme() : const LightColorScheme();
  }
}

