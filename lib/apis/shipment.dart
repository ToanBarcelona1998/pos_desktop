import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apis/api.dart';
import '../models/system.dart';

class ShipmentApi extends Api {
  //get sell by shipment status
  getSellByShipmentStatus(String status, String date) async {
    String url = "$baseUrl$apiUrl/sell/?start_date=$date&shipping_status=$status";
    var token = await System().getToken();
    var response = [];
    await http
        .get(Uri.parse(url), headers: getHeader(token))
        .then((value) {
      response = jsonDecode(value.body)['data'];
    });
    return response;
  }

  //update shipment status in api
  updateShipmentStatus(data) async {
    String url = "$baseUrl$apiUrl/update-shipping-status";
    var token = await System().getToken();
    var body = jsonEncode(data);
    dynamic response;
    await http
        .post(Uri.parse(url), headers: getHeader(token), body: body)
        .then((value) {
      response = jsonDecode(value.body);
    });
    return response;
  }
}
