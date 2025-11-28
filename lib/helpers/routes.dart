import 'package:flutter/material.dart';
import 'package:pos_final/helpers/bottom_nav.dart';
import 'package:pos_final/pages/brands/brands.dart';
import 'package:pos_final/pages/category_screen.dart';
import 'package:pos_final/pages/login/login_screen.dart';
import 'package:pos_final/pages/notifications/notify.dart';
import 'package:pos_final/pages/on_boarding/on_boarding.dart';
import 'package:pos_final/pages/online_pos/online_pos_screen.dart';
import 'package:pos_final/pages/product_stock_report.dart';
import 'package:pos_final/pages/profit_loss_report.dart';
import 'package:pos_final/pages/purchases/view/products_selection_screen.dart';
import 'package:pos_final/pages/purchases/view/purchase_checkout_screen.dart';
import 'package:pos_final/pages/purchases/view/purchases_screen.dart';
import 'package:pos_final/pages/units/units.dart';
import 'package:pos_final/pages/users.dart';
import 'package:pos_final/pages/home.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/warranties/warranties.dart';
import 'package:pos_final/pages/pos/pos_screen.dart';

import '../pages/cart.dart';
import '../pages/checkout/checkout.dart';
import '../pages/contact_payment.dart';
import '../pages/contacts.dart';
import '../pages/customer.dart';
import '../pages/expenses.dart';
import '../pages/field_force.dart';
import '../pages/follow_up.dart';
import '../pages/products.dart';
import '../pages/purchases/view/add_purchase_screen.dart';
import '../pages/report.dart';
import '../pages/sales.dart';
import '../pages/shipment.dart';
import '../pages/splash.dart';

class Routes {
  static generateRoute() {
    return {
      '/splash': (context) => const Splash(),
      '/onBoarding': (context) => const OnBoardingScreen(),
      '/login': (context) => const LoginScreen(),
      '/layout': (context) => const Home(),
      '/products': (context) => const Products(),
      '/Categories': (context) => const CategoryScreen(),
      '/notify': (context) => const NotificationScreen(),
      '/sale': (context) => const Sales(),
      '/pos': (context) => const PosScreen(),
      '/online_pos': (context) => const OnlinePosScreen(),
      '/cart': (context) => const Cart(),
      '/customer': (context) => const Customer(),
      '/checkout': (context) => const CheckoutScreen(),
      '/expense': (context) => const Expense(),
      '/contactPayment': (context) => const ContactPayment(),
      '/shipment': (context) => const Shipment(),
      '/leads': (context) => const Contacts(),
      '/followUp': (context) => const FollowUp(),
      '/fieldForce': (context) => const FieldForce(),
      '/purchases': (context) => const PurchasesScreen(),
      '/add_purchases': (context) => const AddPurchasesScreen(),
      '/products_selection': (context) => const ProductsSelectionScreen(),
      '/purchase_checkout': (context) => const PurchaseCheckoutScreen(),
      '/users': (context) => UsersScreen(logic: HomeLogic(HomeState())),
      '/units': (context) => UnitsPage(homeLogic: HomeLogic(HomeState())),
      '/products/warranties': (context) => WarrantiesPage(homeLogic: HomeLogic(HomeState())),
      '/brands': (context) => BrandsPage(homeLogic: HomeLogic(HomeState())),
      ReportScreen.routeName: (context) => ReportScreen(),
      ProfitLossReportScreen.routeName: (context) => const ProfitLossReportScreen(),
      ProductStockReportScreen.routeName: (context) => const ProductStockReportScreen(),
    };
  }
}