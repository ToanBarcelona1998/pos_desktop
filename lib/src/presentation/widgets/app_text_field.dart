import 'package:flutter/material.dart';

import '../../core/constants/app_responsive.dart';
import '../../core/constants/app_radius.dart';

/// Text field with app styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      maxLines: maxLines,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      style: rTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusSm,
          borderSide: BorderSide(color: theme.disabledColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: rSpacing.md,
          vertical: rSpacing.sm,
        ),
      ),
    );
  }
}

/// Search text field
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmit;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
      style: rTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        prefixIcon: Icon(Icons.search, size: rSizes.iconMd),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: Icon(Icons.clear, size: rSizes.iconMd),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: rSpacing.md,
          vertical: rSpacing.sm,
        ),
      ),
    );
  }
}
