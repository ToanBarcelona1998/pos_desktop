import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/src/presentation/presentation.dart';
import 'package:pos_final/src/presentation/widgets/icon_wrapper_widget.dart';
import 'package:pos_final/src/presentation/widgets/live_clock_widget.dart';

import '../../../../application/auth/auth_cubit.dart';
import '../../../../application/auth/auth_state.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// POS app bar widget
class PosAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final List<LocationEntity> locations;
  final int? selectedLocationId;
  final ValueChanged<int>? onLocationChanged;
  final VoidCallback? onRefresh;
  final VoidCallback? onSuspendedSales;
  final VoidCallback? onOpenFullScreen;

  const PosAppBarWidget({
    super.key,
    required this.locations,
    this.selectedLocationId,
    this.onLocationChanged,
    this.onRefresh,
    this.onSuspendedSales,
    this.onOpenFullScreen,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppBar(
      leading: const SizedBox(),
      leadingWidth: 0,
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
              // border: Border.all(color: theme.dividerColor),
            ),
            // child: Text(
            //   l10n.translate(LocaleKeys.selectLocation),
            // ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedLocationId,
                hint: Text(l10n.translate(LocaleKeys.selectLocation)),
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
          AppGradientButton(
            text: '',
            leading: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(
                  width: AppSpacing.xs,
                ),
                const LiveClockWidget()
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconWrapper(
          icon: Icons.refresh,
          onTap: onRefresh,
          tooltip: l10n.translate(LocaleKeys.refresh),
          iconColor: Colors.purple,
        ),
        const SizedBox(
          width: AppSpacing.xs,
        ),
        IconWrapper(
          icon: Icons.pause_circle_outline,
          onTap: onSuspendedSales,
          tooltip: l10n.translate(LocaleKeys.suspendedSales),
          iconColor: Colors.grey,
        ),
        const SizedBox(
          width: AppSpacing.xs,
        ),
        IconWrapper(
          icon: Icons.fullscreen,
          onTap: onOpenFullScreen,
          iconColor: Colors.blueAccent,
        ),
        const SizedBox(
          width: AppSpacing.xs,
        ),
        IconWrapper(
          icon: Icons.close,
          onTap: (){},
          iconColor: Colors.red,
        ),
        const SizedBox(
          width: AppSpacing.sm,
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is Authenticated) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync button
                  IconWrapper(
                    iconSize: AppSizes.iconXs,
                    iconColor: Colors.blueAccent,
                    icon: Icons.sync,
                    tooltip: l10n.translate(LocaleKeys.syncData),
                    onTap: () {
                      context.read<PosOnlineBloc>().add(
                        const PosOnlineSync(),
                      );
                    },
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                  // Logout button
                  IconWrapper(
                    iconColor: Colors.red,
                    iconSize: AppSizes.iconXs,
                    icon: Icons.logout,
                    tooltip: l10n.translate(LocaleKeys.logout),
                    onTap: () {
                      context.read<PosOnlineBloc>().add(
                        const PosOnlineLogout(),
                      );
                    },
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
