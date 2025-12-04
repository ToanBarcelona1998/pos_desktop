import 'package:cached_network_image/cached_network_image.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/constants/app_sizes.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_loading.dart';
import '../pos_state.dart';
import 'pos_filter_drawer.dart';

/// POS product grid widget
class PosProductGridWidget extends StatefulWidget {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List<CartItem> cartItems;
  final ValueChanged<ProductEntity>? onProductTap;
  final ValueChanged<String>? onSearch;
  final ValueChanged<int?>? onCategoryFilter;
  final ValueChanged<int?>? onBrandFilter;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;

  const PosProductGridWidget({
    super.key,
    required this.products,
    required this.categories,
    required this.brands,
    this.selectedCategoryId,
    this.selectedBrandId,
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    required this.cartItems,
    this.onProductTap,
    this.onSearch,
    this.onCategoryFilter,
    this.onBrandFilter,
    this.onLoadMore,
    this.onRefresh,
  });

  @override
  State<PosProductGridWidget> createState() => _PosProductGridWidgetState();
}

class _PosProductGridWidgetState extends State<PosProductGridWidget>
    with SingleTickerProviderStateMixin {
  bool _isFilterDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleFilterDrawer() {
    setState(() {
      _isFilterDrawerOpen = !_isFilterDrawerOpen;
      if (_isFilterDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _handleCategorySelected(int? categoryId) {
    widget.onCategoryFilter?.call(categoryId);
    _toggleFilterDrawer();
  }

  void _handleBrandSelected(int? brandId) {
    widget.onBrandFilter?.call(brandId);
    _toggleFilterDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Filter buttons
            _FilterSection(
              selectedCategoryId: widget.selectedCategoryId,
              selectedBrandId: widget.selectedBrandId,
              onFilterTap: _toggleFilterDrawer,
              l10n: l10n,
            ),
            // SizedBox(height: AppSpacing.sm),
            // // Search
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            //   child: AppSearchField(
            //     hintText: l10n?.translate(LocaleKeys.searchProducts) ?? 'Search products...',
            //     onChanged: widget.onSearch,
            //   ),
            // ),
            SizedBox(height: AppSpacing.sm),
            // Product grid with refresh
            Expanded(
              child: widget.isLoading
                  ? const AppLoadingCenter()
                  : RefreshIndicator(
                      onRefresh: () async {
                        widget.onRefresh?.call();
                      },
                      child: widget.products.isEmpty
                          ? _EmptyProducts(l10n: l10n)
                          : _ProductGrid(
                              products: widget.products,
                              cartItems: widget.cartItems,
                              onProductTap: widget.onProductTap,
                              isLoadingMore: widget.isLoadingMore,
                              hasMore: widget.hasMore,
                              onLoadMore: widget.onLoadMore,
                            ),
                    ),
            ),
          ],
        ),
        // Filter drawer overlay
        if (_isFilterDrawerOpen)
          GestureDetector(
            onTap: _toggleFilterDrawer,
            child: Container(
              color: Colors.black.withAlpha((0.5 * 255).round()),
            ),
          ),
        // Filter drawer
        SlideTransition(
          position: _drawerAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: PosFilterDrawer(
              categories: widget.categories,
              brands: widget.brands,
              selectedCategoryId: widget.selectedCategoryId,
              selectedBrandId: widget.selectedBrandId,
              onCategorySelected: _handleCategorySelected,
              onBrandSelected: _handleBrandSelected,
              onClose: _toggleFilterDrawer,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final VoidCallback? onFilterTap;
  final AppLocalizations l10n;

  const _FilterSection({
    this.selectedCategoryId,
    this.selectedBrandId,
    this.onFilterTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final hasActiveFilter =
        selectedCategoryId != null || selectedBrandId != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              icon: Icons.category,
              label: l10n.translate(LocaleKeys.category),
              isSelected: selectedCategoryId != null,
              hasActiveFilter: hasActiveFilter,
              onTap: onFilterTap,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _FilterButton(
              icon: Icons.branding_watermark,
              label: l10n.translate(LocaleKeys.brand),
              isSelected: selectedBrandId != null,
              hasActiveFilter: hasActiveFilter,
              onTap: onFilterTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool hasActiveFilter;
  final VoidCallback? onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.hasActiveFilter = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderRadiusSm,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha((0.1 * 255).round())
              : theme.cardColor,
          borderRadius: AppRadius.borderRadiusSm,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? theme.colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyProducts({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate(LocaleKeys.noProductsAvailable),
            style: AppTypography.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<ProductEntity> products;
  final List<CartItem> cartItems;
  final ValueChanged<ProductEntity>? onProductTap;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const _ProductGrid({
    required this.products,
    required this.cartItems,
    this.onProductTap,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          // Load more when scrolled near bottom (200px threshold)
          if (notification.metrics.extentAfter < 200 &&
              hasMore &&
              !isLoadingMore) {
            onLoadMore?.call();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: AppSpacing.paddingSm,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: products.length + (isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = products[index];
          final productId = product.productId ?? product.id;
          final variationId = product.variationId ?? 0;
          final cartItem = cartItems.firstWhere(
            (item) =>
                item.productId == productId && item.variationId == variationId,
            orElse: () => CartItem(
              product: product,
              productId: productId,
              variationId: variationId,
              unitPrice: 0,
            ),
          );
          final inCart = cartItems.any(
            (item) =>
                item.productId == productId && item.variationId == variationId,
          );

          return _ProductItem(
            product: product,
            quantity: inCart ? cartItem.quantity : 0,
            onTap: () => onProductTap?.call(product),
          );
        },
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final ProductEntity product;
  final int quantity;
  final VoidCallback? onTap;

  const _ProductItem({
    required this.product,
    this.quantity = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = product.displayName ??
        product.productName ??
        l10n.translate(LocaleKeys.product);
    final price = product.sellPriceIncTax ?? product.defaultSellPrice ?? 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSm,
        side: quantity > 0
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusSm,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: product.productImageUrl != null &&
                          product.productImageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.productImageUrl ?? '',
                            height: AppSizes.avatarLg,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildPlaceholder(theme),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/default_product.png',
                              height: AppSizes.avatarLg,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : _buildPlaceholder(theme),
                ),
                // Product info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: AppTypography.labelSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Expanded(
                          child: Align(
                            alignment: AlignmentGeometry.bottomCenter,
                            child: Text(
                              '${Helper().formatCurrency(price)}đ',
                              style: AppTypography.labelLarge.copyWith(
                                color: Color(0xff244ca3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Quantity badge
            if (quantity > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$quantity',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
        size: 32,
        color: theme.colorScheme.primary.withAlpha((0.5 * 255).round()),
      ),
    );
  }
}
