import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:pos_final/api_end_points.dart';

import '../config.dart';

class Api {
  String baseUrl = Config.baseUrl,
      apiUrl = ApiEndPoints.apiUrl,
      clientId = Config().clientId,
      clientSecret = Config().clientSecret;

  // Validate the login details
  Future<Map?> login(String username, String password) async {
    String url = ApiEndPoints.loginUrl;

    Map body = {
      'grant_type': 'password',
      'client_id': clientId,
      'client_secret': clientSecret,
      'username': username,
      'password': password,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      // Log the response for debugging
      print('Login API Response Status: ${response.statusCode}');
      print('Login API Response Body: ${response.body}');

      // Check if response is JSON
      try {
        var jsonResponse = convert.jsonDecode(response.body);
        if (response.statusCode == 200) {
          // Logged in successfully
          return {
            'success': true,
            'access_token': jsonResponse['access_token'],
          };
        } else if (response.statusCode == 401) {
          // Invalid credentials
          return {
            'success': false,
            'error': jsonResponse['error'] ?? 'Invalid credentials',
          };
        } else {
          // Other HTTP errors (e.g., 400, 404, 500)
          return {
            'success': false,
            'error': jsonResponse['error'] ?? 'Server error: ${response.statusCode}',
          };
        }
      } catch (e) {
        // Response is not JSON (likely HTML)
        print('Parse error: $e');
        return {
          'success': false,
          'error': 'Unexpected response format from server: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Network or other errors
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Unable to connect to the server',
      };
    }
  }

  Map<String, String> getHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}