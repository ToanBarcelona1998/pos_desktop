import 'package:domain/domain.dart';

/// Invoice type enum for UI/presentation layer
/// This is separate from domain SellStatus to allow UI-specific types
enum InvoiceType {
  /// Final invoice (completed sale)
  final_,

  /// Draft invoice
  draft,

  /// Quotation
  quotation,

  /// Suspended invoice
  suspended,
}

/// Extension for InvoiceType UI operations
extension InvoiceTypeExtension on InvoiceType {
  /// Convert to string for display/storage
  String get value {
    switch (this) {
      case InvoiceType.final_:
        return 'final';
      case InvoiceType.draft:
        return 'draft';
      case InvoiceType.quotation:
        return 'quotation';
      case InvoiceType.suspended:
        return 'suspended';
    }
  }

  /// Create from string
  static InvoiceType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'final':
        return InvoiceType.final_;
      case 'draft':
        return InvoiceType.draft;
      case 'quotation':
        return InvoiceType.quotation;
      case 'suspended':
      case 'suspend':
        return InvoiceType.suspended;
      default:
        return InvoiceType.final_; // Default
    }
  }

  /// Convert to domain SellStatus
  /// Note: InvoiceType doesn't have 'pending', so we map it appropriately
  SellStatus toSellStatus() {
    switch (this) {
      case InvoiceType.final_:
        return SellStatus.final_;
      case InvoiceType.draft:
        return SellStatus.draft;
      case InvoiceType.quotation:
        return SellStatus.quotation;
      case InvoiceType.suspended:
        return SellStatus.suspended;
    }
  }
}

