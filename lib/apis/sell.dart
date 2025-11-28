import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/sell_database.dart';
import '../models/system.dart';
import 'api.dart';

class SellApi extends Api {
  // Create a sell in API
  Future<Map<String, dynamic>> create(dynamic data) async {
    try {
      String url = "$baseUrl$apiUrl/sell";
      var token = await System().getToken();

      // Ensure data is properly encoded as JSON and remove shipping-related fields
      Map<String, dynamic> cleanedData;
      if (data is String) {
        cleanedData = jsonDecode(data);
      } else {
        cleanedData = Map<String, dynamic>.from(data);
      }

      // Remove shipping fields from data before sending to API
      if (cleanedData.containsKey('sells') && cleanedData['sells'] is List) {
        cleanedData['sells'] = cleanedData['sells'].map((sell) {
          return {
            ...sell,
            'shipping_charges': 0.0,
            'shipping_details': null,
            'shipping_address': null,
            'shipping_status': null,
            'delivered_to': null,
          };
        }).toList();
      } else {
        cleanedData
          ..remove('shipping_charges')
          ..remove('shipping_details')
          ..remove('shipping_address')
          ..remove('shipping_status')
          ..remove('delivered_to');
      }

      final body = jsonEncode(cleanedData);

      // Make the HTTP POST request
      var response = await http.post(
        Uri.parse(url),
        headers: getHeader(token),
        body: body,
      );

      // Check the response status
      if (response.statusCode != 200) {
        log('Failed to create sell: Status ${response.statusCode}, Body: ${response.body}');
        return {'error': 'Failed to create sell', 'status': response.statusCode};
      }

      // Decode the response
      var info = jsonDecode(response.body);
      log('API response: $info');

      // Ensure info contains data and is not empty
      if (info is Map && info.containsKey('data') && info['data'] is List && info['data'].isNotEmpty) {
        return {
          'transaction_id': info['data'][0]['id'],
          'payment_lines': info['data'][0]['payment_lines'] ?? [],
          'invoice_url': info['data'][0]['invoice_url'] ?? '',
          'change_return': info['data'][0]['change_return'] ?? 0.0,
          'status': info['data'][0]['status'] ?? 'final',
          'is_quotation': info['data'][0]['is_quotation'] ?? 0,
          'is_suspend': info['data'][0]['is_suspend'] ?? 0,
          'shipping_charges': 0.0, // Force null/0 for shipping fields
          'shipping_details': null,
          'shipping_address': null,
          'shipping_status': null,
          'delivered_to': null,
        };
      } else {
        log('Invalid API response format: $info');
        return {'error': 'Invalid API response format'};
      }
    } catch (e) {
      log('Error in SellApi.create: $e');
      return {'error': 'Exception occurred: $e'};
    }
  }

  // Update a sell in API
  Future<Map<String, dynamic>> update(int transactionId, dynamic data) async {
    try {
      String url = "$baseUrl$apiUrl/sell/$transactionId";
      var token = await System().getToken();

      // Ensure data is properly encoded as JSON and remove shipping-related fields
      Map<String, dynamic> cleanedData = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
      cleanedData
        ..remove('shipping_charges')
        ..remove('shipping_details')
        ..remove('shipping_address')
        ..remove('shipping_status')
        ..remove('delivered_to');

      final body = jsonEncode(cleanedData);

      var response = await http.put(
        Uri.parse(url),
        headers: getHeader(token),
        body: body,
      );

      if (response.statusCode != 200) {
        log('Failed to update sell: Status ${response.statusCode}, Body: ${response.body}');
        return {'error': 'Failed to update sell', 'status': response.statusCode};
      }

      var sellResponse = jsonDecode(response.body);
      return {
        'payment_lines': sellResponse['data']?['payment_lines'] ?? [],
        'invoice_url': sellResponse['data']?['invoice_url'] ?? '',
        'status': sellResponse['data']?['status'] ?? 'final',
        'is_quotation': sellResponse['data']?['is_quotation'] ?? 0,
        'is_suspend': sellResponse['data']?['is_suspend'] ?? 0,
        'shipping_charges': 0.0, // Force null/0 for shipping fields
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
      };
    } catch (e) {
      log('Error in SellApi.update: $e');
      return {'error': 'Exception occurred: $e'};
    }
  }

  // Delete sell
  Future<Map<String, dynamic>> delete(int transactionId) async {
    try {
      String url = "$baseUrl$apiUrl/sell/$transactionId";
      var token = await System().getToken();

      var response = await http.delete(
        Uri.parse(url),
        headers: getHeader(token),
      );

      if (response.statusCode == 200) {
        var sellResponse = jsonDecode(response.body);
        return sellResponse ?? {'message': 'Sell deleted successfully'};
      } else {
        log('Failed to delete sell: Status ${response.statusCode}, Body: ${response.body}');
        return {'error': 'Failed to delete sell', 'status': response.statusCode};
      }
    } catch (e) {
      log('Error in SellApi.delete: $e');
      return {'error': 'Exception occurred: $e'};
    }
  }

  // Get specified sells
  Future<List<dynamic>> getSpecifiedSells(List<int> transactionIds) async {
    try {
      String ids = transactionIds.join(",");
      String url = "$baseUrl$apiUrl/sell/$ids";
      var token = await System().getToken();

      var response = await http.get(
        Uri.parse(url),
        headers: getHeader(token),
      );

      if (response.statusCode != 200) {
        log('Failed to fetch sells: Status ${response.statusCode}, Body: ${response.body}');
        return [];
      }

      var jsonResponse = jsonDecode(response.body);
      List<dynamic> responseData = [];

      if (jsonResponse.containsKey('data')) {
        responseData = jsonResponse['data'].map((sell) {
          // Remove shipping fields from each sell in the response
          return {
            ...sell,
            'shipping_charges': 0.0,
            'shipping_details': null,
            'shipping_address': null,
            'shipping_status': null,
            'delivered_to': null,
          };
        }).toList();

        var responseTransactionIds = responseData.map((e) => e['id']).toList();

        // Delete local sells that are not in the API response
        for (var id in transactionIds) {
          if (!responseTransactionIds.contains(id)) {
            var sell = await SellDatabase().getSellByTransactionId(id);
            if (sell.isNotEmpty) {
              await SellDatabase().deleteSell(sell[0]['id']);
            }
          }
        }
      }

      return responseData;
    } catch (e) {
      log('Error in SellApi.getSpecifiedSells: $e');
      return [];
    }
  }
}