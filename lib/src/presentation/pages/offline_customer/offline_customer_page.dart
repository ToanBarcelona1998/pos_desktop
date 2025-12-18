import 'package:flutter/material.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/constants/app_responsive.dart';
import 'package:pos_final/src/core/constants/app_radius.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/core/localization/app_localization.dart';
import 'package:pos_final/src/core/localization/locale_keys.dart';
import 'package:pos_final/src/core/services/cart_sync_service.dart';
import 'package:pos_final/src/presentation/presentation.dart';

class OfflineCustomerPage extends StatefulWidget {
  const OfflineCustomerPage({super.key});

  @override
  State<OfflineCustomerPage> createState() => _OfflineCustomerPageState();
}

class _OfflineCustomerPageState extends State<OfflineCustomerPage> {
  CartSyncData? _cartData;

  @override
  void initState() {
    super.initState();
    _setupMessageHandler();
  }

  void _setupMessageHandler() {
    CartSyncService().registerCustomerWindowHandler((cartData) {
      if (mounted) {
        setState(() {
          _cartData = cartData;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final rSpacing = context.rSpacing;
      final rTypography = context.rTypography;
      final rSizes = context.rSizes;

      final scheme = AppThemes.light;

      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            l10n.translate(LocaleKeys.cart),
            style: rTypography.titleMedium.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: scheme.primaryColor,
          elevation: 0,
        ),
        body: _cartData == null || _cartData!.items.isEmpty
            ? _buildEmptyCart(l10n, rSpacing, rTypography, rSizes, scheme)
            : _buildCartContent(l10n, theme, rSpacing, rTypography, rSizes),
      );
    });
  }

  Widget _buildEmptyCart(
    AppLocalizations l10n,
    ResponsiveSpacing rSpacing,
    ResponsiveTypography rTypography,
    ResponsiveSizes rSizes,
    ThemeData schema,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: rSizes.illustrationSm,
            color: Colors.grey[500],
          ),
          rSpacing.gapVerticalMd,
          Text(
            l10n.translate(LocaleKeys.cartEmpty),
            style: rTypography.bodyMedium.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    AppLocalizations l10n,
    ThemeData theme,
    ResponsiveSpacing rSpacing,
    ResponsiveTypography rTypography,
    ResponsiveSizes rSizes,
  ) {
    if (_cartData == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Customer info (if available)
        if (_cartData!.customerName != null)
          Container(
            width: double.infinity,
            padding: rSpacing.paddingMd,
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: rSizes.iconMd,
                ),
                rSpacing.gapHorizontalSm,
                Text(
                  _cartData!.customerName!,
                  style: rTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

        // Cart items list
        Expanded(
          child: ListView.separated(
            padding: rSpacing.paddingMd,
            itemCount: _cartData!.items.length,
            separatorBuilder: (_, __) => rSpacing.gapVerticalSm,
            itemBuilder: (context, index) {
              final item = _cartData!.items[index];
              return _CartItemCard(
                item: item,
                currencySymbol: _cartData!.currencySymbol,
                l10n: l10n,
                theme: theme,
                rSpacing: rSpacing,
                rTypography: rTypography,
                rSizes: rSizes,
              );
            },
          ),
        ),

        // Summary section
        Container(
          width: double.infinity,
          padding: rSpacing.paddingLg,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Subtotal
              if (_cartData!.subtotal > 0)
                _SummaryRow(
                  label: l10n.translate(LocaleKeys.subtotal),
                  value:
                      '${Helper().formatCurrency(_cartData!.subtotal)}${_cartData!.currencySymbol}',
                  rTypography: rTypography,
                ),
              // Discount
              if (_cartData!.discount > 0)
                _SummaryRow(
                  label: l10n.translate(LocaleKeys.discount),
                  value:
                      '-${Helper().formatCurrency(_cartData!.discount)}${_cartData!.currencySymbol}',
                  valueColor: Colors.red,
                  rTypography: rTypography,
                ),
              // Tax
              if (_cartData!.tax > 0)
                _SummaryRow(
                  label: l10n.translate(LocaleKeys.tax),
                  value:
                      '${Helper().formatCurrency(_cartData!.tax)}${_cartData!.currencySymbol}',
                  rTypography: rTypography,
                ),
              rSpacing.gapVerticalSm,
              Divider(height: 1, color: Colors.grey[300]),
              rSpacing.gapVerticalSm,
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate(LocaleKeys.total),
                    style: rTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${Helper().formatCurrency(_cartData!.total)}${_cartData!.currencySymbol}',
                    style: rTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              rSpacing.gapVerticalXs,
              Text(
                '${l10n.translate(LocaleKeys.totalItems)}: ${_cartData!.totalItems}',
                style: rTypography.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartSyncItem item;
  final String currencySymbol;
  final AppLocalizations l10n;
  final ThemeData theme;
  final ResponsiveSpacing rSpacing;
  final ResponsiveTypography rTypography;
  final ResponsiveSizes rSizes;

  const _CartItemCard({
    required this.item,
    required this.currencySymbol,
    required this.l10n,
    required this.theme,
    required this.rSpacing,
    required this.rTypography,
    required this.rSizes,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: rSpacing.paddingMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (item.productImageUrl != null && item.productImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: AppRadius.borderRadiusSm,
              child: Image.network(
                item.productImageUrl!,
                width: rSizes.illustrationSm,
                height: rSizes.illustrationSm,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              ),
            )
          else
            _buildPlaceholderImage(),
          rSpacing.gapHorizontalMd,

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName ?? item.productName,
                  style: rTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                rSpacing.gapVerticalXs,
                Row(
                  children: [
                    Text(
                      '${l10n.translate(LocaleKeys.quantity)}: ',
                      style: rTypography.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: rTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    rSpacing.gapHorizontalMd,
                    Text(
                      '${l10n.translate(LocaleKeys.priceAfterTax)}: ',
                      style: rTypography.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${Helper().formatCurrency(item.unitPrice)}$currencySymbol',
                      style: rTypography.bodyMedium,
                    ),
                  ],
                ),
                if (item.discountAmount > 0) ...[
                  rSpacing.gapVerticalXs,
                  Text(
                    '${l10n.translate(LocaleKeys.discount)}: ${item.discountType == 'percentage' ? '${item.discountAmount}%' : '${Helper().formatCurrency(item.discountAmount)}$currencySymbol'}',
                    style: rTypography.bodySmall.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Line total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Helper().formatCurrency(item.lineTotal)}$currencySymbol',
                style: rTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: rSizes.illustrationSm,
      height: rSizes.illustrationSm,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Icon(
        Icons.image_not_supported,
        size: rSizes.iconMd,
        color: Colors.grey[400],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final ResponsiveTypography rTypography;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.rTypography,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: rTypography.bodyMedium,
          ),
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
