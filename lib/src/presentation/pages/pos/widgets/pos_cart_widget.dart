import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/constants/app_responsive.dart';
import 'package:pos_final/src/presentation/presentation.dart';
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
  final ValueChanged<String>? onProductSearch;
  final ValueChanged<String>? onSuspendSellSearch;

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
    this.onProductSearch,
    this.onSuspendSellSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    return Card(
      margin: EdgeInsets.all(rSpacing.sm),
      child: Column(
        children: [
          // Customer selector and search fields
          Padding(
            padding: rSpacing.paddingSm,
            child: Column(
              children: [
                // Customer selector
                Row(
                  children: [
                    Expanded(
                      child: _CustomerSelectorSection(
                        customer: customer,
                        onSelect: onCustomerSelect,
                        l10n: l10n,
                        theme: theme,
                      ),
                    ),
                    rSpacing.gapHorizontalSm,
                    // Product search (SKU/Product name)
                    Expanded(
                      child: _SearchField(
                        hint: '${l10n.translate(LocaleKeys.sku)} / ${l10n.translate(LocaleKeys.product)}',
                        icon: Icons.search,
                        onChanged: onProductSearch,
                        theme: theme,
                      ),
                    ),
                    rSpacing.gapHorizontalSm,
                    // Suspend sell search
                    Expanded(
                      child: _SearchField(
                        hint: '${l10n.translate(LocaleKeys.suspendedSales)} (ID / ${l10n.translate(LocaleKeys.invoiceNo)})',
                        icon: Icons.pause_circle_outline,
                        onChanged: onSuspendSellSearch,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.black.withAlpha((255 * 0.1).round())),
          // Cart items
          // Table header
          Container(
            padding: rSpacing.paddingSm,
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
                    style: rTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Quantity column
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.translate(LocaleKeys.quantity),
                    style: rTypography.bodyMedium.copyWith(
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
                    style: rTypography.bodyMedium.copyWith(
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
                    style: rTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: rSpacing.xxxl,
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
          Divider(height: 1, color: Colors.black.withAlpha((255 * 0.1).round())),
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
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    
    return InkWell(
      onTap: onSelect,
      borderRadius: AppRadius.borderRadiusSm,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: rSpacing.sm,
          vertical: rSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: context.rSizes.iconSm,
            ),
            rSpacing.gapHorizontalSm,
            Expanded(
              child: Text(
                customer?.name ?? l10n.translate(LocaleKeys.selectCustomer),
                style: rTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.primaryColor,
              size: context.rSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final ThemeData theme;

  const _SearchField({
    required this.hint,
    required this.icon,
    this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;
    
    return TextField(
      onChanged: onChanged,
      style: rTypography.bodySmall,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: rTypography.bodySmall.copyWith(
          color: theme.hintColor,
        ),
        prefixIcon: Icon(
          icon,
          size: rSizes.iconSm,
          color: theme.colorScheme.primary,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: rSpacing.sm,
          vertical: rSpacing.xs,
        ),
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
            width: 1,
          ),
        ),
        isDense: true,
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyCart({required this.l10n});

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
            Icons.shopping_cart_outlined,
            size: rSizes.illustrationXs,
            color: Colors.grey[400],
          ),
          rSpacing.gapVerticalMd,
          Text(
            l10n.translate(LocaleKeys.cartEmpty),
            style: rTypography.bodyLarge.copyWith(color: Colors.grey),
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
          Divider(height: 1, color: Colors.black.withAlpha((255 * 0.1).round())),
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
          qtyAvailable: item.product.qtyAvailable,
          enableStock: item.product.enableStock ?? false,
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
  final double? qtyAvailable;
  final bool enableStock;
  final void Function(int) onQuantityChanged;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _CartItemRow({
    required this.productName,
    required this.quantity,
    required this.priceAfterTax,
    required this.pricePay,
    required this.currencySymbol,
    this.qtyAvailable,
    this.enableStock = false,
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
      _quantityController.text = widget.quantity.toString();
      return;
    }

    // Validate stock if enabled
    if (widget.enableStock && widget.qtyAvailable != null) {
      final available = widget.qtyAvailable!;
      if (available <= 0) {
        // Reset to current quantity if out of stock
        _quantityController.text = widget.quantity.toString();
        return;
      }
      if (parsed > available) {
        // Cap at available stock
        _quantityController.text = available.toInt().toString();
        widget.onQuantityChanged(available.toInt());
        return;
      }
    }

    if (parsed != widget.quantity) {
      widget.onQuantityChanged(parsed);
    }
  }

  void _onMinusQuantity() {
    final text = _quantityController.text.trim();
    int parsed = int.tryParse(text) ?? widget.quantity;

    if (parsed > 1) {
      parsed--;
      _quantityController.text = parsed.toString();
      widget.onQuantityChanged(parsed);
    }
    // If already at 1, don't do anything (can't go below 1)
  }

  void _onPlusQuantity() {
    final text = _quantityController.text.trim();
    int parsed = int.tryParse(text) ?? widget.quantity;

    // Validate stock if enabled
    if (widget.enableStock && widget.qtyAvailable != null) {
      final available = widget.qtyAvailable!;
      if (available <= 0) {
        // Out of stock, don't increment
        return;
      }
      if (parsed >= available) {
        // Already at max stock, don't increment
        return;
      }
    }

    parsed++;
    _quantityController.text = parsed.toString();
    widget.onQuantityChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;
    
    return Container(
      padding: rSpacing.paddingSm,
      child: Row(
        children: [
          // Product column
          Expanded(
            flex: 4,
            child: Text(
              widget.productName,
              style: rTypography.bodyMedium.copyWith(color: Colors.lightBlue),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Quantity column
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: widget.quantity > 1 ? _onMinusQuantity : null,
                  padding: EdgeInsets.symmetric(horizontal: rSpacing.xxs),
                  icon: Text(
                    '-',
                    style: rTypography.titleLarge.copyWith(
                      color: widget.quantity > 1 ? Colors.red : Colors.grey,
                    ),
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
                        horizontal: rSpacing.xs,
                        vertical: rSpacing.xxs,
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
                    style: rTypography.bodyMedium,
                    onSubmitted: (_) {
                      _validateAndUpdateQuantity();
                      _quantityFocusNode.unfocus();
                    },
                  ),
                ),
                Builder(
                  builder: (context) {
                    final canIncrement = !widget.enableStock ||
                        widget.qtyAvailable == null ||
                        widget.qtyAvailable! > 0 &&
                            widget.quantity < widget.qtyAvailable!;
                    return IconButton(
                      onPressed: canIncrement ? _onPlusQuantity : null,
                      padding: EdgeInsets.symmetric(horizontal: rSpacing.xxs),
                      icon: Text(
                        '+',
                        style: rTypography.titleLarge.copyWith(
                          color: canIncrement ? Colors.green : Colors.grey
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Price after tax column
          Expanded(
            flex: 2,
            child: Text(
              '${Helper().formatCurrency(widget.priceAfterTax)}${widget.currencySymbol}',
              style: rTypography.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          // Price pay column
          Expanded(
            flex: 2,
            child: Text(
              '${Helper().formatCurrency(widget.pricePay)}${widget.currencySymbol}',
              style: rTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Delete button column
          SizedBox(
            width: rSpacing.xxxl,
            child: IconButton(
              icon: Icon(
                Icons.delete,
                size: rSizes.iconSm,
                color: Colors.red,
              ),
              onPressed: widget.onDelete,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.all(rSpacing.xxs),
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
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;;
    return Container(
      padding: rSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // _SummaryRow(
          //   label: l10n.translate(LocaleKeys.subtotal),
          //   value: '${Helper().formatCurrency(subtotal)}$currencySymbol',
          // ),
          // if (discount > 0)
          //   _SummaryRow(
          //     label: l10n.translate(LocaleKeys.discount),
          //     value: '-${Helper().formatCurrency(discount)}$currencySymbol',
          //     valueColor: Colors.red,
          //   ),
          // if (tax > 0)
          //   _SummaryRow(
          //     label: l10n.translate(LocaleKeys.tax),
          //     value: '${Helper().formatCurrency(tax)}$currencySymbol',
          //   ),
          // rSpacing.gapVerticalXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate(LocaleKeys.total),
                style: rTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${Helper().formatCurrency(total)}$currencySymbol',
                style: rTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: rTypography.bodyMedium),
          Text(
            value,
            style: rTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
