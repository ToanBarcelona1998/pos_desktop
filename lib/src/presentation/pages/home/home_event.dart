import '../../base/base_event.dart';

/// Home page events
class HomeEvent extends BaseEvent {
  const HomeEvent();
}

/// Initialize home event
class HomeInitialize extends HomeEvent {
  const HomeInitialize();
}

/// Refresh dashboard data
class HomeRefresh extends HomeEvent {
  const HomeRefresh();
}

/// Change selected location
class HomeLocationChanged extends HomeEvent {
  final int locationId;
  const HomeLocationChanged(this.locationId);
}

/// Logout event
class HomeLogout extends HomeEvent {
  const HomeLogout();
}

/// Sync data event
class HomeSyncData extends HomeEvent {
  const HomeSyncData();
}

/// Logout with sync event
class HomeLogoutWithSync extends HomeEvent {
  const HomeLogoutWithSync();
}

/// Logout without sync event
class HomeLogoutWithoutSync extends HomeEvent {
  const HomeLogoutWithoutSync();
}

/// Cancel logout event
class HomeCancelLogout extends HomeEvent {
  const HomeCancelLogout();
}






