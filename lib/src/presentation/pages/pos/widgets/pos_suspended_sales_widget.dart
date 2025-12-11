import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/presentation/presentation.dart';

import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/icon_wrapper_widget.dart';

/// Bottom sheet for suspended sales
class PosSuspendedSalesWidget extends StatelessWidget {
  final List<SellEntity> suspendedSells;
  final bool isLoading;
  final ValueChanged<SellEntity>? onContinue;
  final ValueChanged<int>? onDelete;

  const PosSuspendedSalesWidget({
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
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: rSpacing.paddingMd,
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
              Expanded(
                child: Text(
                  l10n.translate(LocaleKeys.suspendedSales),
                  style: rTypography.titleLarge,
                ),
              ),
              IconWrapper(
                icon: Icons.close,
                iconColor: theme.colorScheme.primary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          rSpacing.gapVerticalMd,
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
                              onDelete?.call(sell.id);
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
  final AppLocalizations l10n;

  const _EmptySuspendedSales({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            size: rSizes.illustrationXs,
            color: Colors.grey[400],
          ),
          rSpacing.gapVerticalMd,
          Text(
            l10n.translate(LocaleKeys.noData),
            style: rTypography.bodyLarge.copyWith(color: Colors.grey),
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
  final AppLocalizations l10n;

  const _SuspendedSaleItem({
    required this.sell,
    required this.onContinue,
    required this.onDelete,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final transactionDate = sell.transactionDate != null
        ? DateTime.tryParse(sell.transactionDate!)
        : null;

    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    final t = AppThemes.light;
    
    return AppCard(
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
                      sell.invoiceNo ?? '',
                      style: rTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (transactionDate != null)
                      Text(
                        dateFormat.format(transactionDate),
                        style: rTypography.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: rSpacing.sm,
                  vertical: rSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Text(
                  '${Helper().formatCurrency(sell.invoiceAmount)}đ',
                  style: rTypography.labelLarge.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (sell.sellLines.isNotEmpty) ...[
            rSpacing.gapVerticalXs,
            Text(
              '${sell.sellLines.length} ${l10n.translate(LocaleKeys.items)}',
              style: rTypography.bodySmall,
            ),
          ],
          rSpacing.gapVerticalSm,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.translate(LocaleKeys.continueSale),
                  icon: Icons.play_arrow,
                  onPressed: onContinue,
                  backgroundColor: t.primaryColor,
                ),
              ),
              rSpacing.gapHorizontalSm,
              AppButton(
                text: l10n.translate(LocaleKeys.delete),
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
    );
  }
}





