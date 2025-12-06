import 'package:flutter/material.dart';
import '../../../widgets/app_button.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// POS bottom bar widget
class PosBottomBarWidget extends StatelessWidget {
  final double total;
  final String currencySymbol;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback? onCashPayment;
  final VoidCallback? onCreditPayment;
  final VoidCallback? onDraft;
  final VoidCallback? onQuotation;
  final VoidCallback? onSuspend;
  final VoidCallback? onCancel;

  const PosBottomBarWidget({
    super.key,
    required this.total,
    this.currencySymbol = '\$',
    this.isSubmitting = false,
    this.canSubmit = false,
    this.onCashPayment,
    this.onCreditPayment,
    this.onDraft,
    this.onQuotation,
    this.onSuspend,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quick action buttons
            _ActionButton(
              icon: Icons.drafts_outlined,
              label: l10n.translate(LocaleKeys.draft),
              color: Colors.lightBlue,
              onTap: onDraft,
            ),
            _ActionButton(
              icon: Icons.description_outlined,
              label: l10n.translate(LocaleKeys.quotation),
              color: Colors.orange,
              onTap: onQuotation,
            ),
            _ActionButton(
              icon: Icons.pause_circle_outline,
              label: l10n.translate(LocaleKeys.suspend),
              color: Colors.red,
              onTap: onSuspend,
            ),
            _ActionButton(
              icon: Icons.credit_card,
              label: l10n.translate(LocaleKeys.credit),
              color: Colors.purple,
              onTap: onCreditPayment,
            ),
            const SizedBox(width: AppSpacing.md),
            // Main action buttons
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MainActionButton(
                      label: l10n.translate(LocaleKeys.methods),
                      color: Colors.deepOrange,
                      icon: Icons.payment,
                      isLoading: isSubmitting,
                      onTap: canSubmit ? onCashPayment : null,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MainActionButton(
                      label: l10n.translate(LocaleKeys.cash),
                      color: Colors.green,
                      icon: Icons.payments,
                      isLoading: isSubmitting,
                      onTap: canSubmit ? onCashPayment : null,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MainActionButton(
                      label: l10n.translate(LocaleKeys.cancel),
                      color: Colors.red,
                      icon: Icons.cancel,
                      isLoading: isSubmitting,
                      onTap: canSubmit ? onCashPayment : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Total display
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${l10n.translate(LocaleKeys.totalPayable)}: $currencySymbol${total.toStringAsFixed(2)}',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: IntrinsicHeight(
                      child: AppGradientButton(
                        leading: Icon(Icons.history),
                        text: l10n.translate(LocaleKeys.history),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        onPressed: () {
                          // Show history
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusSm,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _MainActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
