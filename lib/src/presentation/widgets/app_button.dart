import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_radius.dart';

/// Primary button with app styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = foregroundColor ?? colorScheme.onPrimary;

    final buttonHeight = height ?? AppSizes.buttonHeight;

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: bgColor),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusSm,
            ),
          ),
          child: _buildChild(bgColor, fgColor, isOutlined: true),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusSm,
          ),
          elevation: 2,
        ),
        child: _buildChild(bgColor, fgColor),
      ),
    );
  }

  Widget _buildChild(Color bgColor, Color fgColor, {bool isOutlined = false}) {
    final textColor = isOutlined ? bgColor : fgColor;

    if (isLoading) {
      return SizedBox(
        width: AppSizes.iconSm,
        height: AppSizes.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: textColor),
          SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.button.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTypography.button.copyWith(color: textColor),
    );
  }
}

/// Text button with app styling
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: buttonColor),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppTypography.button.copyWith(color: buttonColor),
          ),
        ],
      ),
    );
  }
}

/// Icon button with app styling
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;
    final iconSize = size ?? AppSizes.iconMd;

    Widget button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize, color: iconColor),
      style: backgroundColor != null
          ? IconButton.styleFrom(backgroundColor: backgroundColor)
          : null,
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
