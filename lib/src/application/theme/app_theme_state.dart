import 'package:flutter/material.dart';

/// Theme mode enum
enum AppThemeMode {
  light(1),
  dark(2),
  system(0);

  final int value;
  const AppThemeMode(this.value);

  static AppThemeMode fromValue(int value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppThemeMode.light,
    );
  }
}

/// State for app theme
class AppThemeState {
  final AppThemeMode themeMode;
  final ThemeData themeData;
  final bool isInitialized;

  const AppThemeState({
    required this.themeMode,
    required this.themeData,
    this.isInitialized = false,
  });

  AppThemeState copyWith({
    AppThemeMode? themeMode,
    ThemeData? themeData,
    bool? isInitialized,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeData: themeData ?? this.themeData,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppThemeState &&
        other.themeMode == themeMode &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode => themeMode.hashCode ^ isInitialized.hashCode;
}










