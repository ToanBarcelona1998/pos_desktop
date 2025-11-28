import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_final/constants.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';

import 'view_model_manger/login_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginFailed) {
            LoginCubit.get(context).isLoading = false;
            Fluttertoast.showToast(
              fontSize: 18,
              backgroundColor: Colors.red,
              msg: AppLocalizations.of(context).translate('invalid_credentials'),
            );
          } else if (state is LoginSuccessfully) {
            LoginCubit.get(context).navigateToHome(context);
          }
        },
        builder: (context, state) {
          var cubit = LoginCubit.get(context);
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF583C8F),
                    kDefaultColor.withOpacity(0.85),
                    kDefaultColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Subtle background effect
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: 0.15,
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            radius: 1.2,
                            center: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
                        child: Card(
                          elevation: 0,
                          color: Colors.white.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Form(
                              key: cubit.formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Lottie Animation with scale animation
                                    AnimatedScale(
                                      scale: cubit.isLoading ? 0.9 : 1.0,
                                      duration: const Duration(milliseconds: 500),
                                      child: Lottie.asset(
                                        'assets/lottie/welcome.json',
                                        height: 140,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // App Name with fade animation
                                    AnimatedOpacity(
                                      opacity: cubit.isLoading ? 0.7 : 1.0,
                                      duration: const Duration(milliseconds: 500),
                                      child: Text(
                                        'Ashal Erp',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: kDefaultColor.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    // Username Field
                                    TextFormField(
                                      style: AppTheme.getTextStyle(
                                        cubit.themeData.textTheme.bodyLarge,
                                        letterSpacing: 0.2,
                                        color: Colors.white,
                                        fontWeight: 500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context).translate('username'),
                                        hintStyle: AppTheme.getTextStyle(
                                          cubit.themeData.textTheme.titleSmall,
                                          letterSpacing: 0.2,
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: 500,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: kDefaultColor,
                                            width: 2,
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          MdiIcons.faceMan,
                                          color: Colors.white,
                                        ),
                                      ),
                                      controller: cubit.usernameController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(context).translate('please_enter_username');
                                        }
                                        return null;
                                      },
                                      autofocus: true,
                                    ),
                                    const SizedBox(height: 24),
                                    // Password Field
                                    TextFormField(
                                      keyboardType: TextInputType.visiblePassword,
                                      style: AppTheme.getTextStyle(
                                        cubit.themeData.textTheme.bodyLarge,
                                        letterSpacing: 0.2,
                                        color: Colors.white,
                                        fontWeight: 500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context).translate('password'),
                                        hintStyle: AppTheme.getTextStyle(
                                          cubit.themeData.textTheme.titleSmall,
                                          letterSpacing: 0.2,
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: 500,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: kDefaultColor,
                                            width: 2,
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          MdiIcons.lock,
                                          color: Colors.white,
                                        ),
                                        suffixIcon: IconButton(
                                          color: Colors.white,
                                          icon: Icon(
                                            cubit.passwordVisible
                                                ? MdiIcons.eye
                                                : MdiIcons.eyeOff,
                                          ),
                                          onPressed: () {
                                            cubit.passwordVisible = !cubit.passwordVisible;
                                          },
                                        ),
                                      ),
                                      obscureText: !cubit.passwordVisible,
                                      controller: cubit.passwordController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(context).translate('please_enter_password');
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 40),
                                    // Login Button
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              kDefaultColor,
                                              kDefaultColor.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: kDefaultColor.withOpacity(0.5),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: cubit.isLoading
                                              ? null
                                              : () async {
                                            await cubit.checkOnLogin(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 48,
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: cubit.isLoading
                                              ? const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                              : Text(
                                            AppLocalizations.of(context).translate('login'),
                                            style: AppTheme.getTextStyle(
                                              cubit.themeData.textTheme.labelLarge,
                                              color: Colors.white,
                                              fontWeight: 700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Quick Login Button
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.blue.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.5),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: cubit.isLoading
                                              ? null
                                              : () async {
                                            cubit.usernameController.text = 'admin';
                                            cubit.passwordController.text = '123456';
                                            await cubit.checkOnLogin(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 48,
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: cubit.isLoading
                                              ? const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                              : Text(
                                            AppLocalizations.of(context).translate('quick_login'),
                                            style: AppTheme.getTextStyle(
                                              cubit.themeData.textTheme.labelLarge,
                                              color: Colors.white,
                                              fontWeight: 700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // No Account Text
                                    AnimatedOpacity(
                                      opacity: cubit.isLoading ? 0.7 : 1.0,
                                      duration: const Duration(milliseconds: 500),
                                      child: Text(
                                        AppLocalizations.of(context).translate('no_account'),
                                        style: AppTheme.getTextStyle(
                                          cubit.themeData.textTheme.bodyLarge,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: 500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Register Button
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            await cubit.register();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 48,
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context).translate('register'),
                                            style: AppTheme.getTextStyle(
                                              cubit.themeData.textTheme.labelLarge,
                                              color: Colors.white,
                                              fontWeight: 700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}