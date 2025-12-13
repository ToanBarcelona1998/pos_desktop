import 'dart:convert';

import 'package:flutter/services.dart';

import 'app_config.dart';

/// Environment types
enum Environment { development, staging, production }

/// Loads configuration from JSON files in assets/config
class EnvConfig {
  static Environment _environment = Environment.staging;
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

    final configFileName = switch(env){
      Environment.development => 'env_development.json',
      Environment.staging => 'env_staging.json',
      Environment.production => 'env_production.json'
    };

    final jsonString = await rootBundle.loadString('assets/config/$configFileName');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    _config = AppConfig.fromJson(jsonMap);

    return _config!;
  }

  /// Reloads configuration with a different environment
  static Future<AppConfig> switchEnvironment(Environment env) async {
    return load(env);
  }
}
