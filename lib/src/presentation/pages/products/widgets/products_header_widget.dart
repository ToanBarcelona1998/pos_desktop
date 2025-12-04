import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_text_field.dart';

/// Products page header with search
class ProductsHeaderWidget extends StatefulWidget {
  final int totalProducts;
  final String searchQuery;
  final ValueChanged<String>? onSearch;

  const ProductsHeaderWidget({
    super.key,
    required this.totalProducts,
    this.searchQuery = '',
    this.onSearch,
  });

  @override
  State<ProductsHeaderWidget> createState() => _ProductsHeaderWidgetState();
}

class _ProductsHeaderWidgetState extends State<ProductsHeaderWidget> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics
          Row(
            children: [
              Icon(Icons.inventory_2, color: theme.colorScheme.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                '${l10n?.translate(LocaleKeys.products) ?? 'Products'}: ${widget.totalProducts}',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Search
          AppSearchField(
            controller: _searchController,
            hintText: l10n?.translate(LocaleKeys.searchProducts) ?? 'Search products...',
            onChanged: widget.onSearch,
            onClear: () => widget.onSearch?.call(''),
          ),
        ],
      ),
    );
  }
}










