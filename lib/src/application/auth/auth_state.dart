import 'package:domain/domain.dart';

/// Authentication states
sealed class AuthState {
  const AuthState();
}

/// Initial state - checking authentication
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with user data
class Authenticated extends AuthState {
  final UserEntity user;
  final AuthTokenEntity token;

  const Authenticated({
    required this.user,
    required this.token,
  });
}

/// Unauthenticated state
class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated({this.message});
}

/// Authentication error state
class AuthError extends AuthState {
  final Failure failure;

  const AuthError(this.failure);

  String get message => failure.message;
}







