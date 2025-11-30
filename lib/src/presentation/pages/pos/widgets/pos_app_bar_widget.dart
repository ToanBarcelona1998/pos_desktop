import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// POS app bar widget
class PosAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final List<LocationEntity> locations;
  final int? selectedLocationId;
  final ValueChanged<int>? onLocationChanged;
  final VoidCallback? onRefresh;

  const PosAppBarWidget({
    super.key,
    required this.locations,
    this.selectedLocationId,
    this.onLocationChanged,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppBar(
      title: Row(
        children: [
          // Location selector
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderRadiusSm,
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedLocationId,
                hint: Text(l10n?.translate(LocaleKeys.selectLocation) ?? 'Select Location'),
                items: locations.map((location) {
                  return DropdownMenuItem<int>(
                    value: location.id,
                    child: Text(location.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onLocationChanged?.call(value);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Date/time display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                SizedBox(width: AppSpacing.xs),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen),
          onPressed: () {
            // Toggle fullscreen
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}


