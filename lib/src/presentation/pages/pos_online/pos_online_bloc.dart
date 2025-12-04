import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/auth/auth_cubit.dart';
import '../../../core/localization/locale_keys.dart';
import 'pos_online_event.dart';
import 'pos_online_state.dart';

/// POS Online page bloc
class PosOnlineBloc extends Bloc<PosOnlineEvent, PosOnlineState> {
  final AuthCubit _authCubit;
  final SystemSyncService _syncService;
  final SellRepository _sellRepository;

  PosOnlineBloc({
    required AuthCubit authCubit,
    required SystemSyncService syncService,
    required SellRepository sellRepository,
  })  : _authCubit = authCubit,
        _syncService = syncService,
        _sellRepository = sellRepository,
        super(PosOnlineState.initial()) {
    on<PosOnlineInitialize>(_onInitialize);
    on<PosOnlineSync>(_onSync);
    on<PosOnlineLogout>(_onLogout);
    on<PosOnlineLogoutWithSync>(_onLogoutWithSync);
    on<PosOnlineLogoutWithoutSync>(_onLogoutWithoutSync);
    on<PosOnlineCancelLogout>(_onCancelLogout);
    on<PosOnlineShowOffline>(_onShowOffline);
    on<PosOnlineHideOffline>(_onHideOffline);
    on<PosOnlineAuthCompleted>(_onAuthCompleted);
    on<PosOnlineLogoutFromWebview>(_onLogoutFromWebview);
    on<PosOnlineCheckAuthentication>(_onCheckAuthentication);
    on<PosOnlineUrlChangedToLogin>(_onUrlChangedToLogin);
  }

  Future<void> _onInitialize(
    PosOnlineInitialize event,
    Emitter<PosOnlineState> emit,
  ) async {
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onSync(
    PosOnlineSync event,
    Emitter<PosOnlineState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearFailure: true));

    // Check for unsynced sells first
    final unsyncedSellsResult = await _sellRepository.getLocalSells();

    await unsyncedSellsResult.fold(
      onSuccess: (unsyncedSells) async {
        try {
          if (unsyncedSells.isNotEmpty) {
            // Sync sells first
            final syncSellsResult = await _sellRepository.syncSells();
            await syncSellsResult.fold(
              onSuccess: (_) {},
              onError: (failure) {
                // Continue with system sync even if sell sync fails
                print('Sell sync error: ${failure.message}');
              },
            );
          }

          // Sync system data
          await _syncService.syncAll();

          emit(state.copyWith(
            isSyncing: false,
            successMessage: LocaleKeys.syncCompletedSuccessfully,
          ));
        } catch (e) {
          emit(state.copyWith(
            isSyncing: false,
            failure: UnknownFailure(message: e.toString()),
          ));
        }
      },
      onError: (failure) async {
        // On error, still try to sync system data
        try {
          await _syncService.syncAll();
          emit(state.copyWith(
            isSyncing: false,
            successMessage: LocaleKeys.syncCompletedSuccessfully,
          ));
        } catch (e) {
          emit(state.copyWith(
            isSyncing: false,
            failure: UnknownFailure(message: e.toString()),
          ));
        }
      },
    );
  }

  Future<void> _onLogout(
    PosOnlineLogout event,
    Emitter<PosOnlineState> emit,
  ) async {
    // Check for unsynced sells
    final unsyncedSellsResult = await _sellRepository.getLocalSells();

    await unsyncedSellsResult.fold(
      onSuccess: (unsyncedSells) async {
        if (unsyncedSells.isEmpty) {
          // No unsynced sells, logout directly
          add(const PosOnlineLogoutWithoutSync());
        } else {
          // Show dialog with options
          emit(state.copyWith(
            showLogoutDialog: true,
            unsyncedSellsCount: unsyncedSells.length,
          ));
        }
      },
      onError: (_) {
        // On error, allow logout
        add(const PosOnlineLogoutWithoutSync());
      },
    );
  }

  Future<void> _onLogoutWithSync(
    PosOnlineLogoutWithSync event,
    Emitter<PosOnlineState> emit,
  ) async {
    emit(state.copyWith(
      isSyncing: true,
      showLogoutDialog: false,
      clearFailure: true,
    ));

    try {
      // Sync sells
      final syncSellsResult = await _sellRepository.syncSells();
      await syncSellsResult.fold(
        onSuccess: (_) {},
        onError: (_) {},
      );

      // Sync system data
      await _syncService.syncAll();

      // Proceed to logout
      await _authCubit.logout();

      emit(state.copyWith(
        isSyncing: false,
        successMessage: LocaleKeys.loggedOutSuccessfully,
        showLogoutDialog: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onLogoutWithoutSync(
    PosOnlineLogoutWithoutSync event,
    Emitter<PosOnlineState> emit,
  ) async {
    try {
      // Clear user and database via AuthCubit
      await _authCubit.logout();

      emit(state.copyWith(
        successMessage: LocaleKeys.loggedOutSuccessfully,
      ));
    } catch (e) {
      emit(state.copyWith(
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  void _onCancelLogout(
    PosOnlineCancelLogout event,
    Emitter<PosOnlineState> emit,
  ) {
    emit(state.copyWith(showLogoutDialog: false));
  }

  void _onShowOffline(
    PosOnlineShowOffline event,
    Emitter<PosOnlineState> emit,
  ) {
    emit(state.copyWith(showOfflinePos: true));
  }

  void _onHideOffline(
    PosOnlineHideOffline event,
    Emitter<PosOnlineState> emit,
  ) {
    emit(state.copyWith(showOfflinePos: false));
  }

  Future<void> _onAuthCompleted(
    PosOnlineAuthCompleted event,
    Emitter<PosOnlineState> emit,
  ) async {
    try {
      // Handle authentication via AuthCubit
      await _authCubit.loginFromWebView(
        accessToken: event.accessToken,
        userInfo: event.userInfo,
      );
    } catch (e) {
      emit(state.copyWith(
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onLogoutFromWebview(
    PosOnlineLogoutFromWebview event,
    Emitter<PosOnlineState> emit,
  ) async {
    try {
      // Clear user and database
      await _authCubit.logout();

      emit(state.copyWith(
        successMessage: LocaleKeys.loggedOutSuccessfully,
      ));
    } catch (e) {
      emit(state.copyWith(
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onCheckAuthentication(
    PosOnlineCheckAuthentication event,
    Emitter<PosOnlineState> emit,
  ) async {
    // Check if user is already authenticated
    await _authCubit.checkAuthentication();
  }

  Future<void> _onUrlChangedToLogin(
    PosOnlineUrlChangedToLogin event,
    Emitter<PosOnlineState> emit,
  ) async {
    try {
      // URL changed to login page - logout (clear cache, delete user database, auth)
      await _authCubit.logout();
    } catch (e) {
      emit(state.copyWith(
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }
}

