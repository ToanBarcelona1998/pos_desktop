/// Payment method enum for domain layer (business logic)
enum PaymentMethod {
  /// Cash payment
  cash,

  /// Card payment
  card,

  /// Cheque payment
  cheque,

  /// Bank transfer payment
  bankTransfer,

  /// E wallet payment
  eWallet,

  /// Other payment method
  other,
}

/// Extension to convert PaymentMethod to/from string
extension PaymentMethodExtension on PaymentMethod {
  /// Convert enum to string value for API/database
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.eWallet:
        return 'e-wallet';
      case PaymentMethod.other:
        return 'other';
    }
  }

  /// Create enum from string value
  static PaymentMethod? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'e-wallet':
        return PaymentMethod.eWallet;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash; // Default to cash
    }
  }
}



