import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'app_sizes.dart';
import '../utils/responsive_utils.dart';

/// Responsive spacing that scales based on screen size
class ResponsiveSpacing {
  final BuildContext context;
  final double scale;

  ResponsiveSpacing(this.context) : scale = ResponsiveUtils.getScaleFactor(context);

  // Spacing values
  double get xxxs => ResponsiveUtils.scaleSpacing(context, AppSpacing.xxxs);
  double get xxs => ResponsiveUtils.scaleSpacing(context, AppSpacing.xxs);
  double get xs => ResponsiveUtils.scaleSpacing(context, AppSpacing.xs);
  double get sm => ResponsiveUtils.scaleSpacing(context, AppSpacing.sm);
  double get md => ResponsiveUtils.scaleSpacing(context, AppSpacing.md);
  double get lg => ResponsiveUtils.scaleSpacing(context, AppSpacing.lg);
  double get xl => ResponsiveUtils.scaleSpacing(context, AppSpacing.xl);
  double get xxl => ResponsiveUtils.scaleSpacing(context, AppSpacing.xxl);
  double get xxxl => ResponsiveUtils.scaleSpacing(context, AppSpacing.xxxl);

  // Padding
  EdgeInsets get paddingXxs => EdgeInsets.all(xxs);
  EdgeInsets get paddingXs => EdgeInsets.all(xs);
  EdgeInsets get paddingSm => EdgeInsets.all(sm);
  EdgeInsets get paddingMd => EdgeInsets.all(md);
  EdgeInsets get paddingLg => EdgeInsets.all(lg);
  EdgeInsets get paddingXl => EdgeInsets.all(xl);

  EdgeInsets get paddingHorizontalXs => EdgeInsets.symmetric(horizontal: xs);
  EdgeInsets get paddingHorizontalSm => EdgeInsets.symmetric(horizontal: sm);
  EdgeInsets get paddingHorizontalMd => EdgeInsets.symmetric(horizontal: md);
  EdgeInsets get paddingHorizontalLg => EdgeInsets.symmetric(horizontal: lg);

  EdgeInsets get paddingVerticalXs => EdgeInsets.symmetric(vertical: xs);
  EdgeInsets get paddingVerticalSm => EdgeInsets.symmetric(vertical: sm);
  EdgeInsets get paddingVerticalMd => EdgeInsets.symmetric(vertical: md);
  EdgeInsets get paddingVerticalLg => EdgeInsets.symmetric(vertical: lg);

  // Gaps
  SizedBox get gapXxs => SizedBox(width: xxs, height: xxs);
  SizedBox get gapXs => SizedBox(width: xs, height: xs);
  SizedBox get gapSm => SizedBox(width: sm, height: sm);
  SizedBox get gapMd => SizedBox(width: md, height: md);
  SizedBox get gapLg => SizedBox(width: lg, height: lg);
  SizedBox get gapXl => SizedBox(width: xl, height: xl);

  SizedBox get gapHorizontalXxs => SizedBox(width: xxs);
  SizedBox get gapHorizontalXs => SizedBox(width: xs);
  SizedBox get gapHorizontalSm => SizedBox(width: sm);
  SizedBox get gapHorizontalMd => SizedBox(width: md);
  SizedBox get gapHorizontalLg => SizedBox(width: lg);

  SizedBox get gapVerticalXxs => SizedBox(height: xxs);
  SizedBox get gapVerticalXs => SizedBox(height: xs);
  SizedBox get gapVerticalSm => SizedBox(height: sm);
  SizedBox get gapVerticalMd => SizedBox(height: md);
  SizedBox get gapVerticalLg => SizedBox(height: lg);
}

/// Responsive typography that scales based on screen size
class ResponsiveTypography {
  final BuildContext context;
  final double scale;

  ResponsiveTypography(this.context) : scale = ResponsiveUtils.getScaleFactor(context);

  // Font sizes
  double get fontSizeXxs => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeXxs);
  double get fontSizeXs => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeXs);
  double get fontSizeSm => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeSm);
  double get fontSizeMd => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeMd);
  double get fontSizeLg => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeLg);
  double get fontSizeXl => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeXl);
  double get fontSizeXxl => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeXxl);
  double get fontSizeDisplay => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeDisplay);
  double get fontSizeDisplayLg => ResponsiveUtils.scaleFontSize(context, AppTypography.fontSizeDisplayLg);

  // Text styles
  TextStyle get displayLarge => AppTypography.displayLarge.copyWith(fontSize: fontSizeDisplayLg);
  TextStyle get displayMedium => AppTypography.displayMedium.copyWith(fontSize: fontSizeDisplay);
  TextStyle get displaySmall => AppTypography.displaySmall.copyWith(fontSize: fontSizeXxl);
  TextStyle get headlineLarge => AppTypography.headlineLarge.copyWith(fontSize: fontSizeXxl);
  TextStyle get headlineMedium => AppTypography.headlineMedium.copyWith(fontSize: fontSizeXl);
  TextStyle get headlineSmall => AppTypography.headlineSmall.copyWith(fontSize: fontSizeLg);
  TextStyle get titleLarge => AppTypography.titleLarge.copyWith(fontSize: fontSizeLg);
  TextStyle get titleMedium => AppTypography.titleMedium.copyWith(fontSize: fontSizeMd);
  TextStyle get titleSmall => AppTypography.titleSmall.copyWith(fontSize: fontSizeSm);
  TextStyle get bodyLarge => AppTypography.bodyLarge.copyWith(fontSize: fontSizeMd);
  TextStyle get bodyMedium => AppTypography.bodyMedium.copyWith(fontSize: fontSizeSm);
  TextStyle get bodySmall => AppTypography.bodySmall.copyWith(fontSize: fontSizeXs);
  TextStyle get labelLarge => AppTypography.labelLarge.copyWith(fontSize: fontSizeSm);
  TextStyle get labelMedium => AppTypography.labelMedium.copyWith(fontSize: fontSizeXs);
  TextStyle get labelSmall => AppTypography.labelSmall.copyWith(fontSize: fontSizeXxs);
  TextStyle get caption => AppTypography.caption.copyWith(fontSize: fontSizeXs);
  TextStyle get button => AppTypography.button.copyWith(fontSize: fontSizeSm);
}

/// Responsive sizes that scale based on screen size
class ResponsiveSizes {
  final BuildContext context;
  final double scale;

  ResponsiveSizes(this.context) : scale = ResponsiveUtils.getScaleFactor(context);

  // Icon sizes
  double get iconXs => ResponsiveUtils.scaleIconSize(context, AppSizes.iconXs);
  double get iconSm => ResponsiveUtils.scaleIconSize(context, AppSizes.iconSm);
  double get iconMd => ResponsiveUtils.scaleIconSize(context, AppSizes.iconMd);
  double get iconLg => ResponsiveUtils.scaleIconSize(context, AppSizes.iconLg);
  double get iconXl => ResponsiveUtils.scaleIconSize(context, AppSizes.iconXl);
  double get iconXxl => ResponsiveUtils.scaleIconSize(context, AppSizes.iconXxl);

  // Avatar sizes
  double get avatarXs => ResponsiveUtils.scaleSize(context, AppSizes.avatarXs);
  double get avatarSm => ResponsiveUtils.scaleSize(context, AppSizes.avatarSm);
  double get avatarMd => ResponsiveUtils.scaleSize(context, AppSizes.avatarMd);
  double get avatarLg => ResponsiveUtils.scaleSize(context, AppSizes.avatarLg);
  double get avatarXl => ResponsiveUtils.scaleSize(context, AppSizes.avatarXl);
  double get avatarXxl => ResponsiveUtils.scaleSize(context, AppSizes.avatarXxl);

  // Button heights
  double get buttonHeight => ResponsiveUtils.scaleSize(context, AppSizes.buttonHeight);
  double get buttonHeightSm => ResponsiveUtils.scaleSize(context, AppSizes.buttonHeightSm);
  double get buttonHeightMd => ResponsiveUtils.scaleSize(context, AppSizes.buttonHeightMd);
  double get buttonHeightLg => ResponsiveUtils.scaleSize(context, AppSizes.buttonHeightLg);
  double get buttonHeightXl => ResponsiveUtils.scaleSize(context, AppSizes.buttonHeightXl);

  // Input heights
  double get inputHeight => ResponsiveUtils.scaleSize(context, AppSizes.inputHeight);
  double get inputHeightSm => ResponsiveUtils.scaleSize(context, AppSizes.inputHeightSm);
  double get inputHeightMd => ResponsiveUtils.scaleSize(context, AppSizes.inputHeightMd);
  double get inputHeightLg => ResponsiveUtils.scaleSize(context, AppSizes.inputHeightLg);

  // AppBar height
  double get appBarHeight => ResponsiveUtils.scaleSize(context, AppSizes.appBarHeight);
  double get appBarHeightLarge => ResponsiveUtils.scaleSize(context, AppSizes.appBarHeightLarge);

  // Bottom navigation height
  double get bottomNavHeight => ResponsiveUtils.scaleSize(context, AppSizes.bottomNavHeight);

  // Card sizes
  double get cardMinHeight => ResponsiveUtils.scaleSize(context, AppSizes.cardMinHeight);
  double get cardMaxWidth => ResponsiveUtils.scaleSize(context, AppSizes.cardMaxWidth);

  // Modal sizes
  double get modalWidthSm => ResponsiveUtils.scaleSize(context, AppSizes.modalWidthSm);
  double get modalWidthMd => ResponsiveUtils.scaleSize(context, AppSizes.modalWidthMd);
  double get modalWidthLg => ResponsiveUtils.scaleSize(context, AppSizes.modalWidthLg);
  double get modalWidthXl => ResponsiveUtils.scaleSize(context, AppSizes.modalWidthXl);

  // Sidebar width
  double get sidebarWidth => ResponsiveUtils.scaleSize(context, AppSizes.sidebarWidth);
  double get sidebarWidthCollapsed => ResponsiveUtils.scaleSize(context, AppSizes.sidebarWidthCollapsed);

  // Divider
  double get dividerThickness => ResponsiveUtils.scaleSize(context, AppSizes.dividerThickness);
  double get dividerThicknessBold => ResponsiveUtils.scaleSize(context, AppSizes.dividerThicknessBold);

  // Touch target minimum
  double get minTouchTarget => ResponsiveUtils.scaleSize(context, AppSizes.minTouchTarget);

  // Illustration sizes
  double get illustrationXs => ResponsiveUtils.scaleSize(context, AppSizes.illustrationXs);
  double get illustrationSm => ResponsiveUtils.scaleSize(context, AppSizes.illustrationSm);
  double get illustrationMd => ResponsiveUtils.scaleSize(context, AppSizes.illustrationMd);
  double get illustrationLg => ResponsiveUtils.scaleSize(context, AppSizes.illustrationLg);
  double get illustrationXl => ResponsiveUtils.scaleSize(context, AppSizes.illustrationXl);

  // Logo sizes
  double get logoSm => ResponsiveUtils.scaleSize(context, AppSizes.logoSm);
  double get logoMd => ResponsiveUtils.scaleSize(context, AppSizes.logoMd);
  double get logoLg => ResponsiveUtils.scaleSize(context, AppSizes.logoLg);

  // Product grid
  double get productGridItemWidth => ResponsiveUtils.scaleSize(context, AppSizes.productGridItemWidth);
  double get productGridItemHeight => ResponsiveUtils.scaleSize(context, AppSizes.productGridItemHeight);

  // List item
  double get listItemHeight => ResponsiveUtils.scaleSize(context, AppSizes.listItemHeight);
  double get listItemHeightSm => ResponsiveUtils.scaleSize(context, AppSizes.listItemHeightSm);
  double get listItemHeightLg => ResponsiveUtils.scaleSize(context, AppSizes.listItemHeightLg);
}

/// Extension methods for easy access to responsive values
extension ResponsiveExtension on BuildContext {
  ResponsiveSpacing get rSpacing => ResponsiveSpacing(this);
  ResponsiveTypography get rTypography => ResponsiveTypography(this);
  ResponsiveSizes get rSizes => ResponsiveSizes(this);
  double get rScale => ResponsiveUtils.getScaleFactor(this);
}

