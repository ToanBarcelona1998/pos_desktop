import '../../core/api_client.dart';
import '../../model/variation_model.dart';

/// Remote data source for product variation operations
abstract class VariationRemoteDataSource {
  /// Get variations with pagination
  Future<VariationListResponse> getVariations(String url);
}

/// Implementation of [VariationRemoteDataSource]
class VariationRemoteDataSourceImpl implements VariationRemoteDataSource {
  final ApiClient _apiClient;

  const VariationRemoteDataSourceImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  @override
  Future<VariationListResponse> getVariations(String url) async {
    final response = await _apiClient.get(url);
    final data = response['data'] as List<dynamic>? ?? [];
    final variations = data
        .map((json) => VariationModel.fromJson(json as Map<String, dynamic>))
        .toList();
    final nextLink = response['links']?['next'] as String?;

    return VariationListResponse(
      variations: variations,
      nextLink: nextLink,
    );
  }
}

/// Response class for paginated variation list
class VariationListResponse {
  final List<VariationModel> variations;
  final String? nextLink;

  const VariationListResponse({
    required this.variations,
    this.nextLink,
  });
}






