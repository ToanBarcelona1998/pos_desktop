import 'package:flutter/material.dart';

import 'api_end_points.dart';

class Config {
  static final String baseUrl = ApiEndPoints.baseUrl;
  static int? userId;
  String clientId = '7',
      clientSecret = 'ikfxjBPEghUyohjQrWaMRugc8q973ntYzibFxTjC',
      copyright = '\u00a9',
      appName = 'app',
      version = 'V 1.7',
      splashScreen = '$baseUrl/Uploads/mobile/welcome.jpg',
      loginScreen = '$baseUrl/Uploads/mobile/login.jpg',
      noDataImage = '$baseUrl/Uploads/mobile/no_data.jpg',
      defaultBusinessImage = '$baseUrl/Uploads/business_default.jpg';
  final bool syncCallLog = true, showRegister = false, showFieldForce = false;

  // Quantity precision, currency precision, call_log sync duration
  static int quantityPrecision = 2, currencyPrecision = 2, callLogSyncDuration = 30;

  // List of locale language codes
  List locale = ['en', 'ar', 'de', 'fr', 'es', 'tr', 'id', 'my', 'be', 'ch', 'it'];
  String defaultLanguage = 'en';

  // List of supported locales
  List<Locale> supportedLocales = [
    const Locale('en', 'US'),
    const Locale('ar', ''),
    const Locale('de', ''),
    const Locale('fr', ''),
    const Locale('es', ''),
    const Locale('tr', ''),
    const Locale('id', ''),
    const Locale('my', ''),
    const Locale('be', ''),
    const Locale('ch', ''),
    const Locale('it', ''),
  ];

  // Dropdown items for changing language
  List<Map<String, dynamic>> lang = [
    {'languageCode': 'en', 'countryCode': 'US', 'name': 'English'},
    {'languageCode': 'ar', 'countryCode': '', 'name': 'العربي'},
    {'languageCode': 'de', 'countryCode': '', 'name': 'Deutsche'},
    {'languageCode': 'fr', 'countryCode': '', 'name': 'Français'},
    {'languageCode': 'es', 'countryCode': '', 'name': 'Española'},
    {'languageCode': 'tr', 'countryCode': '', 'name': 'Türkçe'},
    {'languageCode': 'id', 'countryCode': '', 'name': 'Indonesian'},
    {'languageCode': 'be', 'countryCode': '', 'name': 'Bengali'},
    {'languageCode': 'ch', 'countryCode': '', 'name': 'Chinese'},
    {'languageCode': 'it', 'countryCode': '', 'name': 'Italian'},
    {'languageCode': 'my', 'countryCode': '', 'name': 'မြန်မာ'},
  ];

  // Google Maps API key
  final String googleAPIKey = 'AIzaSyDtorf5cQD5g7V4K2R0JVl8DcnnqiZS5Qw';
}