import 'package:domain/domain.dart';

/// POS Online page status enum
enum PosOnlineStatus {
  /// Initial state
  initial,
  
  /// Loading state
  loading,
  
  /// Syncing data
  syncing,
  
  /// Success state
  success,
  
  /// Error state
  error,
  
  /// Idle/ready state
  idle,
}

/// POS Online page state
class PosOnlineState {
  final PosOnlineStatus status;
  final bool showOfflinePos;
  final bool showLogoutDialog;
  final bool showSyncDialog;
  final int unsyncedSellsCount;
  final String? errorMessage;
  final String? successMessage;

  const PosOnlineState({
    this.status = PosOnlineStatus.idle,
    this.showOfflinePos = false,
    this.showLogoutDialog = false,
    this.showSyncDialog = false,
    this.unsyncedSellsCount = 0,
    this.errorMessage,
    this.successMessage,
  });

  factory PosOnlineState.initial() => const PosOnlineState(status: PosOnlineStatus.initial);

  // Convenience getters for backward compatibility
  bool get isLoading => status == PosOnlineStatus.loading || status == PosOnlineStatus.initial;
  bool get isSyncing => status == PosOnlineStatus.syncing;
  Failure? get failure => errorMessage != null 
      ? UnknownFailure(message: errorMessage!) 
      : null;

  PosOnlineState copyWith({
    PosOnlineStatus? status,
    bool? showOfflinePos,
    bool? showLogoutDialog,
    bool? showSyncDialog,
    int? unsyncedSellsCount,
    String? errorMessage,
    String? successMessage,
    bool clearFailure = false,
    bool clearSuccessMessage = false,
  }) {
    return PosOnlineState(
      status: status ?? this.status,
      showOfflinePos: showOfflinePos ?? this.showOfflinePos,
      showLogoutDialog: showLogoutDialog ?? this.showLogoutDialog,
      showSyncDialog: showSyncDialog ?? this.showSyncDialog,
      unsyncedSellsCount: unsyncedSellsCount ?? this.unsyncedSellsCount,
      errorMessage: clearFailure ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}




