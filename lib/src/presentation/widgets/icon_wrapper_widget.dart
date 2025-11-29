import 'package:flutter/material.dart';

class IconWrapper extends StatelessWidget {
  final IconData icon;
  final double iconSize; // Kích thước của Icon
  final double wrapperSize; // Kích thước tổng thể của Container bọc ngoài
  final Color iconColor;
  final Color backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

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
  })  : iconSize = iconSize ?? 20.0,
  // Đảm bảo wrapperSize đủ lớn để chứa icon và padding.
  // Mặc định: iconSize + 16 (8 padding mỗi bên)
        wrapperSize = wrapperSize ?? (iconSize ?? 20.0) + 16.0;

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