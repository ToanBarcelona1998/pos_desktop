import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
import 'package:pos_final/src/core/utils/window_manager_abstract.dart';
import 'package:pos_final/src/offline_customer_application.dart';
import 'package:pos_final/src/presentation/pages/offline_customer/offline_customer.dart';
import 'package:pos_final/src/presentation/pages/online_customer/online_customer.dart';
import 'application.dart';

class OnlineCustomerApplication extends StatefulWidget {
  final String href;

  const OnlineCustomerApplication({
    super.key,
    required this.href,
  });

  @override
  State<OnlineCustomerApplication> createState() =>
      _OnlineCustomerApplicationState();
}

class _OnlineCustomerApplicationState extends State<OnlineCustomerApplication> {
  late String _currentHref;
  WindowType type = WindowType.none;
  final FlutterPresentationDisplay _display = FlutterPresentationDisplay();

  @override
  void initState() {
    super.initState();
    _currentHref = widget.href;
    dev.log('Màn hình phụ current href $_currentHref',
        name: 'SECONDARY_DISPLAY');

    // On Android, listen for data updates from main display
    if (Platform.isAndroid) {
      dev.log('Màn hình phụ ', name: 'SECONDARY_DISPLAY');
      _display.listenDataFromMainDisplay((data) {
        dev.log('Màn hình phụ nhận được data: $data',
            name: 'SECONDARY_DISPLAY');
        if (data is Map && data.containsKey('href')) {
          if (mounted) {
            _currentHref = data['href'] as String;
          }

          if (data.containsKey('type')) {
            type = WindowType.fromName(data['type'] ?? '');
          }
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: Platform.isMacOS || Platform.isWindows || Platform.isLinux
          ? DesktopScrollBehavior()
          : null,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: _currentHref.isEmpty
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : type == WindowType.onlineCustomer
              ? OnlineCustomerPage(
                  href: _currentHref,
                )
              : OfflineCustomerApplication(),
    );
  }
}
