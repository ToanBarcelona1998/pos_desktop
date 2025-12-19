import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_final/src/presentation/pages/online_customer/online_customer.dart';

import 'application.dart';

class OnlineCustomerApplication extends StatelessWidget {
  final String href;
  const OnlineCustomerApplication({
    super.key,
    required this.href,
  });

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
      home: OnlineCustomerPage(
        href: href,
      ),
    );
  }
}