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
  final VoidCallback? onOpenCustomerWindow;
  final VoidCallback? onCloseSession;

  const PosAppBarWidget({
    super.key,
    required this.locations,
    this.selectedLocationId,
    this.onLocationChanged,
    this.onRefresh,
    this.onSuspendedSales,
    this.onOpenFullScreen,
    this.onOpenCustomerWindow,
    this.onCloseSession,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return AppBar(
      leading: const SizedBox(),
      leadingWidth: 0,
      title: Row(
        children: [
          // Location selector
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: rSpacing.sm,
              vertical: rSpacing.xxs,
            ),
            child: Row(
              children: [
                Text(
                  '${l10n.translate(LocaleKeys.location)}:',
                  style: rTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                rSpacing.gapHorizontalMd,
                _buildLocations(context),
              ],
            ),
          ),
          rSpacing.gapHorizontalMd,
          // Date/time display
          AppGradientButton(
            text: '',
            leading: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.white, size: rSizes.iconXs),
                rSpacing.gapHorizontalXs,
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
        rSpacing.gapHorizontalXs,
        IconWrapper(
          icon: Icons.pause_circle_outline,
          onTap: onSuspendedSales,
          tooltip: l10n.translate(LocaleKeys.suspendedSales),
          iconColor: Colors.grey,
        ),
        rSpacing.gapHorizontalXs,
        IconWrapper(
          icon: Icons.fullscreen,
          onTap: onOpenFullScreen,
          iconColor: Colors.blueAccent,
        ),
        rSpacing.gapHorizontalXs,
        IconWrapper(
          icon: Icons.close,
          onTap: onCloseSession,
          iconColor: Colors.red,
        ),
        rSpacing.gapHorizontalXs,
        IconWrapper(
          icon: Icons.tv,
          onTap: onOpenCustomerWindow,
          tooltip: l10n.translate(LocaleKeys.customerDisplay),
          iconColor: Colors.blue,
        ),
        rSpacing.gapHorizontalSm,
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is Authenticated) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync button
                  IconWrapper(
                    iconColor: Colors.blueAccent,
                    icon: Icons.sync,
                    tooltip: l10n.translate(LocaleKeys.syncData),
                    onTap: () {
                      context.read<PosOnlineBloc>().add(
                            const PosOnlineSync(),
                          );
                    },
                  ),
                  rSpacing.gapHorizontalSm,
                  // Logout button
                  IconWrapper(
                    iconColor: Colors.red,
                    icon: Icons.logout,
                    tooltip: l10n.translate(LocaleKeys.logout),
                    onTap: () {
                      context.read<PosOnlineBloc>().add(
                            const PosOnlineLogout(),
                          );
                    },
                  ),
                  rSpacing.gapHorizontalSm,
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildLocations(BuildContext context) {
    // Multiple accounts - dropdown
    final theme = Theme.of(context);

    final rTypography = context.rTypography;
    
    if(locations.isEmpty){
      return const SizedBox();
    }

    final initValue = locations
        .where(
          (element) => element.id == selectedLocationId,
    )
        .first;
    
    if(locations.length == 1){
      return Text(
        initValue.name,
        style: rTypography.titleMedium,
      );
    }
    
    return IntrinsicWidth(
      child: DropdownButtonFormField<LocationEntity>(
        initialValue: initValue,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderRadiusSm,
            borderSide: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderRadiusSm,
            borderSide: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderRadiusSm,
            borderSide: BorderSide(
              color: theme.primaryColor,
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.rSpacing.md,
            vertical: context.rSpacing.sm,
          ),
        ),
        style: context.rTypography.bodyMedium.copyWith(color: Colors.black),
        selectedItemBuilder: (context) {
          return locations.map((location) {
            return Text(
              location.name,
              overflow: TextOverflow.ellipsis,
              style: context.rTypography.bodyMedium,
            );
          }).toList();
        },
        items: locations.map((location) {
          return DropdownMenuItem<LocationEntity>(
            value: location,
            child: Text(
              location.name,
              overflow: TextOverflow.ellipsis,
              style: context.rTypography.bodyMedium.copyWith(color: Colors.black),
            ),
          );
        }).toList(),
        onChanged: (location) {
          if(location != null){
            onLocationChanged?.call(location.id); 
          }
        },
      ),
    );
  }
}
