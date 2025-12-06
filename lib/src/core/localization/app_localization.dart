import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Application localization class
class AppLocalizations {
  final Locale locale;
  Map<String, String>? _localizedStrings;

  AppLocalizations({required this.locale});

  /// Gets the localization from context (nullable)
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Localization delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationDelegate();

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('vi'),
  ];

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
      translation = translation.replaceAll('{\$$argKey}', value.toString());
    });
    return translation;
  }

  /// Shorthand for translate
  String tr(String key) => translate(key);
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationDelegate();

  static const List<String> _supportedLanguages = ['en', 'vi'];

  @override
  bool isSupported(Locale locale) {
    return _supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localization = AppLocalizations(locale: locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => false;
}

/// Extension for easy translation access
extension LocalizationExtension on BuildContext {
  /// Translates a key (returns key if localization not available)
  String tr(String key) => AppLocalizations.of(this).translate(key);

  /// Translates a key with arguments
  String trArgs(String key, Map<String, dynamic> args) =>
      AppLocalizations.of(this).translateWithArgs(key, args);
}
