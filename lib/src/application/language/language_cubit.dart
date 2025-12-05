import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_state.dart';

/// Cubit for managing app language globally
class LanguageCubit extends Cubit<LanguageState> {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'countryCode';

  LanguageCubit()
      : super(LanguageState(
          locale: Locale(AppLanguages.defaultLanguage),
          languageCode: AppLanguages.defaultLanguage,
        ));

  /// Initializes the language from stored preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode =
        prefs.getString(_languageCodeKey) ?? AppLanguages.defaultLanguage;
    final countryCode = prefs.getString(_countryCodeKey) ?? '';

    final locale = Locale(languageCode, countryCode.isEmpty ? null : countryCode);

    emit(LanguageState(
      locale: locale,
      languageCode: languageCode,
      countryCode: countryCode.isEmpty ? null : countryCode,
      isInitialized: true,
    ));
  }

  /// Changes the app language
  Future<void> changeLanguage(String languageCode, {String? countryCode}) async {
    if (languageCode == state.languageCode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
    await prefs.setString(_countryCodeKey, countryCode ?? '');

    final locale = Locale(languageCode, countryCode);

    emit(LanguageState(
      locale: locale,
      languageCode: languageCode,
      countryCode: countryCode,
      isInitialized: true,
    ));
  }

  /// Changes language using LanguageOption
  Future<void> setLanguage(LanguageOption option) async {
    await changeLanguage(
      option.code,
      countryCode: option.countryCode.isEmpty ? null : option.countryCode,
    );
  }

  /// Gets current language option
  LanguageOption? get currentLanguage =>
      AppLanguages.getLanguageByCode(state.languageCode);

  /// Gets all supported languages
  List<LanguageOption> get supportedLanguages => AppLanguages.supportedLanguages;

  /// Gets all supported locales
  List<Locale> get supportedLocales => AppLanguages.supportedLocales;

  /// Checks if a language code is supported
  bool isSupported(String languageCode) =>
      AppLanguages.supportedLanguages.any((l) => l.code == languageCode);
}












