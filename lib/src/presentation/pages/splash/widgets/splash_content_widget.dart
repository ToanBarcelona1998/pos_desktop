import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Splash screen content
class SplashContentWidget extends StatelessWidget {
  const SplashContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: AppSizes.illustrationLg,
                height: AppSizes.illustrationLg,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.store,
                  size: AppSizes.iconXxl * 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              // App name
              Text(
                'POS System',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Point of Sale',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              // Loading indicator
              SizedBox(
                width: AppSizes.iconLg,
                height: AppSizes.iconLg,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



