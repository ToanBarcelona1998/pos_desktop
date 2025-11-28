import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pos_final/api_end_points.dart';
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/api_handler/api_error_handler.dart';
import 'package:pos_final/helpers/api_handler/api_helper.dart';
import 'package:pos_final/helpers/api_handler/api_response.dart';

import '../models/system.dart';
import 'api.dart';

class PurchasesService extends Api {
  Future<ApiResponse> getPurchases() async {
    String token = await System().getToken();
    int userId = Config.userId!;
    dynamic business = await System().get('business');
    dynamic businessId = business[0]['id'];
    try {
      final Response<dynamic> response = await DioServiceHelper.getData(
          endPoint: ApiEndPoints.purchases,
          headers: getHeader(token),
          query: {'user_id': userId, 'business_id': businessId});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      log("ERROR ${e.toString()}");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponse> addPurchases(Map<String, dynamic> data) async {
    String token = await System().getToken();
    try {
      final Response<dynamic> response = await DioServiceHelper.post(
          ApiEndPoints.purchases,
          headers: getHeader(token),
          data: data);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      log("ERROR ${e.toString()}");
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
