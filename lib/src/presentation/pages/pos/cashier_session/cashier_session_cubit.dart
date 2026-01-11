import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app_config/di.dart';
import 'cashier_session_state.dart';

/// Cubit for managing cashier session state
class CashierSessionCubit extends Cubit<CashierSessionState> {
  final CashierSessionRepository _repository;

  CashierSessionCubit({
    CashierSessionRepository? repository,
  })  : _repository = repository ?? sl.get<CashierSessionRepository>(),
        super(CashierSessionState.initial());

  /// Initialize and check for active session
  Future<void> initialize({
    required int userId,
    required int locationId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.getActiveSession(
      userId: userId,
      locationId: locationId,
    );

    result.fold(
      onSuccess: (session) {
        emit(state.copyWith(
          isLoading: false,
          activeSession: session,
          showCheckInDialog: session == null, // Show dialog if no active session
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      },
    );
  }

  /// Check-in (start session)
  Future<void> checkIn({
    required int locationId,
    required double amount,
    required int userId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.checkIn(
      locationId: locationId,
      amount: amount,
      userId: userId,
    );

    result.fold(
      onSuccess: (session) {
        emit(state.copyWith(
          isLoading: false,
          activeSession: session,
          showCheckInDialog: false,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      },
    );
  }

  /// Check-out (end session)
  Future<void> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
    required int userId,
    required int locationId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _repository.checkOut(
      closingAmount: closingAmount,
      closingAmountOnStaff: closingAmountOnStaff,
      totalCardSlips: totalCardSlips,
      totalCheques: totalCheques,
      closingNote: closingNote,
      denominations: denominations,
      userId: userId,
      locationId: locationId,
    );

    result.fold(
      onSuccess: (_) {
        emit(state.copyWith(
          isLoading: false,
          checkOutSuccess: true,
          showCheckOutDialog: false,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      },
    );
  }

  /// Show check-out dialog
  void showCheckOutDialog() {
    emit(state.copyWith(showCheckOutDialog: true));
  }

  /// Hide check-out dialog
  void hideCheckOutDialog() {
    emit(state.copyWith(showCheckOutDialog: false));
  }
}
