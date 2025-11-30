import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/navigation/route_path.dart';

/// Home page drawer
class HomeDrawerWidget extends StatelessWidget {
  final String userName;
  final String businessName;
  final VoidCallback? onLogout;

  const HomeDrawerWidget({
    super.key,
    required this.userName,
    required this.businessName,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: AppSizes.avatarMd / 2,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  userName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  businessName,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          _DrawerMenuItem(
            icon: Icons.dashboard,
            title: l10n?.translate(LocaleKeys.dashboard) ?? 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerMenuItem(
            icon: Icons.point_of_sale,
            title: l10n?.translate(LocaleKeys.pos) ?? 'POS',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.pos.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.inventory,
            title: l10n?.translate(LocaleKeys.products) ?? 'Products',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.products.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.receipt_long,
            title: l10n?.translate(LocaleKeys.sales) ?? 'Sales',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.sale.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.shopping_bag,
            title: l10n?.translate(LocaleKeys.purchases) ?? 'Purchases',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.purchases.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.people,
            title: l10n?.translate(LocaleKeys.contacts) ?? 'Contacts',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.customer.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.payment,
            title: l10n?.translate(LocaleKeys.expenses) ?? 'Expenses',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.expense.path);
            },
          ),
          const Divider(),
          _DrawerMenuItem(
            icon: Icons.bar_chart,
            title: l10n?.translate(LocaleKeys.reports) ?? 'Reports',
            onTap: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(RoutePath.report.path);
            },
          ),
          _DrawerMenuItem(
            icon: Icons.settings,
            title: l10n?.translate(LocaleKeys.settings) ?? 'Settings',
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          const Divider(),
          _DrawerMenuItem(
            icon: Icons.logout,
            title: l10n?.translate(LocaleKeys.logout) ?? 'Logout',
            iconColor: theme.colorScheme.error,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, l10n, onLogout);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AppLocalizations? l10n,
    VoidCallback? onLogout,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.translate(LocaleKeys.logout) ?? 'Logout'),
        content: Text(l10n?.translate(LocaleKeys.areYouSure) ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.translate(LocaleKeys.cancel) ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout?.call();
              AppNavigator.navigateToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n?.translate(LocaleKeys.logout) ?? 'Logout'),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: AppTypography.bodyLarge),
      onTap: onTap,
    );
  }
}



