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





