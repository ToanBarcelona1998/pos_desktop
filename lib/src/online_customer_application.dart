import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_final/src/presentation/pages/online_customer/online_customer.dart';

class OnlineCustomerApplication extends StatelessWidget {
  const OnlineCustomerApplication({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return Scaffold(
          body: OnlineCustomerPage(),
        );
      },
    );
  }
}