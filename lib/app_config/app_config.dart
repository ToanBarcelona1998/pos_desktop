/// Application configuration
final class AppConfig {
  final String baseUrl;
  final String clientSecret;
  final String clientId;
  final String webUrl;
  final String environment;

  const AppConfig({
    required this.baseUrl,
    required this.clientSecret,
    required this.webUrl,
    this.clientId = '7',
    this.environment = 'production',
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      baseUrl: json['base_url'] as String,
      clientSecret: json['client_secret'] as String,
      webUrl: json['web_url'] as String,
      clientId: json['client_id'] as String? ?? '7',
      environment: json['environment'] as String? ?? 'production',
    );
  }

  /// Development configuration
  factory AppConfig.development() {
    return const AppConfig(
      baseUrl: 'https://sandbox.oman.digityze.asia',
      clientSecret: 'ikfxjBPEghUyohjQrWaMRugc8q973ntYzibFxTjC',
      webUrl: 'https://sandbox.oman.digityze.asia',
      clientId: '7',
      environment: 'development',
    );
  }

  /// Production configuration
  factory AppConfig.production() {
    return const AppConfig(
      baseUrl: 'https://sandbox.oman.digityze.asia',
      clientSecret: 'ikfxjBPEghUyohjQrWaMRugc8q973ntYzibFxTjC',
      webUrl: 'https://sandbox.oman.digityze.asia',
      clientId: '7',
      environment: 'production',
    );
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';

  /// API URL prefix
  String get apiUrl => '/connector/api';

  /// OAuth login URL
  String get loginUrl => '$baseUrl/oauth/token';

  /// User endpoint
  String get userEndpoint => '$apiUrl/user/loggedin';

  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'client_secret': clientSecret,
      'client_id': clientId,
      'web_url': webUrl,
      'environment': environment,
    };
  }

  @override
  String toString() => 'AppConfig(environment: $environment, baseUrl: $baseUrl)';
}
