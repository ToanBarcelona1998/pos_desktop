import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../core/core.dart';
import 'package:pos_final/helpers/other_helpers.dart';

class CurrencySelectionDialog extends StatelessWidget {
  final ExchangeRateEntity? exchangeRate;

  const CurrencySelectionDialog({
    super.key,
    this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr(LocaleKeys.selectCurrency),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (exchangeRate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.tr(LocaleKeys.exchangeRate)}: 1 USD = ${Helper().formatCurrency(exchangeRate!.conversionRate)} VND',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildCurrencyOption(
              context,
              currency: 'VND',
              symbol: '₫',
              label: l10n.tr(LocaleKeys.vietnameseDong),
            ),
            const SizedBox(height: 12),
            _buildCurrencyOption(
              context,
              currency: 'USD',
              symbol: '\$',
              label: l10n.tr(LocaleKeys.usDollar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context, {
    required String currency,
    required String symbol,
    required String label,
  }) {
    final theme = AppThemes.light;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(currency);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
