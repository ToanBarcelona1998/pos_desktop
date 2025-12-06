/// Contact type enum for domain layer (business logic)
enum ContactType {
  /// Customer contact
  customer,

  /// Supplier contact
  supplier,

  /// Both customer and supplier
  both,
}

/// Extension to convert ContactType to/from string
extension ContactTypeExtension on ContactType {
  /// Convert enum to string value for API/database
  String get value {
    switch (this) {
      case ContactType.customer:
        return 'customer';
      case ContactType.supplier:
        return 'supplier';
      case ContactType.both:
        return 'both';
    }
  }

  /// Create enum from string value
  static ContactType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'customer':
        return ContactType.customer;
      case 'supplier':
        return ContactType.supplier;
      case 'both':
        return ContactType.both;
      default:
        return ContactType.customer; // Default to customer
    }
  }
}



