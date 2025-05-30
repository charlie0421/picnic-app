// product_providers.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/product_provider.g.dart';

@Riverpod(keepAlive: true)
class ServerProducts extends _$ServerProducts {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return _fetchProductsFromSupabase();
  }

  /// PostgrestBuilder를 우회한 직접 HTTP 요청으로 products 데이터 가져오기
  Future<List<Map<String, dynamic>>> _fetchProductsFromSupabase() async {
    try {
      logger.d('[ServerProducts] 직접 HTTP 요청으로 제품 데이터 조회 시작');

      // Supabase URL과 API Key 가져오기
      final supabaseUrl = Environment.supabaseUrl;
      final supabaseKey = Environment.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        logger.e('[ServerProducts] Supabase 설정이 없습니다');
        throw Exception('Supabase configuration missing');
      }

      // REST API URL 구성
      final String baseUrl = '$supabaseUrl/rest/v1/products';
      final Map<String, String> queryParams = {
        'select': '*',
        'start_at': 'lt.now()',
        'end_at': 'gt.now()',
        'order': 'price.asc',
      };

      // URI 구성
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      logger.d(
          '[ServerProducts] 요청 URL: ${uri.toString().substring(0, uri.toString().length > 100 ? 100 : uri.toString().length)}...');

      // HTTP 헤더 설정
      final headers = {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // HTTP GET 요청 실행
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          logger.w('[ServerProducts] HTTP 요청 타임아웃');
          return http.Response('[]', 408);
        },
      );

      logger.d('[ServerProducts] HTTP 응답 상태: ${response.statusCode}');

      // 응답 상태 확인
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is List) {
            final List<Map<String, dynamic>> products =
                jsonData.cast<Map<String, dynamic>>();

            logger.i('[ServerProducts] 직접 HTTP 요청 성공: ${products.length}개 제품');

            if (products.isEmpty) {
              throw Exception('No products found');
            }

            return products;
          } else {
            logger.w('[ServerProducts] 예상치 못한 응답 형식: ${jsonData.runtimeType}');
            throw Exception('Unexpected response format');
          }
        } catch (jsonError) {
          logger.e('[ServerProducts] JSON 파싱 실패: $jsonError');
          throw Exception('Failed to parse response: $jsonError');
        }
      } else if (response.statusCode == 404) {
        logger.w('[ServerProducts] 제품 테이블을 찾을 수 없음');
        throw Exception('Products table not found');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        logger.w('[ServerProducts] 인증/권한 오류: ${response.statusCode}');
        throw Exception('Authentication/Authorization error');
      } else {
        logger.w(
            '[ServerProducts] HTTP 오류: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e, s) {
      logger.e('[ServerProducts] 제품 조회 실패', error: e, stackTrace: s);
      throw Exception('Error fetching products: $e');
    }
  }

  Map<String, dynamic>? getProductDetailById(String id) {
    return state.value?.firstWhere(
      (product) => product['id'] == id,
      orElse: () => throw Exception('Product not found'),
    );
  }
}

@Riverpod(keepAlive: true)
class StoreProducts extends _$StoreProducts {
  @override
  FutureOr<List<ProductDetails>> build() async {
    try {
      final serverProducts = await ref.watch(serverProductsProvider.future);
      return _loadProducts(serverProducts);
    } catch (e, s) {
      logger.e('Error in StoreProducts build: $e', stackTrace: s);
      rethrow;
    }
  }

  Future<List<ProductDetails>> _loadProducts(
      List<Map<String, dynamic>> serverProducts) async {
    final InAppPurchase inAppPurchase = InAppPurchase.instance;

    try {
      final bool available = await inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('Store is not available');
      }

      final productIds = serverProducts
          .map((product) => Platform
                      .isAndroid // check if the operating system is Android
                  ? product['id']
                      .toString()
                      .toLowerCase() // convert to lowercase for Android
                  : Environment.inappAppNamePrefix +
                      product['id'].toString() // use original ID for the rest
              )
          .toSet();

      final ProductDetailsResponse response =
          await inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        logger
            .i('Some product IDs were not recognized: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No products found in the store');
      }

      return response.productDetails;
    } catch (e, s) {
      logger.e('Error loading products: $e', stackTrace: s);
      throw Exception('Error loading products: $e');
    }
  }
}
