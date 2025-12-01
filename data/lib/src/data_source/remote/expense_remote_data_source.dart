import '../../core/api_client.dart';

/// Remote data source for expense operations
abstract class ExpenseRemoteDataSource {
  /// Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories();

  /// Create an expense
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data);

  /// Get expenses
  Future<List<Map<String, dynamic>>> getExpenses({Map<String, dynamic>? query});
}

/// Implementation of [ExpenseRemoteDataSource]
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiClient _apiClient;
  final String _expenseEndpoint;
  final String _categoriesEndpoint;

  const ExpenseRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String expenseEndpoint,
    required String categoriesEndpoint,
  })  : _apiClient = apiClient,
        _expenseEndpoint = expenseEndpoint,
        _categoriesEndpoint = categoriesEndpoint;

  @override
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final response = await _apiClient.get(_categoriesEndpoint);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  @override
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_expenseEndpoint, body: data);
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenses({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_expenseEndpoint, queryParams: query);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }
}






