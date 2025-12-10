import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// Filter drawer that slides from right
class PosFilterDrawer extends StatelessWidget {
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final ValueChanged<int?>? onCategorySelected;
  final ValueChanged<int?>? onBrandSelected;
  final VoidCallback? onClose;

  const PosFilterDrawer({
    super.key,
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

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
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
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate(LocaleKeys.filters),
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: AppSpacing.paddingMd,
              children: [
                // Category section
                _FilterSection(
                  title: l10n.translate(LocaleKeys.category),
                  icon: Icons.category,
                  items: [
                    {'id': null, 'name': l10n.translate(LocaleKeys.allCategories)},
                    ...categories.map((c) => {'id': c.id, 'name': c.name}),
                  ],
                  selectedId: selectedCategoryId,
                  onItemSelected: (id) {
                    onCategorySelected?.call(id);
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                // Brand section
                _FilterSection(
                  title: l10n.translate(LocaleKeys.brand),
                  icon: Icons.branding_watermark,
                  items: [
                    {'id': null, 'name': l10n.translate(LocaleKeys.allBrands)},
                    ...brands.map((b) => {'id': b.id, 'name': b.name}),
                  ],
                  selectedId: selectedBrandId,
                  onItemSelected: (id) {
                    onBrandSelected?.call(id);
                  },
                ),
              ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        // Grid view for filter items
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = item['id'] == selectedId;
            return InkWell(
              onTap: () => onItemSelected?.call(item['id']),
              borderRadius: AppRadius.borderRadiusSm,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withAlpha((0.1 * 255).round())
                      : theme.cardColor,
                  borderRadius: AppRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
