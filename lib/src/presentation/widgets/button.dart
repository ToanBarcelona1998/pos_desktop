import 'package:flutter/material.dart';

class _AppButton extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? suffix;
  final TextStyle? textStyle;

  final Color? color;
  final Color? disableColor;
  final Gradient? gradient;

  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double? minWidth;

  final bool disabled;
  final bool loading;
  final bool isColumnLayout;

  final void Function()? onPress;

  final Color? borderColor;

  _AppButton({
    super.key,
    required this.text,
    this.onPress,
    this.color,
    this.borderColor,
    this.disableColor,
    this.gradient,
    this.minWidth,
    this.leading,
    this.suffix,
    bool? loading,
    bool? disabled,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool? isColumnLayout,
    this.textStyle,
  })  : assert(color == null || gradient == null),
        loading = loading ?? false,
        disabled = (disabled ?? false) || (loading ?? false),
        isColumnLayout = isColumnLayout ?? false,
        padding = padding ??
            (isColumnLayout == true
                ? const EdgeInsets.all(8)
                : const EdgeInsets.all(16)),
        borderRadius = borderRadius ?? BorderRadius.circular(999);

  @override
  Widget build(BuildContext context) {
    final actualDisableColor = disableColor ??
        (color != null
            ? color!.withAlpha((255.0 * 0.3).round())
            : Colors.white12);

    final actualColor = disabled ? actualDisableColor : color;
    final decoration = BoxDecoration(
      color: (gradient == null || disabled) ? actualColor : null,
      gradient: disabled ? null : gradient,
      borderRadius: borderRadius,
      border: borderColor != null
          ? Border.all(
              color: disabled
                  ? borderColor!.withAlpha((255.0 * 0.3).round())
                  : borderColor!,
            )
          : null,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          splashColor: Colors.white.withAlpha((255.0 * 0.3).round()),
          highlightColor: Colors.white.withAlpha((255.0 * 0.1).round()),
          onTap: disabled ? null : onPress,
          child: Container(
            constraints:
                minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
            padding: padding,
            alignment: Alignment.center,
            child: loading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : isColumnLayout
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          leading ?? const SizedBox.shrink(),
                          if (leading != null) const SizedBox(height: 2),
                          Text(
                            text,
                            textAlign: TextAlign.center,
                            style: textStyle,
                          ),
                          if (suffix != null) const SizedBox(height: 2),
                          suffix ?? const SizedBox.shrink(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          leading ?? const SizedBox.shrink(),
                          if (leading != null) const SizedBox(width: 12),
                          Text(
                            text,
                            style: textStyle,
                          ),
                          if (suffix != null) const SizedBox(width: 12),
                          suffix ?? const SizedBox.shrink(),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

final class PrimaryAppButton extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? suffix;
  final bool? isDisable;
  final VoidCallback? onPress;
  final double? minWidth;
  final Color? backGroundColor;
  final TextStyle? textStyle;
  final bool loading;
  final EdgeInsets? padding;

  const PrimaryAppButton({
    super.key,
    required this.text,
    this.isDisable,
    this.leading,
    this.suffix,
    this.onPress,
    this.minWidth,
    this.backGroundColor,
    this.textStyle,
    this.loading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = backGroundColor ?? Colors.blueAccent;

    return _AppButton(
      text: text,
      disabled: isDisable,
      onPress: onPress,
      color: defaultColor,
      disableColor: defaultColor.withAlpha((255.0 * 0.3).round()),
      minWidth: minWidth,
      textStyle: textStyle ??
          TextStyle(
            fontWeight: FontWeight.w500,
            color: isDisable == true ? Colors.white54 : Colors.white,
            fontSize: 14,
          ),
      leading: leading,
      suffix: suffix,
      loading: loading,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(8),
    );
  }
}

final class BorderAppButton extends StatelessWidget {
  final String text;
  final bool? isDisable;
  final VoidCallback? onPress;
  final double? minWidth;
  final Color? borderColor;
  final Color? textColor;
  final Widget? leading;
  final Widget? suffix;
  final TextStyle? textStyle;

  const BorderAppButton({
    super.key,
    required this.text,
    this.isDisable,
    this.onPress,
    this.minWidth,
    this.borderColor,
    this.textColor,
    this.leading,
    this.suffix,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? Colors.blueAccent;

    return _AppButton(
      text: text,
      disabled: isDisable,
      onPress: onPress,
      minWidth: minWidth,
      color: Colors.transparent,
      borderColor: defaultBorderColor,
      disableColor: Colors.transparent,
      textStyle: textStyle ??
          TextStyle(
            fontWeight: FontWeight.w500,
            color: isDisable == true
                ? defaultBorderColor.withAlpha((255.0 * 0.5).round())
                : (textColor ?? defaultBorderColor),
            fontSize: 24,
          ),
      suffix: suffix,
      leading: leading,
    );
  }
}

final class TextAppButton extends StatelessWidget {
  final String text;
  final bool? isDisable;
  final VoidCallback? onPress;
  final double? minWidth;
  final Widget? leading;
  final Widget? suffix;
  final TextStyle? style;
  final EdgeInsets ?padding;

  const TextAppButton({
    super.key,
    required this.text,
    this.style,
    this.isDisable,
    this.onPress,
    this.minWidth,
    this.leading,
    this.suffix,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return _AppButton(
      text: text,
      disabled: isDisable,
      onPress: onPress,
      color: Colors.transparent,
      minWidth: minWidth,
      textStyle: style,
      suffix: suffix,
      leading: leading,
      disableColor: Colors.transparent,
      padding: padding,
    );
  }
}

final class GradientAppButton extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? suffix;
  final bool? isDisable;
  final VoidCallback? onPress;
  final double? minWidth;
  final TextStyle? textStyle;
  final bool loading;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const GradientAppButton({
    super.key,
    required this.text,
    this.isDisable,
    this.leading,
    this.suffix,
    this.onPress,
    this.minWidth,
    this.textStyle,
    this.loading = false,
    this.padding,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    const defaultGradient = LinearGradient(
      colors: [
        Color(0xFF2053ba),
        Color(0xff6982b8),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final defaultTextStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: isDisable == true ? Colors.white30 : Colors.white,
      fontSize: 20,
    );
    return _AppButton(
      text: text,
      disabled: isDisable,
      onPress: onPress,
      gradient: gradient ?? defaultGradient,
      minWidth: minWidth,
      textStyle: textStyle ?? defaultTextStyle,
      leading: leading,
      suffix: suffix,
      loading: loading,
      padding: padding,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

final class ColumnAppButton extends StatelessWidget {
  final String text;
  final Widget? leading;
  final Widget? suffix;
  final bool? isDisable;
  final VoidCallback? onPress;
  final double? minWidth;
  final Color? backGroundColor;
  final TextStyle? textStyle;
  final bool loading;
  final EdgeInsets? padding;

  const ColumnAppButton({
    super.key,
    required this.text,
    this.isDisable,
    this.leading,
    this.suffix,
    this.onPress,
    this.minWidth,
    this.backGroundColor,
    this.textStyle,
    this.loading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = backGroundColor ?? Colors.transparent;

    return _AppButton(
      text: text,
      isColumnLayout: true,
      disabled: isDisable,
      onPress: onPress,
      color: defaultColor,
      disableColor: defaultColor.withAlpha((255.0 * 0.3).round()),
      minWidth: minWidth,
      textStyle: textStyle ??
          TextStyle(
            fontWeight: FontWeight.w700,
            color: isDisable == true ? Colors.grey : Color(0xff505d78),
            fontSize: 14,
          ),
      leading: leading,
      suffix: suffix,
      loading: loading,
      padding: padding ?? const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
