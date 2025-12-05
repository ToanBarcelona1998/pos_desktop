import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../widgets/app_card.dart';

/// Brand list widget
class BrandListWidget extends StatelessWidget {
  final List<BrandEntity> brands;
  final bool isSubmitting;
  final ValueChanged<BrandEntity>? onEdit;
  final ValueChanged<BrandEntity>? onDelete;

  const BrandListWidget({
    super.key,
    required this.brands,
    this.isSubmitting = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.paddingMd,
      itemCount: brands.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final brand = brands[index];
        return _BrandItem(
          brand: brand,
          isSubmitting: isSubmitting,
          onEdit: () => onEdit?.call(brand),
          onDelete: () => onDelete?.call(brand),
        );
      },
    );
  }
}

class _BrandItem extends StatelessWidget {
  final BrandEntity brand;
  final bool isSubmitting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _BrandItem({
    required this.brand,
    this.isSubmitting = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          // Brand icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
                style: AppTypography.headlineSmall.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Brand info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (brand.description != null && brand.description!.isNotEmpty)
                  Text(
                    brand.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Actions
          if (!isSubmitting) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              iconSize: 20,
            ),
            IconButton(
              icon: Icon(Icons.delete_outlined, color: theme.colorScheme.error),
              onPressed: onDelete,
              iconSize: 20,
            ),
          ] else
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}











