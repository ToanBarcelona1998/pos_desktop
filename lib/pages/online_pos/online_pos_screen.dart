import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_observer.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_subject.dart';

class OnlinePosScreen extends StatefulWidget {
  const OnlinePosScreen({super.key});

  @override
  State<OnlinePosScreen> createState() => _OnlinePosScreenState();
}

class _OnlinePosScreenState extends State<OnlinePosScreen> implements NetworkStatusObserver{
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  late NetworkStatusSubject _networkStatusSubject;

  @override
  void initState() {
    _networkStatusSubject = NetworkStatusSubject();
    _networkStatusSubject.attach(this);
    _networkStatusSubject.listenNetworkChanged();
    super.initState();
  }

  @override
  void dispose() {
    _networkStatusSubject.detach(this);
    _networkStatusSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('https://stg.oman.digityze.asia')
        ),
      ),
    );
  }

  @override
  void update(bool newState) {
    if(!newState && mounted){
      Navigator.pushReplacementNamed(context, '/pos');
    }
  }
}
