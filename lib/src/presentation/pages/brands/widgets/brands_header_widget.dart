import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_text_field.dart';

/// Brands page header with search and statistics
class BrandsHeaderWidget extends StatelessWidget {
  final int totalBrands;
  final ValueChanged<String>? onSearch;

  const BrandsHeaderWidget({
    super.key,
    required this.totalBrands,
    this.onSearch,
  });

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
              Icon(Icons.label, color: theme.colorScheme.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                '${l10n?.translate(LocaleKeys.totalBrands) ?? 'Total Brands'}: $totalBrands',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Search
          AppSearchField(
            hintText: l10n?.translate(LocaleKeys.search) ?? 'Search brands...',
            onChanged: onSearch,
          ),
        ],
      ),
    );
  }
}









