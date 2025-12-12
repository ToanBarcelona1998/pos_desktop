import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/presentation/widgets/icon_wrapper_widget.dart';
import '../../../presentation.dart';

/// Payment method selection dialog
class PosPaymentMethodDialog extends StatefulWidget {
  final List<PaymentAccountEntity> eWalletAccounts;
  final List<PaymentAccountEntity> bankTransferAccounts;
  final double total;
  final String currencySymbol;

  const PosPaymentMethodDialog({
    super.key,
    required this.eWalletAccounts,
    required this.bankTransferAccounts,
    required this.total,
    required this.currencySymbol,
  });

  @override
  State<PosPaymentMethodDialog> createState() => _PosPaymentMethodDialogState();
}

class _PosPaymentMethodDialogState extends State<PosPaymentMethodDialog> {
  PaymentMethod? selectedPaymentType;
  PaymentAccountEntity? selectedAccount;

  @override
  void initState() {
    super.initState();
    // Default to first available type
    if (widget.eWalletAccounts.isNotEmpty) {
      selectedPaymentType = PaymentMethod.eWallet;
      selectedAccount = widget.eWalletAccounts.first;
    } else if (widget.bankTransferAccounts.isNotEmpty) {
      selectedPaymentType = PaymentMethod.bankTransfer;
      selectedAccount = widget.bankTransferAccounts.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    final light = AppThemes.light;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: BoxConstraints(
            maxWidth: rSizes.modalWidthXl,
            minWidth: rSizes.modalWidthXl,
            minHeight: rSizes.modalWidthMd
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          l10n.translate(LocaleKeys.selectPaymentMethod),
                          style: rTypography.headlineLarge,
                        ),
                        const Spacer(),
                        IconWrapper(
                          icon: Icons.close,
                          iconColor: Colors.black,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    rSpacing.gapVerticalMd,

                    // Payment Type Selection
                    Text(
                      l10n.translate(LocaleKeys.paymentType),
                      style: rTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    rSpacing.gapVerticalSm,

                    RadioGroup<PaymentMethod>(
                      onChanged: (method){
                        setState(() {
                          selectedPaymentType = method;

                          if(selectedPaymentType == PaymentMethod.eWallet && widget.eWalletAccounts.isNotEmpty){
                            selectedAccount = widget.eWalletAccounts.first;
                          }
                          else if (widget.bankTransferAccounts.isNotEmpty) {
                            selectedAccount = widget.bankTransferAccounts.first;
                          }
                        });
                      },
                      groupValue: selectedPaymentType,
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: PaymentMethod.eWallet,
                                ),
                                Text(l10n.translate(LocaleKeys.eWallet)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: PaymentMethod.bankTransfer,
                                ),
                                Text(l10n.translate(LocaleKeys.bankTransfer)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    rSpacing.gapVerticalLg,

                    // Account Selection
                    if (selectedPaymentType != null) ...[
                      Text(
                        l10n.translate(LocaleKeys.selectAccount),
                        style: rTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      rSpacing.gapVerticalSm,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAccountSelection(),
                          if (selectedAccount != null &&
                              selectedAccount?.cachedImagePath != null) ...[
                            rSpacing.gapVerticalLg,
                            Image.file(
                              File(selectedAccount!.cachedImagePath!),
                              width: rSizes.modalWidthSm,
                              height: rSizes.modalWidthSm,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                            )
                          ]
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            rSpacing.gapVerticalLg,

            // Total
            Container(
              padding: EdgeInsets.all(rSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate(LocaleKeys.total),
                    style: rTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Helper().formatCurrency(widget.total)}${widget.currencySymbol}',
                    style: rTypography.headlineLarge.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            rSpacing.gapVerticalMd,

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    text: l10n.translate(LocaleKeys.cancel),
                    onPressed: () => AppNavigator.pop(),
                  ),
                ),
                rSpacing.gapHorizontalSm,
                Expanded(
                  child: AppButton(
                    backgroundColor: light.primaryColor,
                    text: l10n.translate(
                      LocaleKeys.confirm,
                    ),
                    onPressed: selectedAccount != null
                        ? () {
                            final paymentMethod =
                                selectedPaymentType == PaymentMethod.eWallet
                                    ? PaymentMethod.eWallet
                                    : PaymentMethod.bankTransfer;

                            context.read<PosBloc>().add(
                                  PosSubmitSale(
                                    paymentMethod: paymentMethod,
                                    paymentAccount: selectedAccount,
                                  ),
                                );

                            AppNavigator.pop();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelection() {
    final accounts = selectedPaymentType == PaymentMethod.eWallet
        ? widget.eWalletAccounts
        : widget.bankTransferAccounts;

    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }
    // Multiple accounts - dropdown
    final theme = Theme.of(context);
    return DropdownButtonFormField<PaymentAccountEntity>(
      initialValue: selectedAccount,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.rSpacing.md,
          vertical: context.rSpacing.sm,
        ),
      ),
      style: context.rTypography.bodyMedium.copyWith(color: Colors.black),
      selectedItemBuilder: (context) {
        return accounts.map((account) {
          return Text(
            account.name,
            overflow: TextOverflow.ellipsis,
            style: context.rTypography.bodyMedium,
          );
        }).toList();
      },
      items: accounts.map((account) {
        return DropdownMenuItem<PaymentAccountEntity>(
          value: account,
          child: Text(
            account.name,
            overflow: TextOverflow.ellipsis,
            style: context.rTypography.bodyMedium.copyWith(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (account) {
        setState(() {
          selectedAccount = account;
        });
      },
    );
  }
}