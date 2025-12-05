import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/app_theme.dart';
import 'app_theme_state.dart';

/// Cubit for managing app theme globally
class AppThemeCubit extends Cubit<AppThemeState> {
  static const String _themeKey = 'app_theme_mode';

  AppThemeCubit()
      : super(AppThemeState(
          themeMode: AppThemeMode.light,
          themeData: AppTheme.getThemeFromThemeMode(AppTheme.themeLight),
        ));

  /// Initializes the theme from stored preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getInt(_themeKey) ?? AppTheme.themeLight;
    final themeMode = AppThemeMode.fromValue(storedTheme);

    emit(AppThemeState(
      themeMode: themeMode,
      themeData: AppTheme.getThemeFromThemeMode(themeMode.value),
      isInitialized: true,
    ));
  }

  /// Changes the theme mode
  Future<void> changeTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.value);

    emit(state.copyWith(
      themeMode: mode,
      themeData: AppTheme.getThemeFromThemeMode(mode.value),
    ));
  }

  /// Toggles between light and dark theme
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await changeTheme(newMode);
  }

  /// Sets light theme
  Future<void> setLightTheme() => changeTheme(AppThemeMode.light);

  /// Sets dark theme
  Future<void> setDarkTheme() => changeTheme(AppThemeMode.dark);

  /// Gets the current custom app theme
  CustomAppTheme get customTheme =>
      AppTheme.getCustomAppTheme(state.themeMode.value);

  /// Checks if current theme is dark
  bool get isDark => state.themeMode == AppThemeMode.dark;

  /// Checks if current theme is light
  bool get isLight => state.themeMode == AppThemeMode.light;
}












