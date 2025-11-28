import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/home/widgets/greeting_widget.dart';
import 'package:pos_final/pages/home/widgets/statistics_widget.dart';
import 'package:pos_final/pages/home/widgets/sidebar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late HomeLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = HomeLogic(this);
    _logic.initState();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 1200 ? 32.0 : 24.0; // Responsive padding for desktop

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4, // Added slight elevation for professional look
        title: Row(
          children: [
            const Icon(FontAwesomeIcons.chartPie, color: Colors.white, size: 28), // Increased icon size
            const SizedBox(width: 12),
            Text(
              localizations?.translate('home') ?? 'Home',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24, // Increased font size for desktop
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.sync, color: Colors.orange, size: 28),
            tooltip: localizations?.translate('sync') ?? 'Sync',
            onPressed: () => _logic.sync(context),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.signOutAlt, color: Colors.redAccent, size: 28),
            tooltip: localizations?.translate('logout') ?? 'Logout',
            onPressed: () => _logic.handleLogout(context),
          ),
          const SizedBox(width: 24), // Increased spacing for desktop
        ],
      ),
      body: Row(
        children: [
          // السايدبار (Sidebar remains fixed width for desktop navigation)
          Sidebar(logic: _logic),
          // المحتوى الرئيسي (Main content with responsive scrolling)
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(padding), // Responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة الترحيب (Greeting card with enhanced shadow)
                    Card(
                      elevation: 8, // Increased elevation for depth
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Softer corners
                      shadowColor: Colors.black.withOpacity(0.15), // Subtle shadow
                      child: Padding(
                        padding: const EdgeInsets.all(24.0), // Increased padding inside card
                        child: GreetingWidget(
                          themeData: _logic.themeData,
                          userName: _logic.userName,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32), // Increased vertical spacing for desktop
                    // الإحصائيات (Statistics card with enhanced design)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      shadowColor: Colors.black.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Statistics(
                          themeData: _logic.themeData,
                          businessSymbol: _logic.businessSymbol,
                          totalSales: _logic.totalSales,
                          totalSalesAmount: _logic.totalSalesAmount,
                          netAmount: _logic.netAmount,
                          invoiceDue: _logic.invoiceDue,
                          totalSellReturn: _logic.totalSellReturn,
                          totalPurchase: _logic.totalPurchase,
                          purchaseDue: _logic.purchaseDue,
                          totalPurchaseReturn: _logic.totalPurchaseReturn,
                          totalExpense: _logic.totalExpense,
                          stockAlerts: _logic.stockAlerts,
                          purchaseDues: _logic.purchaseDues,
                          salesDues: _logic.salesDues,
                          dashboardData: _logic.dashboardData,
                          businessLocations: _logic.businessLocations,
                          selectedLocationId: _logic.selectedLocationId,
                          homeLogic: _logic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // تفاصيل الدفع (Payment details card with similar enhancements)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      shadowColor: Colors.black.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _logic.paymentDetails(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}