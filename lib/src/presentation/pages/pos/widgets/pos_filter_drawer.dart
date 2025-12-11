import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/src/presentation/widgets/icon_wrapper_widget.dart';

import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/core.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import 'pos_product_grid_widget.dart';

/// Filter drawer that slides from right
class PosFilterDrawer extends StatelessWidget {
  final FilterType filterType;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final ValueChanged<int?>? onCategorySelected;
  final ValueChanged<int?>? onBrandSelected;
  final VoidCallback? onClose;

  const PosFilterDrawer({
    super.key,
    required this.filterType,
    required this.categories,
    required this.brands,
    this.selectedCategoryId,
    this.selectedBrandId,
    this.onCategorySelected,
    this.onBrandSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    final isCategory = filterType == FilterType.category;
    final title = isCategory
        ? l10n.translate(LocaleKeys.category)
        : l10n.translate(LocaleKeys.brand);
    final icon = isCategory ? Icons.category : Icons.branding_watermark;
    final items = isCategory
        ? [
            {'id': null, 'name': l10n.translate(LocaleKeys.allCategories)},
            ...categories.map((c) => {'id': c.id, 'name': c.name}),
          ]
        : [
            {'id': null, 'name': l10n.translate(LocaleKeys.allBrands)},
            ...brands.map((b) => {'id': b.id, 'name': b.name}),
          ];
    final selectedId = isCategory ? selectedCategoryId : selectedBrandId;
    final onItemSelected = isCategory ? onCategorySelected : onBrandSelected;

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: EdgeInsets.symmetric(
          vertical: rSpacing.md, horizontal: rSpacing.sm),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: rTypography.titleLarge.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconWrapper(
                icon: Icons.close,
                onTap: onClose,
                iconColor: Colors.red,
              ),
            ],
          ),
          rSpacing.gapVerticalSm,
          // Content
          Expanded(
            child: _FilterSection(
              title: title,
              icon: icon,
              items: items,
              selectedId: selectedId,
              onItemSelected: onItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final ValueChanged<int?>? onItemSelected;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.items,
    this.selectedId,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    final appColor = AppThemes.light;

    final selectedColor = appColor.primaryColor;

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: rSpacing.sm,
        crossAxisSpacing: rSpacing.sm,
        childAspectRatio: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item['id'] == selectedId;
        return InkWell(
          onTap: () => onItemSelected?.call(item['id']),
          borderRadius: AppRadius.borderRadiusSm,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: rSpacing.sm,
                  vertical: rSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor.withAlpha((255 * 0.3).round()) : theme.cardColor,
                  borderRadius: AppRadius.borderRadiusSm,
                  border: Border.all(
                    color:
                        isSelected ? selectedColor : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item['name'],
                  style: rTypography.bodySmall.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? selectedColor
                        : theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Positioned(
                  top: rSpacing.xxxs,
                  right: rSpacing.xxxs,
                  child: Icon(
                    Icons.check,
                    color: selectedColor,
                    size: rSizes.iconXs,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
