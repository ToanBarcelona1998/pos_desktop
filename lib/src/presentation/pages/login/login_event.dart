import '../../base/base_event.dart';

/// Login page events
class LoginEvent extends BaseEvent {
  const LoginEvent();
}

/// Username changed event
class LoginUsernameChanged extends LoginEvent {
  final String username;
  const LoginUsernameChanged(this.username);
}

/// Password changed event
class LoginPasswordChanged extends LoginEvent {
  final String password;
  const LoginPasswordChanged(this.password);
}

/// Toggle password visibility
class LoginTogglePasswordVisibility extends LoginEvent {
  const LoginTogglePasswordVisibility();
}

/// Submit login form
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

/// Navigate to register
class LoginRegisterPressed extends LoginEvent {
  const LoginRegisterPressed();
}






