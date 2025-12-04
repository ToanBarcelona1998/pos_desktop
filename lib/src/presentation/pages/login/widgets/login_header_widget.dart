import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';

/// Login page header with logo and welcome text
class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: AppSizes.illustrationMd,
          height: AppSizes.illustrationMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.store,
            size: AppSizes.iconXxl,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        // Welcome text
        Text(
          l10n?.translate(LocaleKeys.welcome) ?? 'Welcome',
          style: AppTypography.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.translate(LocaleKeys.logIn) ?? 'Log in to continue',
          style: AppTypography.bodyLarge.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}








