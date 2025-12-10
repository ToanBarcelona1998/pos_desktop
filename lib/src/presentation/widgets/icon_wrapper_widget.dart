import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';

class IconWrapper extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double wrapperSize;
  final Color iconColor;
  final Color backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String ?tooltip;

  const IconWrapper({
    super.key,
    required this.icon,
    double? iconSize,
    double? wrapperSize,
    this.iconColor = Colors.blueAccent,
    this.backgroundColor = Colors.white,
    this.borderRadius = 8.0,
    this.boxShadow,
    this.onTap,
    this.tooltip,
  })  : iconSize = iconSize ?? AppSizes.iconXs,
        wrapperSize = wrapperSize ?? (iconSize ?? AppSizes.iconXs) + AppSizes.iconXs;

  @override
  Widget build(BuildContext context) {
    final defaultBoxShadow = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withAlpha((0.2 * 255).round()),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: wrapperSize,
        height: wrapperSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: defaultBoxShadow,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}