import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class ShipmentApi extends Api {
  // Update shipping status in API
  Future<Map<String, dynamic>> update(Map<String, dynamic> data) async {
    try {
      String url = "$baseUrl$apiUrl/update-shipping-status";
      var token = await System().getToken();

      // Ensure data is properly encoded as JSON
      final body = jsonEncode(data);

      // Make the HTTP POST request
      var response = await http.post(
        Uri.parse(url),
        headers: getHeader(token),
        body: body,
      );

      // Check the response status
      if (response.statusCode != 200) {
        log('Failed to update shipping status: Status ${response.statusCode}, Body: ${response.body}');
        return {'error': 'Failed to update shipping status', 'status': response.statusCode};
      }

      // Decode the response
      var info = jsonDecode(response.body);
      log('API response: $info');

      // Return success or relevant data
      return info ?? {'message': 'Shipping status updated successfully'};
    } catch (e) {
      log('Error in ShipmentApi.update: $e');
      return {'error': 'Exception occurred: $e'};
    }
  }
}