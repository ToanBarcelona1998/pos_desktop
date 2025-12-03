import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_config/di.dart';
import '../../../application/auth/auth_cubit.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/navigation/route_path.dart';
import '../../widgets/app_loading.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'widgets/home_app_bar_widget.dart';
import 'widgets/home_content_widget.dart';
import 'widgets/home_drawer_widget.dart';

/// Home page - Main dashboard
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        authCubit: context.read<AuthCubit>(),
        locationRepository: sl.get<LocationRepository>(),
        syncService: sl.get<SystemSyncService>(),
        sellRepository: sl.get<SellRepository>(),
      )..add(const HomeInitialize()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.showLogoutDialog != current.showLogoutDialog ||
          (previous.isSyncing && !current.isSyncing && current.failure == null && current.syncSuccess),
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure!.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        if (state.showLogoutDialog) {
          _showLogoutDialogWithUnsyncedSells(context, state.unsyncedSellsCount);
        }
        // Show success message when sync completes successfully
        if (state.syncSuccess && !state.isSyncing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate(LocaleKeys.syncCompleted) ?? 'Sync completed',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          // // Reset syncSuccess flag
          // context.read<HomeBloc>().add(const _HomeResetSyncSuccess());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: HomeAppBarWidget(
            userName: state.userName ?? '',
            isSyncing: state.isSyncing,
            onSync: () => context.read<HomeBloc>().add(const HomeSyncData()),
            onNotifications: () =>
                AppNavigator.pushNamed(RoutePath.notify.path),
          ),
          drawer: HomeDrawerWidget(
            userName: state.userName ?? '',
            businessName: state.businessName ?? '',
            onLogout: () => context.read<HomeBloc>().add(const HomeLogout()),
          ),
          body: state.isLoading
              ? const AppLoadingCenter()
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(const HomeRefresh());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.paddingMd,
                    child: HomeContentWidget(state: state),
                  ),
                ),
        );
      },
    );
  }

  void _showLogoutDialogWithUnsyncedSells(BuildContext context, int unsyncedCount) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bloc = context.read<HomeBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            l10n?.translate(LocaleKeys.pendingSync) ?? 'Pending Synchronization',
            style: AppTypography.titleLarge,
          ),
          content: Text(
            l10n?.translate(LocaleKeys.syncAllSalesBeforeLogout) ??
                'Sync all sales before logout.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bloc.add(const HomeLogoutWithSync());
              },
              child: Text(
                l10n?.translate(LocaleKeys.sync) ?? 'Sync',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bloc.add(const HomeLogoutWithoutSync());
              },
              child: Text(
                l10n?.translate(LocaleKeys.logoutWithoutSync) ??
                    'Logout Without Sync',
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bloc.add(const HomeCancelLogout());
              },
              child: Text(
                l10n?.translate(LocaleKeys.cancel) ?? 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }
}
