import 'package:flutter/material.dart';

import '../../core/constants/app_responsive.dart';
import '../../core/constants/app_radius.dart';

/// Card with app styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;

    return Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: elevation ?? 1,
      color: backgroundColor ?? theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.borderRadiusMd,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppRadius.borderRadiusMd,
        child: Padding(
          padding: padding ?? rSpacing.paddingMd,
          child: child,
        ),
      ),
    );
  }
}

/// List tile card
class AppListTileCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: rTypography.titleMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: rTypography.bodySmall.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              )
            : null,
        trailing: trailing,
        contentPadding: EdgeInsets.symmetric(
          horizontal: rSpacing.md,
          vertical: rSpacing.xs,
        ),
      ),
    );
  }
}

/// Statistics card
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return AppCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: rSizes.iconMd,
            ),
          rSpacing.gapVerticalSm,
          Text(
            value,
            style: rTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          rSpacing.gapVerticalXxs,
          Text(
            title,
            style: rTypography.bodySmall.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
