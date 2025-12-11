import 'package:flutter/material.dart';

import '../../core/constants/app_responsive.dart';
import 'app_button.dart';

/// Empty state widget
class AppEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? illustration;

  const AppEmptyState({
    super.key,
    this.title,
    this.message,
    this.actionText,
    this.onAction,
    this.icon,
    this.illustration,
  });

  /// Creates an empty state for "no data"
  factory AppEmptyState.noData({
    String? title,
    String? message,
    VoidCallback? onRefresh,
  }) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title ?? 'No Data',
      message: message ?? 'No items to display',
      actionText: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  /// Creates an empty state for search
  factory AppEmptyState.noResults({
    String? query,
    VoidCallback? onClear,
  }) {
    return AppEmptyState(
      icon: Icons.search_off,
      title: 'No Results',
      message: query != null ? 'No results found for "$query"' : 'No results found',
      actionText: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }

  /// Creates an empty state for error
  factory AppEmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: 'Error',
      message: message ?? 'Something went wrong',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Creates an empty state for network error
  factory AppEmptyState.noConnection({
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      icon: Icons.wifi_off,
      title: 'No Connection',
      message: 'Please check your internet connection',
      actionText: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return Center(
      child: Padding(
        padding: rSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(
                icon,
                size: rSizes.iconXxl,
                color: theme.disabledColor,
              ),
            rSpacing.gapVerticalLg,
            if (title != null)
              Text(
                title!,
                style: rTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
            if (message != null) ...[
              rSpacing.gapVerticalSm,
              Text(
                message!,
                style: rTypography.bodyMedium.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              rSpacing.gapVerticalLg,
              AppButton(
                text: actionText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
