import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';

class IconWrapper extends StatelessWidget {
  final IconData icon;
  final double ? iconSize;
  final double ? wrapperSize;
  final Color iconColor;
  final Color backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String ?tooltip;

  const IconWrapper({
    super.key,
    required this.icon,
    this.iconSize,
    this.wrapperSize,
    this.iconColor = Colors.blueAccent,
    this.backgroundColor = Colors.white,
    this.borderRadius = 8.0,
    this.boxShadow,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final responseSize = ResponsiveSizes(context);

    final iSize = iconSize ?? responseSize.iconXs;
    final iWrapSize = wrapperSize ?? iSize * 2;
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
        width: iWrapSize,
        height: iWrapSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: defaultBoxShadow,
        ),
        child: Icon(
          icon,
          size: iSize,
          color: iconColor,
        ),
      ),
    );
  }
}