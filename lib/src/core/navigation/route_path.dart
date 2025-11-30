/// Sealed class defining all route paths in the application
/// Use these constants instead of hardcoded strings for type-safe navigation
sealed class RoutePath {
  /// The route path string
  final String path;
  
  /// The route name for display
  final String name;
  
  /// Whether this route requires authentication
  final bool requiresAuth;

  const RoutePath({
    required this.path,
    required this.name,
    this.requiresAuth = true,
  });

  // Auth routes
  static const splash = _SplashRoute();
  static const onBoarding = _OnBoardingRoute();
  static const login = _LoginRoute();

  // Main routes
  static const layout = _LayoutRoute();
  static const home = _HomeRoute();

  // Product routes
  static const products = _ProductsRoute();
  static const categories = _CategoriesRoute();
  static const brands = _BrandsRoute();
  static const units = _UnitsRoute();
  static const warranties = _WarrantiesRoute();

  // POS routes
  static const pos = _PosRoute();
  static const onlinePos = _OnlinePosRoute();
  static const cart = _CartRoute();
  static const checkout = _CheckoutRoute();

  // Sales routes
  static const sale = _SaleRoute();
  static const shipment = _ShipmentRoute();

  // Customer routes
  static const customer = _CustomerRoute();
  static const leads = _LeadsRoute();
  static const contactPayment = _ContactPaymentRoute();
  static const followUp = _FollowUpRoute();
  static const fieldForce = _FieldForceRoute();

  // Purchase routes
  static const purchases = _PurchasesRoute();
  static const addPurchases = _AddPurchasesRoute();
  static const productsSelection = _ProductsSelectionRoute();
  static const purchaseCheckout = _PurchaseCheckoutRoute();

  // Finance routes
  static const expense = _ExpenseRoute();

  // User routes
  static const users = _UsersRoute();

  // Notification routes
  static const notify = _NotifyRoute();

  // Report routes
  static const report = _ReportRoute();
  static const profitLossReport = _ProfitLossReportRoute();
  static const productStockReport = _ProductStockReportRoute();

  /// Get all routes as a list
  static List<RoutePath> get allRoutes => [
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

  /// Find route by path string
  static RoutePath? fromPath(String path) {
    try {
      return allRoutes.firstWhere((route) => route.path == path);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => path;
}

// ============== Route Implementations ==============

final class _SplashRoute extends RoutePath {
  const _SplashRoute() : super(path: '/splash', name: 'Splash', requiresAuth: false);
}

final class _OnBoardingRoute extends RoutePath {
  const _OnBoardingRoute() : super(path: '/onBoarding', name: 'OnBoarding', requiresAuth: false);
}

final class _LoginRoute extends RoutePath {
  const _LoginRoute() : super(path: '/login', name: 'Login', requiresAuth: false);
}

final class _LayoutRoute extends RoutePath {
  const _LayoutRoute() : super(path: '/layout', name: 'Layout');
}

final class _HomeRoute extends RoutePath {
  const _HomeRoute() : super(path: '/home', name: 'Home');
}

final class _ProductsRoute extends RoutePath {
  const _ProductsRoute() : super(path: '/products', name: 'Products');
}

final class _CategoriesRoute extends RoutePath {
  const _CategoriesRoute() : super(path: '/Categories', name: 'Categories');
}

final class _BrandsRoute extends RoutePath {
  const _BrandsRoute() : super(path: '/brands', name: 'Brands');
}

final class _UnitsRoute extends RoutePath {
  const _UnitsRoute() : super(path: '/units', name: 'Units');
}

final class _WarrantiesRoute extends RoutePath {
  const _WarrantiesRoute() : super(path: '/products/warranties', name: 'Warranties');
}

final class _PosRoute extends RoutePath {
  const _PosRoute() : super(path: '/pos', name: 'POS');
}

final class _OnlinePosRoute extends RoutePath {
  const _OnlinePosRoute() : super(path: '/online_pos', name: 'Online POS');
}

final class _CartRoute extends RoutePath {
  const _CartRoute() : super(path: '/cart', name: 'Cart');
}

final class _CheckoutRoute extends RoutePath {
  const _CheckoutRoute() : super(path: '/checkout', name: 'Checkout');
}

final class _SaleRoute extends RoutePath {
  const _SaleRoute() : super(path: '/sale', name: 'Sales');
}

final class _ShipmentRoute extends RoutePath {
  const _ShipmentRoute() : super(path: '/shipment', name: 'Shipment');
}

final class _CustomerRoute extends RoutePath {
  const _CustomerRoute() : super(path: '/customer', name: 'Customer');
}

final class _LeadsRoute extends RoutePath {
  const _LeadsRoute() : super(path: '/leads', name: 'Leads');
}

final class _ContactPaymentRoute extends RoutePath {
  const _ContactPaymentRoute() : super(path: '/contactPayment', name: 'Contact Payment');
}

final class _FollowUpRoute extends RoutePath {
  const _FollowUpRoute() : super(path: '/followUp', name: 'Follow Up');
}

final class _FieldForceRoute extends RoutePath {
  const _FieldForceRoute() : super(path: '/fieldForce', name: 'Field Force');
}

final class _PurchasesRoute extends RoutePath {
  const _PurchasesRoute() : super(path: '/purchases', name: 'Purchases');
}

final class _AddPurchasesRoute extends RoutePath {
  const _AddPurchasesRoute() : super(path: '/add_purchases', name: 'Add Purchases');
}

final class _ProductsSelectionRoute extends RoutePath {
  const _ProductsSelectionRoute() : super(path: '/products_selection', name: 'Products Selection');
}

final class _PurchaseCheckoutRoute extends RoutePath {
  const _PurchaseCheckoutRoute() : super(path: '/purchase_checkout', name: 'Purchase Checkout');
}

final class _ExpenseRoute extends RoutePath {
  const _ExpenseRoute() : super(path: '/expense', name: 'Expense');
}

final class _UsersRoute extends RoutePath {
  const _UsersRoute() : super(path: '/users', name: 'Users');
}

final class _NotifyRoute extends RoutePath {
  const _NotifyRoute() : super(path: '/notify', name: 'Notifications');
}

final class _ReportRoute extends RoutePath {
  const _ReportRoute() : super(path: '/report', name: 'Reports');
}

final class _ProfitLossReportRoute extends RoutePath {
  const _ProfitLossReportRoute() : super(path: '/profit_loss_report', name: 'Profit & Loss');
}

final class _ProductStockReportRoute extends RoutePath {
  const _ProductStockReportRoute() : super(path: '/product_stock_report', name: 'Product Stock');
}
