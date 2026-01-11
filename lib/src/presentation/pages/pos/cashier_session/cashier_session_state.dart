import 'package:domain/domain.dart';

/// Cashier session state
class CashierSessionState {
  final bool isLoading;
  final CashierSessionEntity? activeSession;
  final bool showCheckInDialog;
  final bool showCheckOutDialog;
  final String? errorMessage;
  final bool checkOutSuccess;

  const CashierSessionState({
    this.isLoading = false,
    this.activeSession,
    this.showCheckInDialog = false,
    this.showCheckOutDialog = false,
    this.errorMessage,
    this.checkOutSuccess = false,
  });

  factory CashierSessionState.initial() => const CashierSessionState();

  CashierSessionState copyWith({
    bool? isLoading,
    CashierSessionEntity? activeSession,
    bool? showCheckInDialog,
    bool? showCheckOutDialog,
    String? errorMessage,
    bool? checkOutSuccess,
    bool clearError = false,
  }) {
    return CashierSessionState(
      isLoading: isLoading ?? this.isLoading,
      activeSession: activeSession ?? this.activeSession,
      showCheckInDialog: showCheckInDialog ?? this.showCheckInDialog,
      showCheckOutDialog: showCheckOutDialog ?? this.showCheckOutDialog,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      checkOutSuccess: checkOutSuccess ?? this.checkOutSuccess,
    );
  }
}
