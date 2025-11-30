import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_config/app_config.dart';
import '../../../../app_config/di.dart';
import '../../../application/auth/auth_cubit.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/navigation/route_path.dart';
import 'login_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'widgets/login_form_widget.dart';
import 'widgets/login_header_widget.dart';

/// Login page
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = sl.get<AppConfig>();

    return BlocProvider(
      create: (context) => LoginBloc(
        authCubit: context.read<AuthCubit>(),
        databaseHelper: sl.get<DatabaseHelper>(),
        syncService: sl.get<SystemSyncService>(),
        registerUrl: '${config.baseUrl}/business/register',
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          previous.isSuccess != current.isSuccess ||
          previous.failure != current.failure,
      listener: (context, state) {
        if (state.isSuccess) {
          // Navigate to home - database already initialized by LoginBloc
          AppNavigator.pushReplacementNamed(RoutePath.layout.path);
        } else if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.translate(LocaleKeys.invalidCredentials) ??
                    'Invalid credentials',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.xxl),
                const LoginHeaderWidget(),
                SizedBox(height: AppSpacing.xl),
                const LoginFormWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
