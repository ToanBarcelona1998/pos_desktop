import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_observer.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_subject.dart';
import 'package:pos_final/src/presentation/widgets/dialog/dialog_provider.dart';

class PosOnlinePage extends StatefulWidget {
  const PosOnlinePage({super.key});

  @override
  State<PosOnlinePage> createState() => _PosOnlinePageState();
}

class _PosOnlinePageState extends State<PosOnlinePage>
    implements NetworkStatusObserver {
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
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest:
          URLRequest(url: WebUri('https://stg.oman.digityze.asia')),
        ),
      ),
    );
  }

  @override
  void update(bool newState) {
    if (!newState && mounted) {
      DialogProvider.showConfirmDialog(
          context,
          message: 'Có vấn đề về đường truyền, bạn có muốn chuyển qua chế độ offline không?',
          onConfirm: (){
            Navigator.pushReplacementNamed(context, '/pos');
          }
      );
    }
  }
}




