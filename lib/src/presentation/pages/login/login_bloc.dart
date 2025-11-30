import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app_config/di.dart';
import '../../../application/auth/auth_cubit.dart';
import '../../../application/auth/auth_state.dart';
import '../../../core/localization/locale_keys.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Login page bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthCubit _authCubit;
  final DatabaseHelper _databaseHelper;
  final SystemSyncService _syncService;
  final String? _registerUrl;
  StreamSubscription? _authSubscription;

  LoginBloc({
    required AuthCubit authCubit,
    DatabaseHelper? databaseHelper,
    SystemSyncService? syncService,
    String? registerUrl,
  })  : _authCubit = authCubit,
        _databaseHelper = databaseHelper ?? sl.get<DatabaseHelper>(),
        _syncService = syncService ?? sl.get<SystemSyncService>(),
        _registerUrl = registerUrl,
        super(LoginState.initial()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginTogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginRegisterPressed>(_onRegisterPressed);

    // Listen to auth state changes
    _authSubscription = _authCubit.stream.listen((authState) {
      if (authState is Authenticated) {
        // Ensure database is initialized even if user hasn't logged in before
        _ensureDatabaseInitialized(authState.user.id).then((_) {
          add(const _LoginAuthSuccess());
        });
      } else if (authState is AuthError) {
        add(_LoginAuthError(authState.failure));
      }
    });

    on<_LoginAuthSuccess>((event, emit) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        clearErrors: true,
      ));
    });

    on<_LoginAuthError>((event, emit) {
      emit(state.copyWith(
        isSubmitting: false,
        failure: event.failure,
      ));
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  /// Ensure database is initialized for the user
  Future<void> _ensureDatabaseInitialized(int? userId) async {
    if (userId == null) return;

    try {
      // Initialize database - this is safe to call even if already initialized
      await _databaseHelper.initDatabase(userId);
      
      // Sync system data in background
      _syncService.syncAll().catchError((e) {
        // Log error but don't fail login
        print('System sync error: $e');
      });
    } catch (e) {
      // Log error but don't fail login
      print('Database initialization error: $e');
    }
  }

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<LoginState> emit,
  ) {
    final username = event.username;
    String? error;

    if (username.isEmpty) {
      error = LocaleKeys.pleaseEnterUsername;
    }

    emit(state.copyWith(
      username: username,
      usernameError: error,
      clearErrors: error == null,
    ));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final password = event.password;
    String? error;

    if (password.isEmpty) {
      error = LocaleKeys.pleaseEnterPassword;
    }

    emit(state.copyWith(
      password: password,
      passwordError: error,
      clearErrors: error == null,
    ));
  }

  void _onTogglePasswordVisibility(
    LoginTogglePasswordVisibility event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Validate
    String? usernameError;
    String? passwordError;

    if (state.username.isEmpty) {
      usernameError = LocaleKeys.pleaseEnterUsername;
    }
    if (state.password.isEmpty) {
      passwordError = LocaleKeys.pleaseEnterPassword;
    }

    if (usernameError != null || passwordError != null) {
      emit(state.copyWith(
        usernameError: usernameError,
        passwordError: passwordError,
      ));
      return;
    }

    // Submit - AuthCubit handles login, we ensure database init after
    emit(state.copyWith(isSubmitting: true, clearErrors: true));

    await _authCubit.login(
      username: state.username,
      password: state.password,
    );
  }

  Future<void> _onRegisterPressed(
    LoginRegisterPressed event,
    Emitter<LoginState> emit,
  ) async {
    if (_registerUrl != null) {
      await launchUrl(Uri.parse(_registerUrl!));
    }
  }
}

// Internal events for auth state changes
class _LoginAuthSuccess extends LoginEvent {
  const _LoginAuthSuccess();
}

class _LoginAuthError extends LoginEvent {
  final dynamic failure;
  const _LoginAuthError(this.failure);
}
