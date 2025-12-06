/// Discount type enum for domain layer (business logic)
enum DiscountType {
  /// Fixed amount discount
  fixed,

  /// Percentage discount
  percentage,
}

/// Extension to convert DiscountType to/from string
extension DiscountTypeExtension on DiscountType {
  /// Convert enum to string value for API/database
  String get value {
    switch (this) {
      case DiscountType.fixed:
        return 'fixed';
      case DiscountType.percentage:
        return 'percentage';
    }
  }

  /// Create enum from string value
  static DiscountType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'fixed':
        return DiscountType.fixed;
      case 'percentage':
        return DiscountType.percentage;
      default:
        return DiscountType.fixed; // Default to fixed
    }
  }
}



