import '../../core/api_client.dart';
import '../../model/auth_token_model.dart';
import '../../model/user_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  /// Logs in with username and password
  Future<AuthTokenModel> login({
    required String username,
    required String password,
  });

  /// Gets current user details
  Future<UserModel> getCurrentUser(String token);

  /// Refreshes the authentication token
  Future<AuthTokenModel> refreshToken(String refreshToken);
}

/// Implementation of [AuthRemoteDataSource]
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final String _clientId;
  final String _clientSecret;
  final String _loginUrl;
  final String _userUrl;

  const AuthRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String clientId,
    required String clientSecret,
    required String loginUrl,
    required String userUrl,
  })  : _apiClient = apiClient,
        _clientId = clientId,
        _clientSecret = clientSecret,
        _loginUrl = loginUrl,
        _userUrl = userUrl;

  @override
  Future<AuthTokenModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.postFormUrlEncoded(
      _loginUrl,
      body: {
        'grant_type': 'password',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'username': username,
        'password': password,
      },
    );
    return AuthTokenModel.fromJson(response);
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    _apiClient.setAccessToken(token);
    final response = await _apiClient.get(_userUrl);
    return UserModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<AuthTokenModel> refreshToken(String refreshToken) async {
    final response = await _apiClient.postFormUrlEncoded(
      _loginUrl,
      body: {
        'grant_type': 'refresh_token',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': refreshToken,
      },
    );
    return AuthTokenModel.fromJson(response);
  }
}










