import '../../core/api_client.dart';
import '../../model/contact_model.dart';

/// Remote data source for contacts
abstract class ContactRemoteDataSource {
  /// Gets all contacts
  Future<List<ContactModel>> getContacts({String? type, int? perPage});

  /// Gets a contact by ID
  Future<ContactModel> getContactById(int id);

  /// Creates a new contact
  Future<ContactModel> createContact(Map<String, dynamic> data);

  /// Updates an existing contact
  Future<ContactModel> updateContact(int id, Map<String, dynamic> data);

  /// Deletes a contact
  Future<void> deleteContact(int id);
}

/// Implementation of [ContactRemoteDataSource]
class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const ContactRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<ContactModel>> getContacts({String? type, int? perPage}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    final response = await _apiClient.get(_endpoint, queryParams: queryParams);
    final data = response['data'] as List<dynamic>;
    return data
        .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ContactModel> getContactById(int id) async {
    final response = await _apiClient.get('$_endpoint/$id');
    return ContactModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<ContactModel> createContact(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_endpoint, body: data);
    return ContactModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<ContactModel> updateContact(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_endpoint/$id', body: data);
    return ContactModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<void> deleteContact(int id) async {
    await _apiClient.delete('$_endpoint/$id');
  }
}





