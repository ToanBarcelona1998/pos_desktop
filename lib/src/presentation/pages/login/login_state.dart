import 'package:domain/domain.dart';

/// Login page state
class LoginState {
  final String username;
  final String password;
  final bool isPasswordVisible;
  final bool isLoading;
  final bool isSubmitting;
  final String? usernameError;
  final String? passwordError;
  final Failure? failure;
  final bool isSuccess;

  const LoginState({
    this.username = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.usernameError,
    this.passwordError,
    this.failure,
    this.isSuccess = false,
  });

  /// Initial state
  factory LoginState.initial() => const LoginState();

  /// Check if form is valid
  bool get isFormValid =>
      username.isNotEmpty &&
      password.isNotEmpty &&
      usernameError == null &&
      passwordError == null;

  /// Check if can submit
  bool get canSubmit => isFormValid && !isLoading && !isSubmitting;

  /// Copy with
  LoginState copyWith({
    String? username,
    String? password,
    bool? isPasswordVisible,
    bool? isLoading,
    bool? isSubmitting,
    String? usernameError,
    String? passwordError,
    Failure? failure,
    bool? isSuccess,
    bool clearErrors = false,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      usernameError: clearErrors ? null : (usernameError ?? this.usernameError),
      passwordError: clearErrors ? null : (passwordError ?? this.passwordError),
      failure: clearErrors ? null : (failure ?? this.failure),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}










