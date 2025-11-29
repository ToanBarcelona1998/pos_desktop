import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_config/di.dart';
import 'auth_state.dart';

/// Cubit for managing authentication state globally
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? sl.get<AuthRepository>(),
        super(const AuthInitial());

  /// Checks if user is already authenticated
  Future<void> checkAuthentication() async {
    emit(const AuthLoading());

    final tokenResult = await _authRepository.getStoredToken();

    await tokenResult.fold(
      onSuccess: (token) async {
        // Token exists, try to get user
        final userResult = await _authRepository.getCurrentUser();

        userResult.fold(
          onSuccess: (user) {
            // Set token for API calls
            setAccessToken(token.accessToken);
            emit(Authenticated(user: user, token: token));
          },
          onError: (failure) {
            emit(const Unauthenticated());
          },
        );
      },
      onError: (failure) async {
        emit(const Unauthenticated());
      },
    );
  }

  /// Logs in with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(
      username: username,
      password: password,
    );

    await result.fold(
      onSuccess: (token) async {
        // Set token for API calls
        setAccessToken(token.accessToken);

        // Get user details
        final userResult = await _authRepository.getCurrentUser();

        userResult.fold(
          onSuccess: (user) {
            emit(Authenticated(user: user, token: token));
          },
          onError: (failure) {
            emit(AuthError(failure));
          },
        );
      },
      onError: (failure) async {
        emit(AuthError(failure));
      },
    );
  }

  /// Logs out the current user
  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _authRepository.logout();

    result.fold(
      onSuccess: (_) {
        setAccessToken(null);
        emit(const Unauthenticated());
      },
      onError: (failure) {
        // Still logout locally even if API fails
        setAccessToken(null);
        emit(const Unauthenticated());
      },
    );
  }

  /// Gets current user if authenticated
  UserEntity? get currentUser {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Gets current token if authenticated
  AuthTokenEntity? get currentToken {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.token;
    }
    return null;
  }

  /// Checks if user is authenticated
  bool get isAuthenticated => state is Authenticated;
}

