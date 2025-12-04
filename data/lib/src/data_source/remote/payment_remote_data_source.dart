import '../../core/api_client.dart';

/// Remote data source for payment operations
abstract class PaymentRemoteDataSource {
  /// Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods();

  /// Get payment accounts
  Future<List<Map<String, dynamic>>> getPaymentAccounts();

  /// Get customer due
  Future<Map<String, dynamic>> getCustomerDue(int customerId);

  /// Post contact payment
  Future<void> postContactPayment(Map<String, dynamic> data);
}

/// Implementation of [PaymentRemoteDataSource]
class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient _apiClient;
  final String _paymentMethodsEndpoint;
  final String _paymentAccountsEndpoint;
  final String _contactEndpoint;
  final String _contactPaymentEndpoint;

  const PaymentRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String paymentMethodsEndpoint,
    required String paymentAccountsEndpoint,
    required String contactEndpoint,
    required String contactPaymentEndpoint,
  })  : _apiClient = apiClient,
        _paymentMethodsEndpoint = paymentMethodsEndpoint,
        _paymentAccountsEndpoint = paymentAccountsEndpoint,
        _contactEndpoint = contactEndpoint,
        _contactPaymentEndpoint = contactPaymentEndpoint;

  @override
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final response = await _apiClient.get(_paymentMethodsEndpoint);
    // Payment methods come as a map, convert to list
    final List<Map<String, dynamic>> paymentList = [];
    response.forEach((key, value) {
      if (key != 'data') {
        paymentList.add({key: value});
      }
    });
    return paymentList;
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentAccounts() async {
    final response = await _apiClient.get(_paymentAccountsEndpoint);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  @override
  Future<Map<String, dynamic>> getCustomerDue(int customerId) async {
    final response = await _apiClient.get('$_contactEndpoint/$customerId');
    return response;
  }

  @override
  Future<void> postContactPayment(Map<String, dynamic> data) async {
    await _apiClient.post(_contactPaymentEndpoint, body: data);
  }
}











