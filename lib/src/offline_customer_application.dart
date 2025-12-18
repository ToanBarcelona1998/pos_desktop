import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_final/src/application.dart';
import 'core/localization/app_localization.dart';
import 'package:pos_final/src/presentation/pages/offline_customer/offline_customer.dart';

import 'application/application.dart';

class OfflineCustomerApplication extends StatelessWidget {
  const OfflineCustomerApplication({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppThemeCubit>(
          create: (_) => AppThemeCubit()..init(),
        ),
        BlocProvider<LanguageCubit>(
          create: (_) => LanguageCubit()..init(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
        ),
      ],
      child: const _OfflineCustomerApplication(),
    );
  }
}

class _OfflineCustomerApplication extends StatelessWidget {
  const _OfflineCustomerApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, languageState) {
            return MaterialApp(
              theme: themeState.themeData,
              locale: languageState.locale,
              scrollBehavior: Platform.isMacOS || Platform.isWindows || Platform.isLinux
                  ? DesktopScrollBehavior()
                  : null,
              supportedLocales: AppLanguages.supportedLocales,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: const OfflineCustomerPage(),
            );
          },
        );
      },
    );
  }
}
