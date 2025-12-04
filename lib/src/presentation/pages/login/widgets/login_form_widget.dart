import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../login_bloc.dart';
import '../login_event.dart';
import '../login_state.dart';

/// Login form with username and password fields
class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Username field
        _UsernameField(
          controller: _usernameController,
          l10n: l10n,
          theme: theme,
        ),
        SizedBox(height: AppSpacing.md),
        // Password field
        _PasswordField(
          controller: _passwordController,
          l10n: l10n,
          theme: theme,
        ),
        SizedBox(height: AppSpacing.xl),
        // Login button
        _LoginButton(l10n: l10n, theme: theme),
        SizedBox(height: AppSpacing.lg),
        // Register link
        _RegisterLink(l10n: l10n, theme: theme),
      ],
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _UsernameField({
    required this.controller,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, String?>(
      selector: (state) => state.usernameError,
      builder: (context, error) {
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n?.translate(LocaleKeys.username) ?? 'Username',
            hintText: l10n?.translate(LocaleKeys.pleaseEnterUsername) ?? 
                'Enter your username',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: error != null ? l10n?.translate(error) ?? error : null,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusSm,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            context.read<LoginBloc>().add(LoginUsernameChanged(value));
          },
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _PasswordField({
    required this.controller,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) =>
          previous.isPasswordVisible != current.isPasswordVisible ||
          previous.passwordError != current.passwordError,
      builder: (context, state) {
        return TextFormField(
          controller: controller,
          obscureText: !state.isPasswordVisible,
          decoration: InputDecoration(
            labelText: l10n?.translate(LocaleKeys.password) ?? 'Password',
            hintText: l10n?.translate(LocaleKeys.pleaseEnterPassword) ?? 
                'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible 
                    ? Icons.visibility 
                    : Icons.visibility_off,
              ),
              onPressed: () {
                context.read<LoginBloc>().add(
                  const LoginTogglePasswordVisibility(),
                );
              },
            ),
            errorText: state.passwordError != null 
                ? l10n?.translate(state.passwordError!) ?? state.passwordError 
                : null,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusSm,
            ),
          ),
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            context.read<LoginBloc>().add(LoginPasswordChanged(value));
          },
          onFieldSubmitted: (_) {
            context.read<LoginBloc>().add(const LoginSubmitted());
          },
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _LoginButton({
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginBloc, LoginState, bool>(
      selector: (state) => state.isSubmitting,
      builder: (context, isSubmitting) {
        return SizedBox(
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () {
                    context.read<LoginBloc>().add(const LoginSubmitted());
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusSm,
              ),
            ),
            child: isSubmitting
                ? SizedBox(
                    width: AppSizes.iconSm,
                    height: AppSizes.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    l10n?.translate(LocaleKeys.login) ?? 'Login',
                    style: AppTypography.button,
                  ),
          ),
        );
      },
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final AppLocalizations? l10n;
  final ThemeData theme;

  const _RegisterLink({
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n?.translate(LocaleKeys.noAccount) ?? "Don't have an account?",
          style: AppTypography.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            context.read<LoginBloc>().add(const LoginRegisterPressed());
          },
          child: Text(
            l10n?.translate(LocaleKeys.register) ?? 'Register',
            style: AppTypography.button.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}










