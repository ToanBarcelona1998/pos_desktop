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

/// Gradient button with app styling
class AppGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leading;
  final Widget? suffix;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final TextStyle? textStyle;

  const AppGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leading,
    this.suffix,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = gradient ??
        LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

    final buttonHeight = height ?? AppSizes.buttonHeight;
    final buttonPadding = padding ?? EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    );
    final buttonBorderRadius = borderRadius ?? AppRadius.borderRadiusSm;

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: buttonBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading ? null : defaultGradient,
            color: isLoading ? Colors.grey : null,
            borderRadius: buttonBorderRadius,
          ),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            child: Container(
              padding: buttonPadding,
              alignment: Alignment.center,
              child: _buildChild(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: AppSizes.iconSm,
        height: AppSizes.iconSm,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final defaultTextStyle = textStyle ??
        AppTypography.button.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        );

    if (leading != null || suffix != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: defaultTextStyle,
          ),
          if (suffix != null) ...[
            SizedBox(width: AppSpacing.xs),
            suffix!,
          ],
        ],
      );
    }

    return Text(
      text,
      style: defaultTextStyle,
    );
  }
}

/// Column layout button with icon on top and text below
class AppColumnButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? suffix;
  final double? width;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const AppColumnButton({
    super.key,
    required this.text,
    this.onPressed,
    this.leading,
    this.suffix,
    this.width,
    this.backgroundColor,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? Colors.transparent;
    final defaultTextStyle = textStyle ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.grey[800],
          fontSize: 14,
        );
    final buttonPadding = padding ?? const EdgeInsets.all(12);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderRadiusSm,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.borderRadiusSm,
          ),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: buttonPadding,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: defaultTextStyle,
                  ),
                  if (suffix != null) ...[
                    const SizedBox(height: 4),
                    suffix!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
