import 'package:equatable/equatable.dart';

/// POS Online page events
abstract class PosOnlineEvent extends Equatable {
  const PosOnlineEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize POS online
class PosOnlineInitialize extends PosOnlineEvent {
  const PosOnlineInitialize();
}

/// Sync data
class PosOnlineSync extends PosOnlineEvent {
  const PosOnlineSync();
}

/// Logout
class PosOnlineLogout extends PosOnlineEvent {
  const PosOnlineLogout();
}

/// Logout with sync
class PosOnlineLogoutWithSync extends PosOnlineEvent {
  const PosOnlineLogoutWithSync();
}

/// Logout without sync
class PosOnlineLogoutWithoutSync extends PosOnlineEvent {
  const PosOnlineLogoutWithoutSync();
}

/// Cancel logout
class PosOnlineCancelLogout extends PosOnlineEvent {
  const PosOnlineCancelLogout();
}

/// Show offline POS
class PosOnlineShowOffline extends PosOnlineEvent {
  const PosOnlineShowOffline();
}

/// Hide offline POS
class PosOnlineHideOffline extends PosOnlineEvent {
  const PosOnlineHideOffline();
}

/// Authentication completed from webview
class PosOnlineAuthCompleted extends PosOnlineEvent {
  final String accessToken;
  final Map<String, dynamic> userInfo;

  const PosOnlineAuthCompleted({
    required this.accessToken,
    required this.userInfo,
  });

  @override
  List<Object?> get props => [accessToken, userInfo];
}

/// Logout from webview
class PosOnlineLogoutFromWebview extends PosOnlineEvent {
  const PosOnlineLogoutFromWebview();
}


