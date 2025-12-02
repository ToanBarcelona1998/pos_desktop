import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/icon_wrapper_widget.dart';
import '../pos_state.dart';

/// Bottom sheet for suspended sales
class PosSuspendedSalesBottomSheet extends StatelessWidget {
  final List<SellEntity> suspendedSells;
  final bool isLoading;
  final ValueChanged<SellEntity>? onContinue;
  final ValueChanged<int>? onDelete;

  const PosSuspendedSalesBottomSheet({
    super.key,
    required this.suspendedSells,
    this.isLoading = false,
    this.onContinue,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconWrapper(
                icon: Icons.pause_circle_outline,
                iconColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                onTap: null,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n?.translate(LocaleKeys.suspendedSales) ?? 'Suspended Sales',
                  style: AppTypography.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : suspendedSells.isEmpty
                    ? _EmptySuspendedSales(l10n: l10n)
                    : ListView.builder(
                        itemCount: suspendedSells.length,
                        itemBuilder: (context, index) {
                          final sell = suspendedSells[index];
                          return _SuspendedSaleItem(
                            sell: sell,
                            onContinue: () {
                              onContinue?.call(sell);
                              Navigator.of(context).pop();
                            },
                            onDelete: () {
                              onDelete?.call(sell.id ?? 0);
                            },
                            theme: theme,
                            l10n: l10n,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptySuspendedSales extends StatelessWidget {
  final AppLocalizations? l10n;

  const _EmptySuspendedSales({this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n?.translate(LocaleKeys.noData) ?? 'No suspended sales',
            style: AppTypography.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SuspendedSaleItem extends StatelessWidget {
  final SellEntity sell;
  final VoidCallback onContinue;
  final VoidCallback onDelete;
  final ThemeData theme;
  final AppLocalizations? l10n;

  const _SuspendedSaleItem({
    required this.sell,
    required this.onContinue,
    required this.onDelete,
    required this.theme,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final transactionDate = sell.transactionDate != null
        ? DateTime.tryParse(sell.transactionDate!)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sell.invoiceNo ?? 'N/A',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (transactionDate != null)
                        Text(
                          dateFormat.format(transactionDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    sell.invoiceAmount?.toStringAsFixed(0) ?? '0',
                    style: AppTypography.labelLarge.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (sell.sellLines.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                '${sell.sellLines.length} ${l10n?.translate(LocaleKeys.items) ?? 'items'}',
                style: AppTypography.bodySmall,
              ),
            ],
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: l10n?.translate(LocaleKeys.continueSale) ?? 'Continue',
                    icon: Icons.play_arrow,
                    onPressed: onContinue,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: l10n?.translate(LocaleKeys.delete) ?? 'Delete',
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                  isOutlined: true,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


