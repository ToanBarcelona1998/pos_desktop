import 'dart:ui';

/// State for app language
class LanguageState {
  final Locale locale;
  final String languageCode;
  final String? countryCode;
  final bool isInitialized;

  const LanguageState({
    required this.locale,
    required this.languageCode,
    this.countryCode,
    this.isInitialized = false,
  });

  LanguageState copyWith({
    Locale? locale,
    String? languageCode,
    String? countryCode,
    bool? isInitialized,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageState &&
        other.locale == locale &&
        other.isInitialized == isInitialized;
  }

  @override
  int get hashCode => locale.hashCode ^ isInitialized.hashCode;
}

/// Available languages in the app
class AppLanguages {
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', countryCode: 'US', name: 'English'),
    LanguageOption(code: 'vi', countryCode: 'VN', name: 'Vietnamese'),
  ];

  static const String defaultLanguage = 'vi';

  static List<Locale> get supportedLocales =>
      supportedLanguages.map((l) => l.toLocale()).toList();

  static LanguageOption? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }
}

/// Language option model
class LanguageOption {
  final String code;
  final String countryCode;
  final String name;

  const LanguageOption({
    required this.code,
    required this.countryCode,
    required this.name,
  });

  Locale toLocale() => Locale(code, countryCode.isEmpty ? null : countryCode);

  @override
  String toString() => name;
}












