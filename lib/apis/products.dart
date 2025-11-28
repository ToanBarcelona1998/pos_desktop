// lib/apis/products.dart (تحديث: أضفت خيارًا لتجاوز الكاش بإضافة header لـ Cache-Control، ودعم لجلب كل الصفحات إذا لزم الأمر، لكن بما أن Variations هو المستخدم الرئيسي، هذا تحسين عام للـ API)
import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:pos_final/api_end_points.dart';

import 'package:pos_final/apis/api.dart';

import 'package:pos_final/helpers/api_handler/api_error_handler.dart';

import 'package:pos_final/helpers/api_handler/api_helper.dart';

import 'package:pos_final/helpers/api_handler/api_response.dart';

import 'package:pos_final/models/system.dart';

class ProductsService extends Api {

  Future<ApiResponse> getProducts(int locationId, {int page = 1, int perPage = 10, bool bypassCache = false}) async {

    String token = await System().getToken();

    try {

      final Map<String, dynamic> headers = getHeader(token);

      if (bypassCache) {

        headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';

        headers['Pragma'] = 'no-cache';

        headers['Expires'] = '0';

      }

      final Response<dynamic> response = await DioServiceHelper.getData(

          endPoint: ApiEndPoints.products,

          headers: headers,

          query: {

            'location_id': locationId,

            'page': page,

            'per_page': perPage

          });

      return ApiResponse.withSuccess(response);

    } catch (e) {

      log("ERROR ${e.toString()}");

      return ApiResponse.withError(ApiErrorHandler.getMessage(e));

    }

  }

}