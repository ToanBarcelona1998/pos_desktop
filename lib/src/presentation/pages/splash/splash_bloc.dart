import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../application/auth/auth_cubit.dart';
import '../../../application/auth/auth_state.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// Splash page bloc
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AuthCubit _authCubit;
  static const String _onBoardingKey = 'onboarding_complete';
  StreamSubscription? _authSubscription;

  SplashBloc({
    required AuthCubit authCubit,
  })  : _authCubit = authCubit,
        super(const SplashLoading()) {
    on<SplashInitialize>(_onInitialize);
    on<SplashCheckAuth>(_onCheckAuth);
    on<_SplashAuthChecked>(_onAuthChecked);

    // Listen to auth state changes
    _authSubscription = _authCubit.stream.listen((authState) {
      if (authState is Authenticated || authState is Unauthenticated) {
        add(_SplashAuthChecked(authState));
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitialize(
    SplashInitialize event,
    Emitter<SplashState> emit,
  ) async {
    // Simulate loading delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if onboarding is complete
    final prefs = await SharedPreferences.getInstance();
    final onBoardingComplete = prefs.getBool(_onBoardingKey) ?? false;

    if (!onBoardingComplete) {
      emit(const SplashNavigateToOnBoarding());
      return;
    }

    // Check authentication - AuthCubit handles init database
    add(const SplashCheckAuth());
  }

  Future<void> _onCheckAuth(
    SplashCheckAuth event,
    Emitter<SplashState> emit,
  ) async {
    // Trigger auth check - this will init database if authenticated
    await _authCubit.checkAuthentication();
  }

  void _onAuthChecked(
    _SplashAuthChecked event,
    Emitter<SplashState> emit,
  ) {
    if (event.authState is Authenticated) {
      // Database already initialized by AuthCubit
      emit(const SplashNavigateToHome());
    } else {
      emit(const SplashNavigateToLogin());
    }
  }
}

// Internal event
class _SplashAuthChecked extends SplashEvent {
  final AuthState authState;
  const _SplashAuthChecked(this.authState);
}
