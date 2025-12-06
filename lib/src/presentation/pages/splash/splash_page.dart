import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/auth/auth_cubit.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/navigation/route_path.dart';
import 'splash_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';
import 'widgets/splash_content_widget.dart';

/// Splash page
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc(
        authCubit: context.read<AuthCubit>(),
      )..add(const SplashInitialize()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        switch (state) {
          case SplashNavigateToLogin():
            AppNavigator.pushReplacementNamed(RoutePath.login.path);
          case SplashNavigateToHome():
            // Database already initialized by AuthCubit.checkAuthentication()
            AppNavigator.pushReplacementNamed(RoutePath.layout.path);
          case SplashNavigateToOnBoarding():
            AppNavigator.pushReplacementNamed(RoutePath.onBoarding.path);
          case SplashLoading():
            break;
        }
      },
      child: const Scaffold(
        body: SplashContentWidget(),
      ),
    );
  }
}
