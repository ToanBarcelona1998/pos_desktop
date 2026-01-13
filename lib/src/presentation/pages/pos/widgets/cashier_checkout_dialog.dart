import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/src/presentation/presentation.dart';

import '../../../../../helpers/other_helpers.dart';
import '../../../../core/core.dart';

/// Cashier check-out dialog
class CashierCheckOutDialog extends StatefulWidget {
  final CashierSessionEntity session;
  final String cashierName;
  final String locationName;
  final Function({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  }) onCheckOut;

  const CashierCheckOutDialog({
    super.key,
    required this.session,
    required this.cashierName,
    required this.locationName,
    required this.onCheckOut,
  });

  @override
  State<CashierCheckOutDialog> createState() => _CashierCheckOutDialogState();
}

class _CashierCheckOutDialogState extends State<CashierCheckOutDialog> {
  final Map<String, TextEditingController> _denominationControllers = {};
  final _noteController = TextEditingController();

  // Vietnamese banknotes (1000 to 500000)
  static const List<int> _denominations = [
    500000,
    200000,
    100000,
    50000,
    20000,
    10000,
    5000,
    2000,
    1000,
  ];

  @override
  void initState() {
    super.initState();
    for (final denom in _denominations) {
      _denominationControllers[denom.toString()] = TextEditingController(
        text:
            widget.session.denominations?[denom.toString()]?.toString() ?? '0',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _denominationControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0;
    for (final entry in _denominationControllers.entries) {
      final denom = int.tryParse(entry.key) ?? 0;
      final count = int.tryParse(entry.value.text) ?? 0;
      total += denom * count;
    }
    return total;
  }

  Map<String, int> _getDenominations() {
    final Map<String, int> result = {};
    for (final entry in _denominationControllers.entries) {
      final count = int.tryParse(entry.value.text) ?? 0;
      if (count > 0) {
        result[entry.key] = count;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;
    final helper = Helper();
    final totalAmount = _calculateTotal();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tr(LocaleKeys.currentSession),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Total amount display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tr(LocaleKeys.closingAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    helper.formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Denominations list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _denominations.map((denom) {
                    final controller =
                        _denominationControllers[denom.toString()]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              helper.formatCurrency(denom.toDouble()),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.tr(LocaleKeys.count),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              helper.formatCurrency(
                                (int.tryParse(controller.text) ?? 0) *
                                    denom.toDouble(),
                              ),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: l10n.tr(LocaleKeys.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cashier and location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.tr(LocaleKeys.billCashier)}: ${widget.cashierName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.tr(LocaleKeys.location)}: ${widget.locationName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.tr(LocaleKeys.cancel)),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: l10n.tr(LocaleKeys.cashierCheckOut),
                  backgroundColor: AppThemes.light.primaryColor,
                  onPressed: () {
                    widget.onCheckOut(
                      closingAmount: totalAmount,
                      closingAmountOnStaff: totalAmount,
                      // Assuming all cash
                      totalCardSlips: 0,
                      // TODO: Get from payment summary
                      totalCheques: 0,
                      // TODO: Get from payment summary
                      closingNote: _noteController.text,
                      denominations: _getDenominations(),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
