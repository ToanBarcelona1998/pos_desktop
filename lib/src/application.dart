import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import '../helpers/app_theme.dart';
import 'application/application.dart';
import 'core/localization/app_localization.dart';
import 'core/navigation/navigation.dart';

final class DesktopScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

/// Main application widget with global state providers
class Application extends StatelessWidget {
  const Application({
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
      child: const ApplicationMaterialApp(),
    );
  }
}

/// Material app with theme, language, and navigation support
/// Uses onGenerateRoute for type-safe navigation
class ApplicationMaterialApp extends StatelessWidget {
  final String? initialRoute;
  final bool debugShowCheckedModeBanner;

  const ApplicationMaterialApp({
    super.key,
    this.initialRoute,
    this.debugShowCheckedModeBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, languageState) {
            return MaterialApp(
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              theme: themeState.themeData,
              locale: languageState.locale,
              supportedLocales: AppLanguages.supportedLocales,
              scrollBehavior:
                  Platform.isMacOS || Platform.isWindows || Platform.isLinux
                      ? DesktopScrollBehavior()
                      : null,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              // Use navigatorKey for global navigation access
              navigatorKey: navigatorKey,
              // Use onGenerateRoute for type-safe navigation
              onGenerateRoute: AppNavigator.onGenerateRoute,
              initialRoute: initialRoute ?? RoutePath.onlinePos.path,
            );
          },
        );
      },
    );
  }
}


/// Extension for easy access to global cubits
extension ApplicationContext on BuildContext {
  AppThemeCubit get themeCubit => read<AppThemeCubit>();

  LanguageCubit get languageCubit => read<LanguageCubit>();

  AuthCubit get authCubit => read<AuthCubit>();

  ThemeData get theme => themeCubit.state.themeData;

  CustomAppTheme get customTheme => themeCubit.customTheme;

  Locale get locale => languageCubit.state.locale;

  bool get isAuthenticated => authCubit.isAuthenticated;
}
