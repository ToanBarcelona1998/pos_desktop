import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/system.dart';
import 'api.dart';

class FollowUpApi extends Api {
  //get specific follow up detail
  Future<Map> getSpecifiedFollowUp(id) async {
    try {
      dynamic followUps;
      String url = "$baseUrl$apiUrl/crm/follow-ups/$id";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));

      followUps = jsonDecode(response.body);
      dynamic followUpList = followUps['data'][0];
      return followUpList;
    } catch (e) {
      return {};
    }
  }

  //add follow up
  addFollowUp(Map followUp) async {
    try {
      String url = "$baseUrl$apiUrl/crm/follow-ups";
      dynamic body = json.encode(followUp);
      dynamic token = await System().getToken();
      dynamic response = await http.post(Uri.parse(url),
          headers: getHeader(token), body: body);
      return response.statusCode;
    } catch (_) {}
  }

  //update follow up
  update(Map followUp, id) async {
    try {
      String url = "$baseUrl$apiUrl/crm/follow-ups/$id";
      dynamic body = json.encode(followUp);
      dynamic token = await System().getToken();
      dynamic response = await http.put(Uri.parse(url),
          headers: getHeader(token), body: body);
      return response.statusCode;
    } catch (_) {}
  }

  //post call_logs to api
  Future<bool> syncCallLog(Map callLogs) async {
    try {
      String url = "$baseUrl$apiUrl/crm/call-logs";
      dynamic body = json.encode(callLogs);
      dynamic token = await System().getToken();
      dynamic response = await http.post(Uri.parse(url),
          headers: getHeader(token), body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  //get follow up categories
//get specific follow up detail
  Future<List<dynamic>> getFollowUpCategories() async {
    try {
      dynamic followUpCategories;
      String url = "$baseUrl$apiUrl/taxonomy?type=followup_category";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));

      followUpCategories = jsonDecode(response.body);
      List<dynamic> followUpCategoryList = followUpCategories['data'];
      return followUpCategoryList;
    } catch (e) {
      return [];
    }
  }
}
