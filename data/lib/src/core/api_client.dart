import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

/// HTTP methods
enum HttpMethod { get, post, put, patch, delete }

/// API Client for making HTTP requests
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _accessToken;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Sets the access token for authenticated requests
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Gets default headers
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Makes a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Makes a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Makes a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Makes a PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.patch,
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Makes a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: HttpMethod.delete,
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
    );
  }

  /// Makes a form-urlencoded POST request (for OAuth)
  Future<Map<String, dynamic>> postFormUrlEncoded(
    String url, {
    required Map<String, String> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          ...?headers,
        },
        body: body,
      );
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on FormatException {
      throw ServerException('Invalid response format');
    }
  }

  /// Internal request method
  Future<Map<String, dynamic>> _request({
    required HttpMethod method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final requestHeaders = {..._defaultHeaders, ...?headers};
      final encodedBody = body != null ? jsonEncode(body) : null;

      http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await _client.get(uri, headers: requestHeaders);
          break;
        case HttpMethod.post:
          response = await _client.post(uri,
              headers: requestHeaders, body: encodedBody);
          break;
        case HttpMethod.put:
          response = await _client.put(uri,
              headers: requestHeaders, body: encodedBody);
          break;
        case HttpMethod.patch:
          response = await _client.patch(uri,
              headers: requestHeaders, body: encodedBody);
          break;
        case HttpMethod.delete:
          response = await _client.delete(uri,
              headers: requestHeaders, body: encodedBody);
          break;
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on FormatException {
      throw ServerException('Invalid response format');
    }
  }

  /// Builds URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final fullUrl = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final uri = Uri.parse(fullUrl);

    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  /// Handles HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(
          body['message'] ?? 'Bad request',
          errors: body['errors'],
        );
      case 401:
        throw UnauthorizedException(body['message'] ?? 'Unauthorized');
      case 403:
        throw ForbiddenException(body['message'] ?? 'Forbidden');
      case 404:
        throw NotFoundException(body['message'] ?? 'Not found');
      case 422:
        throw ValidationException(
          body['message'] ?? 'Validation error',
          errors: body['errors'],
        );
      case 500:
      case 502:
      case 503:
        throw ServerException(body['message'] ?? 'Server error');
      default:
        throw ServerException(
          'Unexpected error: ${response.statusCode}',
        );
    }
  }

  /// Closes the HTTP client
  void dispose() {
    _client.close();
  }
}




