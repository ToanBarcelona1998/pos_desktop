import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../pos_state.dart';

/// POS cart widget
class PosCartWidget extends StatelessWidget {
  final ContactEntity? customer;
  final List<CartItem> cartItems;
  final String currencySymbol;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final VoidCallback? onCustomerSelect;
  final void Function(int productId, int variationId, int quantity)?
      onQuantityChanged;
  final void Function(int productId, int variationId)? onRemoveItem;

  const PosCartWidget({
    super.key,
    this.customer,
    required this.cartItems,
    this.currencySymbol = '\$',
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    this.onCustomerSelect,
    this.onQuantityChanged,
    this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // Customer selector
          _CustomerSelectorSection(
            customer: customer,
            onSelect: onCustomerSelect,
            l10n: l10n,
            theme: theme,
          ),
          const Divider(height: 1),
          // Cart items
          Expanded(
            child: cartItems.isEmpty
                ? _EmptyCart(l10n: l10n)
                : _CartItemsList(
                    cartItems: cartItems,
                    currencySymbol: currencySymbol,
                    onQuantityChanged: onQuantityChanged,
                    onRemoveItem: onRemoveItem,
                  ),
          ),
          const Divider(height: 1),
          // Summary
          _CartSummary(
            subtotal: subtotal,
            discount: discount,
            tax: tax,
            total: total,
            currencySymbol: currencySymbol,
            l10n: l10n,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _CustomerSelectorSection extends StatelessWidget {
  final ContactEntity? customer;
  final VoidCallback? onSelect;
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _CustomerSelectorSection({
    this.customer,
    this.onSelect,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Icon(Icons.person, color: theme.colorScheme.primary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer?.name ??
                        (l10n?.translate(LocaleKeys.selectCustomer) ??
                            'Select Customer'),
                    style: AppTypography.titleMedium,
                  ),
                  if (customer?.mobile != null)
                    Text(
                      customer!.mobile!,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final AppLocalizations? l10n;

  const _EmptyCart({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n?.translate(LocaleKeys.cartEmpty) ?? 'Cart is empty',
            style: AppTypography.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final List<CartItem> cartItems;
  final String currencySymbol;
  final void Function(int productId, int variationId, int quantity)?
      onQuantityChanged;
  final void Function(int productId, int variationId)? onRemoveItem;

  const _CartItemsList({
    required this.cartItems,
    required this.currencySymbol,
    this.onQuantityChanged,
    this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: AppSpacing.paddingSm,
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final productId = item.productId;
        final productName =
            item.product.displayName ?? item.product.productName ?? 'Product';

        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      onQuantityChanged?.call(
                        productId,
                        item.variationId,
                        item.quantity - 1,
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(AppSpacing.xxs),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                      onQuantityChanged?.call(
                        productId,
                        item.variationId,
                        item.quantity + 1,
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(AppSpacing.xxs),
                  ),
                ],
              ),
              // Line total
              SizedBox(
                width: 80,
                child: Text(
                  '$currencySymbol${item.lineTotal.toStringAsFixed(2)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // Remove button
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                onPressed: () {
                  onRemoveItem?.call(productId, item.variationId);
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.all(AppSpacing.xxs),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String currencySymbol;
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _CartSummary({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.currencySymbol,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: l10n?.translate('Subtotal') ?? 'Subtotal',
            value: '$currencySymbol${subtotal.toStringAsFixed(2)}',
          ),
          if (discount > 0)
            _SummaryRow(
              label: l10n?.translate(LocaleKeys.discount) ?? 'Discount',
              value: '-$currencySymbol${discount.toStringAsFixed(2)}',
              valueColor: Colors.red,
            ),
          if (tax > 0)
            _SummaryRow(
              label: l10n?.translate(LocaleKeys.tax) ?? 'Tax',
              value: '$currencySymbol${tax.toStringAsFixed(2)}',
            ),
          SizedBox(height: AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.translate(LocaleKeys.total) ?? 'Total',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currencySymbol${total.toStringAsFixed(2)}',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

