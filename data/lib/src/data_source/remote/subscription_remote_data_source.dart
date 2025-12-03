import '../../core/api_client.dart';
import '../../model/subscription_model.dart';

/// Remote data source for subscription operations
abstract class SubscriptionRemoteDataSource {
  /// Get active subscription
  Future<SubscriptionModel?> getActiveSubscription();
}

/// Implementation of [SubscriptionRemoteDataSource]
class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const SubscriptionRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<SubscriptionModel?> getActiveSubscription() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'];
    if (data == null || (data is List && data.isEmpty) || (data is Map && data.isEmpty)) {
      return null;
    }
    if (data is List) {
      return SubscriptionModel.fromJson(data.first as Map<String, dynamic>);
    }
    return SubscriptionModel.fromJson(data as Map<String, dynamic>);
  }
}








