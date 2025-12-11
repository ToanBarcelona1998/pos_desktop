# Responsive Sizing Guide

This guide explains how to use the responsive sizing system in the app to ensure flexible layouts that work across different screen sizes, especially for POS devices and windows.

## Overview

The responsive system automatically scales spacing, typography, and sizes based on screen dimensions. It uses a base design size (1920x1080) and scales down/up proportionally while maintaining minimum and maximum scale limits (0.7x to 1.3x).

## Usage

### Basic Usage

Access responsive values through extension methods on `BuildContext`:

```dart
@override
Widget build(BuildContext context) {
  final rSpacing = context.rSpacing;      // Responsive spacing
  final rTypography = context.rTypography; // Responsive typography
  final rSizes = context.rSizes;          // Responsive sizes
  
  return Container(
    padding: rSpacing.paddingMd,
    child: Text(
      'Hello',
      style: rTypography.bodyMedium,
    ),
  );
}
```

### Spacing

Replace `AppSpacing` with `context.rSpacing`:

```dart
// Before
SizedBox(width: AppSpacing.sm)
EdgeInsets.all(AppSpacing.paddingMd)

// After
context.rSpacing.gapHorizontalSm
context.rSpacing.paddingMd
```

### Typography

Replace `AppTypography` with `context.rTypography`:

```dart
// Before
Text('Hello', style: AppTypography.bodyMedium)

// After
Text('Hello', style: context.rTypography.bodyMedium)
```

### Sizes

Replace `AppSizes` with `context.rSizes`:

```dart
// Before
Icon(Icons.home, size: AppSizes.iconSm)

// After
Icon(Icons.home, size: context.rSizes.iconSm)
```

### Direct Scaling

For custom values, use `ResponsiveUtils.scale()`:

```dart
final customSize = ResponsiveUtils.scale(context, 100.0);
```

## Migration Checklist

When updating a widget to use responsive sizing:

1. ✅ Add responsive variables at the start of `build()`:
   ```dart
   final rSpacing = context.rSpacing;
   final rTypography = context.rTypography;
   final rSizes = context.rSizes;
   ```

2. ✅ Replace all `AppSpacing.*` with `rSpacing.*`
3. ✅ Replace all `AppTypography.*` with `rTypography.*`
4. ✅ Replace all `AppSizes.*` with `rSizes.*`
5. ✅ Replace `SizedBox(width: AppSpacing.x)` with `rSpacing.gapHorizontalX`
6. ✅ Replace `SizedBox(height: AppSpacing.x)` with `rSpacing.gapVerticalX`

## Example: Complete Widget Migration

**Before:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      child: Column(
        children: [
          Text('Title', style: AppTypography.titleLarge),
          SizedBox(height: AppSpacing.sm),
          Icon(Icons.home, size: AppSizes.iconMd),
        ],
      ),
    );
  }
}
```

**After:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;
    
    return Container(
      padding: rSpacing.paddingMd,
      child: Column(
        children: [
          Text('Title', style: rTypography.titleLarge),
          rSpacing.gapVerticalSm,
          Icon(Icons.home, size: rSizes.iconMd),
        ],
      ),
    );
  }
}
```

## Benefits

- ✅ Prevents overflow on small screens
- ✅ Maintains proportions on large screens
- ✅ Consistent scaling across all UI elements
- ✅ Easy to apply - just use extension methods
- ✅ Automatic scaling based on screen size

## Notes

- The system uses the smaller dimension (width or height) to ensure UI fits on screen
- Scale factor is clamped between 0.7x and 1.3x to prevent too small or too large UI
- Base design size is 1920x1080 (common desktop/POS resolution)
- All spacing, typography, and sizes scale proportionally

