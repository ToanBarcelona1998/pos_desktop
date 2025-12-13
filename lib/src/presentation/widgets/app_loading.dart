import 'package:flutter/material.dart';

import '../../core/constants/app_responsive.dart';
import '../../core/constants/app_radius.dart';

/// Loading indicator with app styling
class AppLoading extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const AppLoading({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSizes = context.rSizes;

    return SizedBox(
      width: size ?? rSizes.iconLg,
      height: size ?? rSizes.iconLg,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(color ?? theme.colorScheme.primary),
      ),
    );
  }
}

/// Centered loading widget
class AppLoadingCenter extends StatelessWidget {
  final String? message;

  const AppLoadingCenter({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoading(),
          if (message != null) ...[
            rSpacing.gapVerticalMd,
            Text(message!, style: rTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const AppLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black54,
      child: AppLoadingCenter(message: message),
    );
  }
}

/// Loading dialog
class AppLoadingDialog extends StatelessWidget {
  final String? message;

  const AppLoadingDialog({
    super.key,
    this.message,
  });

  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Padding(
        padding: rSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoading(size: rSizes.iconXl),
            if (message != null) ...[
              rSpacing.gapVerticalMd,
              Text(
                message!,
                style: rTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class AppShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.borderRadiusSm,
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}
