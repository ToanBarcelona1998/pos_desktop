import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apis/tax.dart';
import '../models/system.dart';
import 'api.dart';
import 'contact.dart';

class SystemApi {
  Future<void> store() async {
    await Future.wait([
      Business().get(),
      Permissions().get(),
      ActiveSubscription().get(),
      Brand().get(),
      Category().get(),
      Payment().get(),
      Tax().get(),
      Location().get(),
      PaymentAccounts().get(),
    ]);
    await CustomerApi().get();

  }
}

class Brand extends Api {
  dynamic brands;

  Future<List> get() async {
    try {
      String url ="$baseUrl$apiUrl/brand";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      brands = jsonDecode(response.body);
      dynamic brandList = brands['data'];
      System().insert('brand', jsonEncode(brandList));
      return brandList;
    } catch (e) {
      return [];
    }
  }
}

class Category extends Api {
  dynamic taxonomy;

  Future<List> get() async {
    try {
      String url = "$baseUrl$apiUrl/taxonomy?type=product";
      dynamic token = await System().getToken();
      dynamic response =
      await http.get(Uri.parse(url), headers: getHeader(token));
      taxonomy = jsonDecode(response.body);
      dynamic categoryList = taxonomy['data'];
      System().insert('taxonomy', jsonEncode(categoryList));
      taxonomy['data'].forEach((element) {
        if (element['sub_categories'].isNotEmpty) {
          element['sub_categories'].forEach((value) {
            System().insert(
                'sub_categories',
                jsonEncode({'id': value['id'], 'name': value['name']}),
                value['parent_id']);
          });
        }
      });
      return categoryList;
    } catch (e) {
      return [];
    }
  }
}

class Payment extends Api {
  late Map payment;

  Future<List> get() async {
    try {
      String url = "$baseUrl$apiUrl/payment-methods";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      payment = jsonDecode(response.body);
      List paymentList = [];
      payment.forEach((key, value) {
        paymentList.add({key: value});
      });
      System().insert('payment_methods', jsonEncode(paymentList));
      return paymentList;
    } catch (e) {
      return [];
    }
  }
}

class Permissions extends Api {
  Future<void> get() async {
    try {
      String url = "$baseUrl$apiUrl/user/loggedin";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      dynamic userDetails = jsonDecode(response.body);
      Map userDetailsMap = userDetails['data'];
      if (userDetailsMap.containsKey('all_permissions')) {
        dynamic userData = jsonEncode(userDetailsMap['all_permissions']);
        await System().insert('user_permissions', userData);
      }
    } catch (_) {}
  }
}

class Location extends Api {
  dynamic locations;

  Future<List?> get() async {
    try {
      String url ="$baseUrl$apiUrl/business-location";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      locations = jsonDecode(response.body);
      List? locationList = locations['data'];
      System().insert('location', jsonEncode(locationList));
      if (locationList != null) {
        for (dynamic element in locationList) {
          System().insert('payment_method',
              jsonEncode(element['payment_methods']), element['id']);
        }
      }
      return locationList;
    } catch (e) {
      return [];
    }
  }
}

class Business extends Api {
  dynamic business;

  Future<List> get() async {
    try {
      String url ="$baseUrl$apiUrl/business-details";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      business = jsonDecode(response.body);
      List businessDetails = [business['data']];
      System().insert('business', jsonEncode(businessDetails));
      return businessDetails;
    } catch (e) {
      return [];
    }
  }
}

class ActiveSubscription extends Api {
  dynamic activeSubscription;

  Future<List> get() async {
    try {
      String url = "$baseUrl$apiUrl/active-subscription";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      activeSubscription = jsonDecode(response.body);
      List activeSubscriptionDetails = (activeSubscription['data'].isNotEmpty)
          ? [activeSubscription['data']]
          : [];
      System()
          .insert('active-subscription', jsonEncode(activeSubscriptionDetails));
      return activeSubscriptionDetails;
    } catch (e) {
      return [];
    }
  }
}

class PaymentAccounts extends Api {
  Future<List> get() async {
    try {
      dynamic accounts;
      String url ="$baseUrl$apiUrl/payment-accounts";
      dynamic token = await System().getToken();
      dynamic response =
          await http.get(Uri.parse(url), headers: getHeader(token));
      accounts = jsonDecode(response.body);
      List paymentAccounts = accounts['data'];
      System().insert('payment_accounts', jsonEncode(paymentAccounts));
      return paymentAccounts;
    } catch (e) {
      return [];
    }
  }
}
