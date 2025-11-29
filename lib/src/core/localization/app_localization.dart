import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application localization class
class AppLocalization {
  final Locale locale;
  Map<String, String>? _localizedStrings;

  AppLocalization({required this.locale});

  /// Gets the localization from context
  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  /// Localization delegate
  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();

  /// Loads the localization strings from JSON
  Future<bool> load() async {
    try {
      final jsonString =
          await rootBundle.loadString('i18n/${locale.languageCode}.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      // Fallback to empty map
      _localizedStrings = {};
      return false;
    }
  }

  /// Translates a key
  String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }

  /// Translates a key with arguments
  String translateWithArgs(String key, Map<String, dynamic> args) {
    String translation = translate(key);
    args.forEach((argKey, value) {
      translation = translation.replaceAll('{$argKey}', value.toString());
    });
    return translation;
  }

  /// Shorthand for translate
  String tr(String key) => translate(key);
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  static const List<String> _supportedLanguages = ['en', 'vi'];

  @override
  bool isSupported(Locale locale) {
    return _supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    final localization = AppLocalization(locale: locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => false;
}

/// Extension for easy translation access
extension LocalizationExtension on BuildContext {
  /// Translates a key
  String tr(String key) => AppLocalization.of(this).translate(key);

  /// Translates a key with arguments
  String trArgs(String key, Map<String, dynamic> args) =>
      AppLocalization.of(this).translateWithArgs(key, args);
}

