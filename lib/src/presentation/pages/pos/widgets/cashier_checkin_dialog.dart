import 'package:flutter/material.dart';
import 'package:pos_final/src/core/utils/currency_input_formatter.dart';
import 'package:pos_final/src/presentation/presentation.dart';

import '../../../../core/core.dart';

/// Cashier check-in dialog
class CashierCheckInDialog extends StatefulWidget {
  final Function(double amount) onCheckIn;

  const CashierCheckInDialog({
    super.key,
    required this.onCheckIn,
  });

  @override
  State<CashierCheckInDialog> createState() => _CashierCheckInDialogState();
}

class _CashierCheckInDialogState extends State<CashierCheckInDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.tr(LocaleKeys.cashierCheckIn),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  VNCurrencyFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: l10n.tr(LocaleKeys.openingAmount),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.tr(LocaleKeys.pleaseEnterAmount);
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return l10n.tr(LocaleKeys.invalidAmount);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.tr(LocaleKeys.cancel)),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: l10n.tr(LocaleKeys.cashierCheckIn),
                    backgroundColor: AppThemes.light.primaryColor,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final amount = double.parse(_amountController.text);
                        widget.onCheckIn(amount);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
