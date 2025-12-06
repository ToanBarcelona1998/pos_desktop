import 'package:flutter/material.dart';

import '../../../pages/cart.dart';
import '../../../pages/category_screen.dart';
import '../../../pages/checkout/checkout.dart';
import '../../../pages/contact_payment.dart';
import '../../../pages/contacts.dart';
import '../../../pages/customer.dart';
import '../../../pages/expenses.dart';
import '../../../pages/field_force.dart';
import '../../../pages/follow_up.dart';
import '../../../pages/notifications/notify.dart';
import '../../../pages/on_boarding/on_boarding.dart';
import '../../presentation/pages/pos_online/pos_online_page.dart';
import '../../presentation/pages/pos/pos_page.dart';
import '../../../pages/product_stock_report.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../../pages/profit_loss_report.dart';
import '../../../pages/purchases/view/add_purchase_screen.dart';
import '../../../pages/purchases/view/products_selection_screen.dart';
import '../../../pages/purchases/view/purchase_checkout_screen.dart';
import '../../../pages/purchases/view/purchases_screen.dart';
import '../../../pages/report.dart';
import '../../../pages/sales.dart';
import '../../../pages/shipment.dart';
import '../../../pages/units/units.dart';
import '../../../pages/users.dart';
import '../../../pages/warranties/warranties.dart';
import '../../../pages/home/home_logic.dart';
import '../../presentation/pages/brands/brands_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import 'route_path.dart';

/// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App Navigator - Central navigation management
class AppNavigator {
  const AppNavigator._();

  /// Get the navigator state
  static NavigatorState? get _navigator => navigatorKey.currentState;

  /// Get the current context
  static BuildContext? get context => navigatorKey.currentContext;

  // ============== Push Methods ==============

  /// Push a named route
  static Future<T?> pushNamed<T>(
    String routeName, {
    Object? arguments,
  }) async {
    return _navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push a route path
  static Future<T?> push<T>(
    RoutePath route, {
    Object? arguments,
  }) async {
    return _navigator?.pushNamed<T>(route.path, arguments: arguments);
  }

  /// Push a route and remove all previous routes
  static Future<T?> pushNamedAndRemoveAll<T>(
    String routeName, {
    Object? arguments,
  }) async {
    return _navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Push a route path and remove all previous routes
  static Future<T?> pushAndRemoveAll<T>(
    RoutePath route, {
    Object? arguments,
  }) async {
    return pushNamedAndRemoveAll<T>(route.path, arguments: arguments);
  }

  /// Push a route and remove until a specific route
  static Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    String untilRoute, {
    Object? arguments,
  }) async {
    return _navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      ModalRoute.withName(untilRoute),
      arguments: arguments,
    );
  }

  /// Push a replacement route
  static Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    return _navigator?.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Push a replacement route path
  static Future<T?> pushReplacement<T, TO>(
    RoutePath route, {
    Object? arguments,
    TO? result,
  }) async {
    return pushReplacementNamed<T, TO>(route.path, arguments: arguments, result: result);
  }

  /// Push a widget directly
  static Future<T?> pushWidget<T>(Widget page) async {
    return _navigator?.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push a widget and remove all previous routes
  static Future<T?> pushWidgetAndRemoveAll<T>(Widget page) async {
    return _navigator?.pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  // ============== Pop Methods ==============

  /// Pop the current route
  static void pop<T>([T? result]) {
    if (_navigator?.canPop() ?? false) {
      _navigator?.pop<T>(result);
    }
  }

  /// Pop until a specific route
  static void popUntil(String routeName) {
    _navigator?.popUntil(ModalRoute.withName(routeName));
  }

  /// Pop until a specific route path
  static void popUntilRoute(RoutePath route) {
    popUntil(route.path);
  }

  /// Pop until the first route
  static void popToFirst() {
    _navigator?.popUntil((route) => route.isFirst);
  }

  /// Pop all routes and push a new one
  static Future<T?> popAllAndPush<T>(String routeName, {Object? arguments}) {
    return pushNamedAndRemoveAll<T>(routeName, arguments: arguments);
  }

  /// Try to pop, returns false if can't pop
  static Future<bool> maybePop<T>([T? result]) async {
    return _navigator?.maybePop<T>(result) ?? Future.value(false);
  }

  /// Check if can pop
  static bool canPop() {
    return _navigator?.canPop() ?? false;
  }

  // ============== Utility Methods ==============

  /// Get current route name
  static String? get currentRouteName {
    String? routeName;
    _navigator?.popUntil((route) {
      routeName = route.settings.name;
      return true;
    });
    return routeName;
  }

  /// Get current route
  static RoutePath? get currentRoute {
    final name = currentRouteName;
    return name != null ? RoutePath.fromPath(name) : null;
  }

  /// Check if route is active
  static bool isRouteActive(String routeName) {
    return currentRouteName == routeName;
  }

  /// Navigate to login and clear stack
  static Future<void> navigateToLogin() {
    return pushNamedAndRemoveAll(RoutePath.login.path);
  }

  /// Navigate to home and clear stack
  static Future<void> navigateToHome() {
    return pushNamedAndRemoveAll(RoutePath.layout.path);
  }

  // ============== Route Generator ==============

  /// Generate route based on settings
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth routes - Using new pages
      case '/splash':
        return _buildRoute(settings, const SplashPage());

      case '/onBoarding':
        return _buildRoute(settings, const OnBoardingScreen());

      case '/login':
        return _buildRoute(settings, const LoginPage());

      // Main routes - Using new pages
      case '/layout':
        return _buildRoute(settings, const HomePage());

      case '/products':
        return _buildRoute(settings, const ProductsPage());

      case '/Categories':
        return _buildRoute(settings, const CategoryScreen());

      case '/brands':
        return _buildRoute(settings, const BrandsPage());

      // case '/units':
      //   final homeLogic = args as HomeLogic? ?? HomeLogic(HomeState());
      //   return _buildRoute(settings, UnitsPage(homeLogic: homeLogic));

      // case '/products/warranties':
      //   final homeLogic = args as HomeLogic? ?? HomeLogic(HomeState());
      //   return _buildRoute(settings, WarrantiesPage(homeLogic: homeLogic));

      // POS routes
      case '/pos':
        return _buildRoute(settings, const PosPage());

      case '/online_pos':
        return _buildRoute(settings, const PosOnlinePage());

      case '/cart':
        return _buildRoute(settings, const Cart());

      case '/checkout':
        return _buildRoute(settings, const CheckoutScreen());

      // Sales routes
      case '/sale':
        return _buildRoute(settings, const Sales());

      case '/shipment':
        return _buildRoute(settings, const Shipment());

      // Customer routes
      case '/customer':
        return _buildRoute(settings, const Customer());

      case '/leads':
        return _buildRoute(settings, const Contacts());

      case '/contactPayment':
        return _buildRoute(settings, const ContactPayment());

      case '/followUp':
        return _buildRoute(settings, const FollowUp());

      case '/fieldForce':
        return _buildRoute(settings, const FieldForce());

      // Purchase routes
      case '/purchases':
        return _buildRoute(settings, const PurchasesScreen());

      case '/add_purchases':
        return _buildRoute(settings, const AddPurchasesScreen());

      case '/products_selection':
        return _buildRoute(settings, const ProductsSelectionScreen());

      case '/purchase_checkout':
        return _buildRoute(settings, const PurchaseCheckoutScreen());

      // Finance routes
      case '/expense':
        return _buildRoute(settings, const Expense());

      // User routes
      // case '/users':
      //   final logic = args as HomeLogic? ?? HomeLogic(HomeState());
      //   return _buildRoute(settings, UsersScreen(logic: logic));

      // Notification routes
      case '/notify':
        return _buildRoute(settings, const NotificationScreen());

      // Report routes
      case '/report':
        return _buildRoute(settings, ReportScreen());

      case '/profit_loss_report':
        return _buildRoute(settings, const ProfitLossReportScreen());

      case '/product_stock_report':
        return _buildRoute(settings, const ProductStockReportScreen());

      default:
        return _buildRoute(
          settings,
          Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Build a material page route
  static MaterialPageRoute<T> _buildRoute<T>(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => page,
    );
  }

  /// Build a fade transition route
  static PageRouteBuilder<T> _buildFadeRoute<T>(
    RouteSettings settings,
    Widget page,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Build a slide transition route
  static PageRouteBuilder<T> _buildSlideRoute<T>(
    RouteSettings settings,
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}
