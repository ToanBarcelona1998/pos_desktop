import '../core/result.dart';
import '../entity/payment_entity.dart';

/// Repository interface for payment operations
abstract class PaymentRepository {
  /// Get payment methods
  Future<Result<List<PaymentMethodEntity>>> getPaymentMethods();

  /// Get payment accounts
  Future<Result<List<PaymentAccountEntity>>> getPaymentAccounts();

  /// Sync payment methods from remote to local
  Future<Result<void>> syncPaymentMethods();

  /// Sync payment accounts from remote to local
  Future<Result<void>> syncPaymentAccounts();

  /// Get payment methods from local storage
  Future<Result<List<PaymentMethodEntity>>> getLocalPaymentMethods();

  /// Get payment accounts from local storage
  Future<Result<List<PaymentAccountEntity>>> getLocalPaymentAccounts();

  /// Get customer due
  Future<Result<Map<String, dynamic>>> getCustomerDue(int customerId);

  /// Post contact payment
  Future<Result<void>> postContactPayment({
    required int contactId,
    required double amount,
    required String method,
    String? note,
    int? accountId,
    DateTime? paidOn,
  });
}




