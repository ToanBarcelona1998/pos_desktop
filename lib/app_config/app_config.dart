final class AppConfig {
  final String baseUrl;
  final String clientSecret;
  final String webUrl;

  const AppConfig({
    required this.baseUrl,
    required this.clientSecret,
    required this.webUrl,
  });

  factory AppConfig.fromJson(Map<String,dynamic> json){
    return AppConfig(baseUrl: json['base_url'], clientSecret: json['client_secret'], webUrl: json['web_url']);
  }
}
