import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class OnlinePosScreen extends StatefulWidget {
  const OnlinePosScreen({super.key});

  @override
  State<OnlinePosScreen> createState() => _OnlinePosScreenState();
}

class _OnlinePosScreenState extends State<OnlinePosScreen> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://stg.oman.digityze.asia')
      ),
    );
  }
}
