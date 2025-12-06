import '../../core/api_client.dart';
import '../../model/unit_model.dart';

/// Remote data source for unit operations
abstract class UnitRemoteDataSource {
  /// Get all units
  Future<List<UnitModel>> getUnits();

  /// Create a new unit
  Future<UnitModel> createUnit(Map<String, dynamic> data);

  /// Update an existing unit
  Future<UnitModel> updateUnit(int id, Map<String, dynamic> data);

  /// Delete a unit
  Future<void> deleteUnit(int id);
}

/// Implementation of [UnitRemoteDataSource]
class UnitRemoteDataSourceImpl implements UnitRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const UnitRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<UnitModel>> getUnits() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => UnitModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UnitModel> createUnit(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_endpoint, body: data);
    return UnitModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<UnitModel> updateUnit(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_endpoint/$id', body: data);
    return UnitModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<void> deleteUnit(int id) async {
    await _apiClient.delete('$_endpoint/$id');
  }
}














