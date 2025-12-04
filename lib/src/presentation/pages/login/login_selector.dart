import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_bloc.dart';
import 'login_state.dart';

/// Selector for username error
class UsernameErrorSelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? error) builder;

  const UsernameErrorSelector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, String?>(
      selector: (state) => state.usernameError,
      builder: builder,
    );
  }
}

/// Selector for password error
class PasswordErrorSelector extends StatelessWidget {
  final Widget Function(BuildContext context, String? error) builder;

  const PasswordErrorSelector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, String?>(
      selector: (state) => state.passwordError,
      builder: builder,
    );
  }
}

/// Selector for password visibility
class PasswordVisibilitySelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isVisible) builder;

  const PasswordVisibilitySelector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, bool>(
      selector: (state) => state.isPasswordVisible,
      builder: builder,
    );
  }
}

/// Selector for submitting state
class SubmittingSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool isSubmitting) builder;

  const SubmittingSelector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, bool>(
      selector: (state) => state.isSubmitting,
      builder: builder,
    );
  }
}

/// Selector for can submit
class CanSubmitSelector extends StatelessWidget {
  final Widget Function(BuildContext context, bool canSubmit) builder;

  const CanSubmitSelector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, bool>(
      selector: (state) => state.canSubmit,
      builder: builder,
    );
  }
}








