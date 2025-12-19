import 'package:flutter/material.dart';
import 'package:pos_final/app_config/app_config.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class OnlineCustomerPage extends StatefulWidget {
  final String href;

  const OnlineCustomerPage({required this.href, super.key});

  @override
  State<OnlineCustomerPage> createState() => _OnlineCustomerPageState();
}

class _OnlineCustomerPageState extends State<OnlineCustomerPage> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );
  final AppConfig _appConfig = sl.get<AppConfig>();
  final WebViewEnvironment? _webViewEnvironment =
  sl.getOrNull<WebViewEnvironment>();

  Map<String, String> get _requiredHeaders => {
    'X-Oman-Application': _appConfig.webHeader,
  };

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          webViewEnvironment: _webViewEnvironment,
          initialUrlRequest: URLRequest(
            url: WebUri(widget.href),
            headers: _requiredHeaders,
          ),
        ),
      ),
    );
  }
}
