import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import 'product_item_widget.dart';

/// Products grid widget
class ProductsGridWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final ValueChanged<ProductEntity>? onProductTap;

  const ProductsGridWidget({
    super.key,
    required this.products,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.onLoadMore,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.extentAfter < 200 && hasMore && !isLoadingMore) {
            onLoadMore?.call();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: AppSpacing.paddingMd,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length + (isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = products[index];
          return ProductItemWidget(
            product: product,
            onTap: () => onProductTap?.call(product),
          );
        },
      ),
    );
  }
}






