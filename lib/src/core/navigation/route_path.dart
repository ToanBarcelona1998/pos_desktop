/// Sealed class defining all route paths in the application
/// Use these constants instead of hardcoded strings for type-safe navigation
sealed class RoutePath {
  const RoutePath._();

  // Auth routes
  static const String splash = '/splash';
  static const String onBoarding = '/onBoarding';
  static const String login = '/login';

  // Main routes
  static const String layout = '/layout';
  static const String home = '/home';

  // Product routes
  static const String products = '/products';
  static const String categories = '/Categories';
  static const String brands = '/brands';
  static const String units = '/units';
  static const String warranties = '/products/warranties';

  // POS routes
  static const String pos = '/pos';
  static const String onlinePos = '/online_pos';
  static const String cart = '/cart';
  static const String checkout = '/checkout';

  // Sales routes
  static const String sale = '/sale';
  static const String shipment = '/shipment';

  // Customer routes
  static const String customer = '/customer';
  static const String leads = '/leads';
  static const String contactPayment = '/contactPayment';
  static const String followUp = '/followUp';
  static const String fieldForce = '/fieldForce';

  // Purchase routes
  static const String purchases = '/purchases';
  static const String addPurchases = '/add_purchases';
  static const String productsSelection = '/products_selection';
  static const String purchaseCheckout = '/purchase_checkout';

  // Finance routes
  static const String expense = '/expense';

  // User routes
  static const String users = '/users';

  // Notification routes
  static const String notify = '/notify';

  // Report routes
  static const String report = '/report';
  static const String profitLossReport = '/profit_loss_report';
  static const String productStockReport = '/product_stock_report';

  /// Get route name without leading slash (for logging/analytics)
  static String nameOf(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Check if a route requires authentication
  static bool requiresAuth(String path) {
    const publicRoutes = [splash, onBoarding, login];
    return !publicRoutes.contains(path);
  }

  /// Get all routes as a list
  static List<String> get allRoutes => [
        splash,
        onBoarding,
        login,
        layout,
        home,
        products,
        categories,
        brands,
        units,
        warranties,
        pos,
        onlinePos,
        cart,
        checkout,
        sale,
        shipment,
        customer,
        leads,
        contactPayment,
        followUp,
        fieldForce,
        purchases,
        addPurchases,
        productsSelection,
        purchaseCheckout,
        expense,
        users,
        notify,
        report,
        profitLossReport,
        productStockReport,
      ];
}

