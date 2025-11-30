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
  StreamSubscription? _authSubscription;

  HomeBloc({
    required AuthCubit authCubit,
    required LocationRepository locationRepository,
    required SystemSyncService syncService,
  })  : _authCubit = authCubit,
        _locationRepository = locationRepository,
        _syncService = syncService,
        super(HomeState.initial()) {
    on<HomeInitialize>(_onInitialize);
    on<HomeRefresh>(_onRefresh);
    on<HomeLocationChanged>(_onLocationChanged);
    on<HomeLogout>(_onLogout);
    on<HomeSyncData>(_onSyncData);
    on<_HomeAuthChanged>(_onAuthChanged);

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
    // AuthCubit handles database cleanup
    await _authCubit.logout();
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
    emit(state.copyWith(isSyncing: true));

    try {
      await _syncService.syncAll();
      emit(state.copyWith(isSyncing: false));
      add(const HomeRefresh());
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }
}

// Internal event
class _HomeAuthChanged extends HomeEvent {
  final AuthState authState;
  const _HomeAuthChanged(this.authState);
}
