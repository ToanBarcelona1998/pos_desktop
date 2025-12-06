/// Sell status enum for domain layer (business logic)
enum SellStatus {
  /// Final/completed sale
  final_,

  /// Draft sale (not finalized)
  draft,

  /// Quotation (price quote)
  quotation,

  /// Suspended sale (paused)
  suspended,

  /// Pending sale (credit sale awaiting payment)
  pending,
}

/// Extension to convert SellStatus to/from string
extension SellStatusExtension on SellStatus {
  /// Convert enum to string value for API/database
  String get value {
    switch (this) {
      case SellStatus.final_:
        return 'final';
      case SellStatus.draft:
        return 'draft';
      case SellStatus.quotation:
        return 'quotation';
      case SellStatus.suspended:
        return 'suspended';
      case SellStatus.pending:
        return 'pending';
    }
  }

  /// Create enum from string value
  static SellStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'final':
        return SellStatus.final_;
      case 'draft':
        return SellStatus.draft;
      case 'quotation':
        return SellStatus.quotation;
      case 'suspended':
      case 'suspend':
        return SellStatus.suspended;
      case 'pending':
        return SellStatus.pending;
      default:
        return null;
    }
  }
}



