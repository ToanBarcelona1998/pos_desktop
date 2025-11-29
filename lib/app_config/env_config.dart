import 'dart:convert';

import 'package:flutter/services.dart';

import 'app_config.dart';

/// Environment types
enum Environment { development, production }

/// Loads configuration from JSON files in assets/config
class EnvConfig {
  static Environment _environment = Environment.development;
  static AppConfig? _config;

  /// Current environment
  static Environment get environment => _environment;

  /// Current configuration
  static AppConfig get config {
    if (_config == null) {
      throw Exception('EnvConfig not initialized. Call load() first.');
    }
    return _config!;
  }

  /// Whether config is loaded
  static bool get isLoaded => _config != null;

  /// Loads configuration from JSON file based on environment
  static Future<AppConfig> load([Environment env = Environment.development]) async {
    _environment = env;

    final configFileName = env == Environment.production
        ? 'env_production.json'
        : 'env_development.json';

    try {
      final jsonString = await rootBundle.loadString('assets/config/$configFileName');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _config = AppConfig(
        baseUrl: jsonMap['base_url'] as String? ?? 'https://sandbox.oman.digityze.asia',
        clientSecret: jsonMap['client_secret'] as String? ?? '',
        webUrl: jsonMap['web_url'] as String? ?? '',
        clientId: jsonMap['client_id'] as String? ?? '7',
        environment: jsonMap['environment'] as String? ?? 'development',
      );

      return _config!;
    } catch (e) {
      // Fallback to default config
      _config = env == Environment.production
          ? AppConfig.production()
          : AppConfig.development();
      return _config!;
    }
  }

  /// Reloads configuration with a different environment
  static Future<AppConfig> switchEnvironment(Environment env) async {
    return load(env);
  }
}
