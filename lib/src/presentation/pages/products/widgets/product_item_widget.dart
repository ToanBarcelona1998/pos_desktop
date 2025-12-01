import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';

/// Product item widget for grid
class ProductItemWidget extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const ProductItemWidget({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: product.productImageUrl != null &&
                        product.productImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                        ),
                      )
                    : _buildPlaceholder(theme),
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: AppSpacing.paddingSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName ?? product.productName ?? 'No Name',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    if (product.sku != null)
                      Text(
                        product.sku!,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${(product.sellPriceIncTax ?? product.defaultSellPrice ?? 0).toStringAsFixed(2)}',
                          style: AppTypography.titleSmall.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.qtyAvailable != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStockColor(product.qtyAvailable!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.qtyAvailable!.toInt()}',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 48,
        color: theme.colorScheme.primary.withOpacity(0.5),
      ),
    );
  }

  Color _getStockColor(double quantity) {
    if (quantity <= 0) return Colors.red;
    if (quantity < 10) return Colors.orange;
    return Colors.green;
  }
}





