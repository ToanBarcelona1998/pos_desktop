import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/constants/app_sizes.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_theme_base.dart';
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
          // Table header
          Container(
            padding: AppSpacing.paddingSm,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Product column
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.translate(LocaleKeys.product),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Quantity column
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.translate(LocaleKeys.quantity),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Price after tax column
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.translate(LocaleKeys.priceAfterTax),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                // Price pay column
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.translate(LocaleKeys.paymentAmount),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(
                  width: AppSpacing.xxxl,
                ),
              ],
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? _EmptyCart(l10n: l10n)
                : _CartItemsList(
                    cartItems: cartItems,
                    currencySymbol: currencySymbol,
                    onQuantityChanged: onQuantityChanged,
                    onRemoveItem: onRemoveItem,
                    l10n: l10n,
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
  final AppLocalizations l10n;
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
                    customer?.name ?? l10n.translate(LocaleKeys.selectCustomer),
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
            Icon(Icons.chevron_right, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final AppLocalizations l10n;

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
            l10n.translate(LocaleKeys.cartEmpty),
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
  final AppLocalizations l10n;

  const _CartItemsList({
    required this.cartItems,
    required this.currencySymbol,
    required this.l10n,
    this.onQuantityChanged,
    this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: cartItems.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final productId = item.productId;
        final productName = item.product.displayName ??
            item.product.productName ??
            l10n.translate(LocaleKeys.product);

        return _CartItemRow(
          productName: productName,
          quantity: item.quantity,
          priceAfterTax: item.unitPrice,
          pricePay: item.lineTotal,
          currencySymbol: currencySymbol,
          onQuantityChanged: (newQuantity) {
            onQuantityChanged?.call(productId, item.variationId, newQuantity);
          },
          onDelete: () {
            onRemoveItem?.call(productId, item.variationId);
          },
          theme: theme,
        );
      },
    );
  }
}

class _CartItemRow extends StatefulWidget {
  final String productName;
  final int quantity;
  final double priceAfterTax;
  final double pricePay;
  final String currencySymbol;
  final void Function(int) onQuantityChanged;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _CartItemRow({
    required this.productName,
    required this.quantity,
    required this.priceAfterTax,
    required this.pricePay,
    required this.currencySymbol,
    required this.onQuantityChanged,
    required this.onDelete,
    required this.theme,
  });

  @override
  State<_CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<_CartItemRow> {
  late TextEditingController _quantityController;
  late FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.quantity.toString());
    _quantityFocusNode = FocusNode();
    _quantityFocusNode.addListener(() {
      if (!_quantityFocusNode.hasFocus) {
        _validateAndUpdateQuantity();
      }
    });
  }

  @override
  void didUpdateWidget(_CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && !_quantityFocusNode.hasFocus) {
      _quantityController.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _validateAndUpdateQuantity() {
    final text = _quantityController.text.trim();
    if (text.isEmpty) {
      _quantityController.text = '1';
      widget.onQuantityChanged(1);
      return;
    }

    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1) {
      _quantityController.text = '1';
      widget.onQuantityChanged(1);
    } else if (parsed != widget.quantity) {
      widget.onQuantityChanged(parsed);
    }
  }

  void _onMinusQuantity(){
    final text = _quantityController.text.trim();

    int parsed = int.tryParse(text) ?? 1;

    if(parsed > 1){
      parsed--;
    }else{
      parsed = 1;
    }
    _quantityController.text = parsed.toString();
    widget.onQuantityChanged(parsed);
  }

  void _onPlusQuantity(){
    final text = _quantityController.text.trim();

    int parsed = int.tryParse(text) ?? 1;

    parsed ++;

    _quantityController.text = parsed.toString();
    widget.onQuantityChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingSm,
      child: Row(
        children: [
          // Product column
          Expanded(
            flex: 4,
            child: Text(
              widget.productName,
              style: AppTypography.bodyMedium.copyWith(color: Colors.lightBlue),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Quantity column
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: _onMinusQuantity,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs
                  ),
                  icon: Icon(
                    Icons.minimize,
                    size: AppSizes.iconSm,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderRadiusXs,
                        borderSide: BorderSide(
                          color: widget.theme.dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderRadiusXs,
                        borderSide: BorderSide(
                          color: widget.theme.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderRadiusXs,
                        borderSide: BorderSide(
                          color: widget.theme.colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      isDense: true,
                    ),
                    style: AppTypography.bodyMedium,
                    onSubmitted: (_) {
                      _validateAndUpdateQuantity();
                      _quantityFocusNode.unfocus();
                    },
                  ),
                ),
                IconButton(
                  onPressed: _onPlusQuantity,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs
                  ),
                  icon: Icon(
                    Icons.minimize,
                    size: AppSizes.iconSm,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Price after tax column
          Expanded(
            flex: 2,
            child: Text(
              '${Helper().formatCurrency(widget.priceAfterTax)}${widget.currencySymbol}',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          // Price pay column
          Expanded(
            flex: 2,
            child: Text(
              '${Helper().formatCurrency(widget.pricePay)}${widget.currencySymbol}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Delete button column
          SizedBox(
            width: AppSpacing.xxxl,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: widget.theme.colorScheme.error,
              ),
              onPressed: widget.onDelete,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.all(AppSpacing.xxs),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String currencySymbol;
  final AppLocalizations l10n;
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
    final appColor = AppThemes.light;
    final gradient = LinearGradient(
      colors: [
        appColor.primaryColor,
        appColor.primaryColor.withAlpha((0.8 * 255).round()),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
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
            label: l10n.translate(LocaleKeys.subtotal),
            value: '${Helper().formatCurrency(subtotal)}$currencySymbol',
          ),
          if (discount > 0)
            _SummaryRow(
              label: l10n.translate(LocaleKeys.discount),
              value: '-${Helper().formatCurrency(discount)}$currencySymbol',
              valueColor: Colors.red,
            ),
          if (tax > 0)
            _SummaryRow(
              label: l10n.translate(LocaleKeys.tax),
              value: '${Helper().formatCurrency(tax)}$currencySymbol',
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
              gradient: gradient,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate(LocaleKeys.total),
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${Helper().formatCurrency(total)}$currencySymbol',
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
