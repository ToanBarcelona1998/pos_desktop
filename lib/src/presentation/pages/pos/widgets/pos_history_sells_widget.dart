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
import '../../../widgets/icon_wrapper_widget.dart';

/// Bottom sheet for history sells (final status, view-only)
class PosHistorySellsWidget extends StatelessWidget {
  final List<SellEntity> historySells;
  final bool isLoading;
  final String currencySymbol;

  const PosHistorySellsWidget({
    super.key,
    required this.historySells,
    this.isLoading = false,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Container(
        constraints: BoxConstraints(
            maxWidth: rSizes.modalWidthXl,
            minWidth: rSizes.modalWidthXl,
            minHeight: rSizes.modalWidthMd
        ),
        padding: rSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate(LocaleKeys.previousPayments),
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
                  : historySells.isEmpty
                      ? _EmptyHistorySells(l10n: l10n)
                      : ListView.builder(
                          itemCount: historySells.length,
                          itemBuilder: (context, index) {
                            final sell = historySells[index];
                            return _HistorySellItem(
                              sell: sell,
                              currencySymbol: currencySymbol,
                              theme: theme,
                              l10n: l10n,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistorySells extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyHistorySells({required this.l10n});

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
            Icons.history,
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

class _HistorySellItem extends StatelessWidget {
  final SellEntity sell;
  final String currencySymbol;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _HistorySellItem({
    required this.sell,
    required this.currencySymbol,
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
                  '${Helper().formatCurrency(sell.invoiceAmount ?? 0)}$currencySymbol',
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
          if (sell.payments.isNotEmpty) ...[
            rSpacing.gapVerticalXs,
            Divider(height: 1),
            rSpacing.gapVerticalXs,
            Text(
              l10n.translate(LocaleKeys.paymentDetails),
              style: rTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...sell.payments.map((payment) {
              return Padding(
                padding: EdgeInsets.only(top: rSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.method ?? '',
                      style: rTypography.bodySmall,
                    ),
                    Text(
                      '${Helper().formatCurrency(payment.amount ?? 0)}$currencySymbol',
                      style: rTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

