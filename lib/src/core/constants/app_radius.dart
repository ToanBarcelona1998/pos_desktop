import 'package:flutter/material.dart';

/// Application radius constants
abstract final class AppRadius {
  // Radius values
  static const double none = 0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // BorderRadius
  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(full));

  // Top only
  static const BorderRadius borderRadiusTopSm = BorderRadius.vertical(top: Radius.circular(sm));
  static const BorderRadius borderRadiusTopMd = BorderRadius.vertical(top: Radius.circular(md));
  static const BorderRadius borderRadiusTopLg = BorderRadius.vertical(top: Radius.circular(lg));

  // Bottom only
  static const BorderRadius borderRadiusBottomSm = BorderRadius.vertical(bottom: Radius.circular(sm));
  static const BorderRadius borderRadiusBottomMd = BorderRadius.vertical(bottom: Radius.circular(md));
  static const BorderRadius borderRadiusBottomLg = BorderRadius.vertical(bottom: Radius.circular(lg));

  // Radius for shapes
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
}








