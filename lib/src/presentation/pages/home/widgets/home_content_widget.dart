import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/navigation/route_path.dart';
import '../../../widgets/app_card.dart';
import '../home_state.dart';

/// Home page content
class HomeContentWidget extends StatelessWidget {
  final HomeState state;

  const HomeContentWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics
        Text(
          l10n?.translate(LocaleKeys.overview) ?? 'Overview',
          style: AppTypography.headlineSmall,
        ),
        SizedBox(height: AppSpacing.md),
        _StatisticsGrid(state: state, l10n: l10n),
        SizedBox(height: AppSpacing.xl),
        // Quick actions
        Text(
          l10n?.translate(LocaleKeys.quickActions) ?? 'Quick Actions',
          style: AppTypography.headlineSmall,
        ),
        SizedBox(height: AppSpacing.md),
        _QuickActionsGrid(l10n: l10n),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final HomeState state;
  final AppLocalizations? l10n;

  const _StatisticsGrid({
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        AppStatCard(
          title: l10n?.translate(LocaleKeys.totalSales) ?? 'Total Sales',
          value: '\$${state.totalSales.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          iconColor: theme.colorScheme.primary,
        ),
        AppStatCard(
          title: l10n?.translate(LocaleKeys.totalPurchase) ?? 'Total Purchase',
          value: '\$${state.totalPurchase.toStringAsFixed(2)}',
          icon: Icons.shopping_cart,
          iconColor: Colors.orange,
        ),
        AppStatCard(
          title: l10n?.translate(LocaleKeys.totalExpense) ?? 'Total Expenses',
          value: '\$${state.totalExpenses.toStringAsFixed(2)}',
          icon: Icons.money_off,
          iconColor: Colors.red,
        ),
        AppStatCard(
          title: l10n?.translate(LocaleKeys.numberOfSales) ?? 'No. of Sales',
          value: state.numberOfSales.toString(),
          icon: Icons.receipt_long,
          iconColor: Colors.green,
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final AppLocalizations? l10n;

  const _QuickActionsGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [
        _QuickActionItem(
          icon: Icons.point_of_sale,
          label: l10n?.translate(LocaleKeys.pos) ?? 'POS',
          color: theme.colorScheme.primary,
          onTap: () => AppNavigator.pushNamed(RoutePath.pos.path),
        ),
        _QuickActionItem(
          icon: Icons.add_shopping_cart,
          label: l10n?.translate(LocaleKeys.addPurchase) ?? 'Add Purchase',
          color: Colors.orange,
          onTap: () => AppNavigator.pushNamed(RoutePath.addPurchases.path),
        ),
        _QuickActionItem(
          icon: Icons.person_add,
          label: l10n?.translate(LocaleKeys.createContact) ?? 'Add Contact',
          color: Colors.green,
          onTap: () => AppNavigator.pushNamed(RoutePath.customer.path),
        ),
        _QuickActionItem(
          icon: Icons.receipt,
          label: l10n?.translate(LocaleKeys.sales) ?? 'Sales',
          color: Colors.blue,
          onTap: () => AppNavigator.pushNamed(RoutePath.sale.path),
        ),
        _QuickActionItem(
          icon: Icons.inventory_2,
          label: l10n?.translate(LocaleKeys.products) ?? 'Products',
          color: Colors.purple,
          onTap: () => AppNavigator.pushNamed(RoutePath.products.path),
        ),
        _QuickActionItem(
          icon: Icons.bar_chart,
          label: l10n?.translate(LocaleKeys.reports) ?? 'Reports',
          color: Colors.teal,
          onTap: () => AppNavigator.pushNamed(RoutePath.report.path),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.paddingXs,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}




