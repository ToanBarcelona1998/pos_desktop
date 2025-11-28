import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/report.dart';
import 'package:pos_final/pages/units/units.dart';
import 'package:pos_final/pages/brands/brands.dart';
import 'package:pos_final/config.dart';

class Sidebar extends StatefulWidget {
  final HomeLogic logic;

  const Sidebar({super.key, required this.logic});

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Main Navigation Items
                _buildSidebarItem(context, 'home', FontAwesomeIcons.home, () {
                  setState(() => _selectedItem = 'home');
                  Navigator.pushNamedAndRemoveUntil(context, '/layout', (route) => false);
                }, isSelected: _selectedItem == 'home'),
                _buildSidebarItem(context, 'pos', FontAwesomeIcons.cashRegister, () {
                  setState(() => _selectedItem = 'pos');
                  Navigator.pushNamed(context, '/online_pos');
                }, isSelected: _selectedItem == 'online_pos'),
                // Products Dropdown
                _buildProductsDropdown(context),
                _buildSidebarItem(context, 'sales', FontAwesomeIcons.chartLine, () {
                  setState(() => _selectedItem = 'sales');
                  Navigator.pushNamed(context, '/sale');
                }, isSelected: _selectedItem == 'sales'),
                // _buildSidebarItem(context, 'purchases', FontAwesomeIcons.shoppingCart, () {
                //   setState(() => _selectedItem = 'purchases');
                //   Navigator.pushNamed(context, '/purchases');
                // }, isSelected: _selectedItem == 'purchases'),
                _buildSidebarItem(context, 'users', FontAwesomeIcons.users, () {
                  setState(() => _selectedItem = 'users');
                  Navigator.pushNamed(context, '/users');
                }, isSelected: _selectedItem == 'users'),
                const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                // Quick Actions
                _buildSidebarItem(context, 'language', FontAwesomeIcons.globe, () {
                  setState(() => _selectedItem = 'language');
                  widget.logic.showLanguageDialog(context); // تغيير إلى showLanguageDialog
                }, isSelected: _selectedItem == 'language'),
                if (widget.logic.accessExpenses)
                  _buildSidebarItem(context, 'expenses', FontAwesomeIcons.moneyBill, () {
                    setState(() => _selectedItem = 'expenses');
                    widget.logic.goToExpenses(context);
                  }, isSelected: _selectedItem == 'expenses'),
                _buildSidebarItem(context, 'contact_payment', FontAwesomeIcons.creditCard, () {
                  setState(() => _selectedItem = 'contact_payment');
                  widget.logic.navigateWithConnectivity('/contactPayment', context); // تغيير إلى navigateWithConnectivity
                }, isSelected: _selectedItem == 'contact_payment'),
                _buildSidebarItem(context, 'follow_ups', FontAwesomeIcons.userClock, () {
                  setState(() => _selectedItem = 'follow_ups');
                  widget.logic.navigateWithConnectivity('/followUp', context); // تغيير إلى navigateWithConnectivity
                }, isSelected: _selectedItem == 'follow_ups'),
                if (Config().showFieldForce)
                  _buildSidebarItem(context, 'field_force_visits', FontAwesomeIcons.users, () {
                    setState(() => _selectedItem = 'field_force_visits');
                    widget.logic.navigateWithConnectivity('/fieldForce', context); // تغيير إلى navigateWithConnectivity
                  }, isSelected: _selectedItem == 'field_force_visits'),
                _buildSidebarItem(context, 'contacts', FontAwesomeIcons.addressBook, () {
                  setState(() => _selectedItem = 'contacts');
                  widget.logic.navigateWithConnectivity('/leads', context); // تغيير إلى navigateWithConnectivity
                }, isSelected: _selectedItem == 'contacts'),
                _buildSidebarItem(context, 'reports', FontAwesomeIcons.chartBar, () {
                  setState(() => _selectedItem = 'reports');
                  widget.logic.navigateWithConnectivity(ReportScreen.routeName, context); // تغيير إلى navigateWithConnectivity
                }, isSelected: _selectedItem == 'reports'),
                const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                // Check In/Out Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.logic.checkIO(context),
                ),
                // Version
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    localizations?.translate('version') ?? 'Version',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ashal Erp',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations?.translate('manage_your_business') ?? 'Manage Your Business',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String name, IconData icon, VoidCallback? onTap, {bool isSelected = false}) {
    final localizations = AppLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white, size: 24),
          title: Text(
            localizations?.translate(name) ?? name,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          onTap: onTap,
          hoverColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildProductsDropdown(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _selectedItem?.startsWith('products_') == true
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
        child: ExpansionTile(
          leading: const Icon(FontAwesomeIcons.box, color: Colors.white, size: 24),
          title: Text(
            localizations?.translate('products') ?? 'Products',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: [
            _buildSubItem(context, 'units', FontAwesomeIcons.ruler, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnitsPage(homeLogic: widget.logic),
                ),
              );
            }, 'products_units'),
            _buildSubItem(context, 'brands', FontAwesomeIcons.copyright, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrandsPage(homeLogic: widget.logic),
                ),
              );
            }, 'products_brands'),
            _buildSubItem(context, 'warranties', FontAwesomeIcons.shield, '/products/warranties', 'products_warranties'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubItem(BuildContext context, String name, IconData icon, dynamic route, String selectedKey) {
    final localizations = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        localizations?.translate(name) ?? name,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
      onTap: route is String
          ? () {
        setState(() => _selectedItem = selectedKey);
        Navigator.pushNamed(context, route);
      }
          : () {
        setState(() => _selectedItem = selectedKey);
        route();
      },
      selected: _selectedItem == selectedKey,
      selectedTileColor: Colors.white.withOpacity(0.2),
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      hoverColor: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}