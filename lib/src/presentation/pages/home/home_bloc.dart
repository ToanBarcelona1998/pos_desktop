import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/auth/auth_cubit.dart';
import '../../../application/auth/auth_state.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/navigation/route_path.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Home page bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthCubit _authCubit;
  final LocationRepository _locationRepository;
  final SystemSyncService _syncService;
  final SellRepository _sellRepository;
  StreamSubscription? _authSubscription;

  HomeBloc({
    required AuthCubit authCubit,
    required LocationRepository locationRepository,
    required SystemSyncService syncService,
    required SellRepository sellRepository,
  })  : _authCubit = authCubit,
        _locationRepository = locationRepository,
        _syncService = syncService,
        _sellRepository = sellRepository,
        super(HomeState.initial()) {
    on<HomeInitialize>(_onInitialize);
    on<HomeRefresh>(_onRefresh);
    on<HomeLocationChanged>(_onLocationChanged);
    on<HomeLogout>(_onLogout);
    on<HomeLogoutWithSync>(_onLogoutWithSync);
    on<HomeLogoutWithoutSync>(_onLogoutWithoutSync);
    on<HomeCancelLogout>(_onCancelLogout);
    on<HomeSyncData>(_onSyncData);
    on<_HomeAuthChanged>(_onAuthChanged);
    on<_HomeResetSyncSuccess>(_onResetSyncSuccess);

    // Listen to auth state for logout
    _authSubscription = _authCubit.stream.listen((authState) {
      add(_HomeAuthChanged(authState));
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitialize(
    HomeInitialize event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    try {
      // Get user info
      final user = _authCubit.currentUser;

      // Get locations from local/remote
      final locationsResult = await _locationRepository.getLocations();

      locationsResult.fold(
        onSuccess: (locations) {
          emit(state.copyWith(
            isLoading: false,
            userName: user?.username ?? 'User',
            businessName: 'Business',
            locations: locations,
            selectedLocationId:
                locations.isNotEmpty ? locations.first.id : null,
          ));
        },
        onError: (failure) {
          emit(state.copyWith(
            isLoading: false,
            userName: user?.username ?? 'User',
            businessName: 'Business',
            failure: failure,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onRefresh(
    HomeRefresh event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeInitialize());
  }

  Future<void> _onLocationChanged(
    HomeLocationChanged event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(selectedLocationId: event.locationId));
    add(const HomeRefresh());
  }

  Future<void> _onLogout(
    HomeLogout event,
    Emitter<HomeState> emit,
  ) async {
    // Check for unsynced sells first
    final unsyncedSellsResult = await _sellRepository.getLocalSells();
    
    await unsyncedSellsResult.fold(
      onSuccess: (unsyncedSells) async {
        if (unsyncedSells.isEmpty) {
          // No unsynced sells, logout directly
          await _authCubit.logout();
        } else {
          // There are unsynced sells, emit state to show dialog
          emit(state.copyWith(showLogoutDialog: true, unsyncedSellsCount: unsyncedSells.length));
        }
      },
      onError: (_) async {
        // On error, still allow logout
        await _authCubit.logout();
      },
    );
  }

  Future<void> _onLogoutWithSync(
    HomeLogoutWithSync event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, showLogoutDialog: false));
    
    try {
      // Sync sells first
      final syncResult = await _sellRepository.syncSells();
      
      await syncResult.fold(
        onSuccess: (_) async {
          // After sync, logout
          await _authCubit.logout();
        },
        onError: (_) async {
          // Even if sync fails, allow logout
          await _authCubit.logout();
        },
      );
    } catch (e) {
      // On error, still allow logout
      await _authCubit.logout();
    } finally {
      emit(state.copyWith(isSyncing: false));
    }
  }

  Future<void> _onLogoutWithoutSync(
    HomeLogoutWithoutSync event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(showLogoutDialog: false));
    // Logout without syncing
    await _authCubit.logout();
  }

  void _onCancelLogout(
    HomeCancelLogout event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(showLogoutDialog: false));
  }

  void _onAuthChanged(
    _HomeAuthChanged event,
    Emitter<HomeState> emit,
  ) {
    if (event.authState is Unauthenticated) {
      // Navigate to login after logout
      AppNavigator.navigateToLogin();
    }
  }

  Future<void> _onSyncData(
    HomeSyncData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearFailure: true));

    try {
      // Check connectivity first (like old code)
      // Note: NetworkInfo is checked inside repositories, but we can show better error messages
      
      // 1. Sync all unsynced sells first (like old code: Sell().createApiSell(syncAll: true))
      final syncSellsResult = await _sellRepository.syncSells();
      await syncSellsResult.fold(
        onSuccess: (_) {
          // Sells synced successfully
        },
        onError: (failure) {
          // If network error, continue with other syncs
          // Only fail if it's not a network error
          if (failure is! NetworkFailure) {
            emit(state.copyWith(
              isSyncing: false,
              failure: failure,
            ));
            return;
          }
        },
      );

      // 2. Sync system data (like old code: Variations().refresh() and SystemApi().store())
      await _syncService.syncAll();

      // 3. Refresh dashboard data (like old code: homepageData())
      add(const HomeRefresh());

      emit(state.copyWith(
        isSyncing: false,
        syncSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  void _onResetSyncSuccess(
    _HomeResetSyncSuccess event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(syncSuccess: false));
  }
}

// Internal event
class _HomeAuthChanged extends HomeEvent {
  final AuthState authState;
  const _HomeAuthChanged(this.authState);
}

class _HomeResetSyncSuccess extends HomeEvent {
  const _HomeResetSyncSuccess();
}
