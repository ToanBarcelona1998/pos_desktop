import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_config/di.dart';
import '../../../application/auth/auth_cubit.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localization.dart';
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
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure!.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
}
