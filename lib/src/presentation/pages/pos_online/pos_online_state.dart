import 'package:domain/domain.dart';

/// POS Online page state
class PosOnlineState {
  final bool isLoading;
  final bool isSyncing;
  final bool showOfflinePos;
  final bool showLogoutDialog;
  final int unsyncedSellsCount;
  final Failure? failure;
  final String? successMessage;

  const PosOnlineState({
    this.isLoading = false,
    this.isSyncing = false,
    this.showOfflinePos = false,
    this.showLogoutDialog = false,
    this.unsyncedSellsCount = 0,
    this.failure,
    this.successMessage,
  });

  factory PosOnlineState.initial() => const PosOnlineState(isLoading: true);

  PosOnlineState copyWith({
    bool? isLoading,
    bool? isSyncing,
    bool? showOfflinePos,
    bool? showLogoutDialog,
    int? unsyncedSellsCount,
    Failure? failure,
    String? successMessage,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return PosOnlineState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      showOfflinePos: showOfflinePos ?? this.showOfflinePos,
      showLogoutDialog: showLogoutDialog ?? this.showLogoutDialog,
      unsyncedSellsCount: unsyncedSellsCount ?? this.unsyncedSellsCount,
      failure: clearFailure ? null : (failure ?? this.failure),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}



