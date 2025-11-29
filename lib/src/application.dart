import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../helpers/app_theme.dart';
import '../locale/my_localizations.dart';
import 'application/application.dart';
import 'core/navigation/navigation.dart';

/// Main application widget with global state providers
class Application extends StatelessWidget {
  final Widget child;

  const Application({
    super.key,
    required this.child,
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
          create: (_) => AuthCubit()..checkAuthentication(),
        ),
      ],
      child: child,
    );
  }
}

/// Material app with theme, language, and navigation support
/// Uses onGenerateRoute for type-safe navigation
class ApplicationMaterialApp extends StatelessWidget {
  final String initialRoute;
  final bool debugShowCheckedModeBanner;

  const ApplicationMaterialApp({
    super.key,
    this.initialRoute = RoutePath.splash,
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
              initialRoute: initialRoute,
            );
          },
        );
      },
    );
  }
}

/// Legacy support: Material app with routes map (deprecated, use ApplicationMaterialApp instead)
@Deprecated('Use ApplicationMaterialApp with onGenerateRoute instead')
class ApplicationMaterialAppLegacy extends StatelessWidget {
  final Map<String, Widget Function(BuildContext)> routes;
  final String initialRoute;
  final bool debugShowCheckedModeBanner;

  const ApplicationMaterialAppLegacy({
    super.key,
    required this.routes,
    this.initialRoute = '/splash',
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
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              routes: routes,
              initialRoute: initialRoute,
            );
          },
        );
      },
    );
  }
}

/// Convenience widget for building with theme
class ThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ThemeData theme, CustomAppTheme customTheme) builder;

  const ThemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, state) {
        final customTheme = context.read<AppThemeCubit>().customTheme;
        return builder(context, state.themeData, customTheme);
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

/// Extension for navigation using AppNavigator
extension NavigationContext on BuildContext {
  /// Navigate to a named route
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return AppNavigator.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  Future<T?> navigateToAndRemoveAll<T>(String routeName, {Object? arguments}) {
    return AppNavigator.pushNamedAndRemoveAll<T>(routeName, arguments: arguments);
  }

  /// Navigate to a named route and replace the current route
  Future<T?> navigateToReplacement<T>(String routeName, {Object? arguments}) {
    return AppNavigator.pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);
  }

  /// Go back
  void goBack<T>([T? result]) {
    AppNavigator.pop<T>(result);
  }

  /// Go back to a specific route
  void goBackTo(String routeName) {
    AppNavigator.popUntil(routeName);
  }

  /// Go back to the first route
  void goBackToFirst() {
    AppNavigator.popToFirst();
  }

  /// Navigate to login and clear all routes
  Future<void> navigateToLogin() {
    return AppNavigator.navigateToLogin();
  }

  /// Navigate to home and clear all routes
  Future<void> navigateToHome() {
    return AppNavigator.navigateToHome();
  }
}
