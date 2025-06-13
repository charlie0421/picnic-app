// product_providers.dart
import 'dart:io';

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

  Future<List<Map<String, dynamic>>> _fetchProductsFromSupabase() async {
    try {
      // Supabase 초기화 상태 확인
      if (!isSupabaseLoggedSafely && supabase.auth.currentUser == null) {
        // Supabase가 초기화되지 않은 경우 잠시 대기 후 재시도
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final response = await supabase
          .from('products')
          .select()
          .lt('start_at', 'now()')
          .gt('end_at', 'now()')
          .order('price', ascending: true);

      logger.i('Server products: $response');

      final List<Map<String, dynamic>> products =
          List<Map<String, dynamic>>.from(response);

      if (products.isEmpty) {
        throw Exception('No products found');
      }

      return products;
    } catch (e, s) {
      logger.e('Supabase products fetch error', error: e, stackTrace: s);
      
      // Supabase 초기화 문제인지 확인
      if (e.toString().contains('Project not specified') || 
          e.toString().contains('not initialized')) {
        logger.w('Supabase 초기화 문제 감지. 재시도 예약...');
        // 상태 리셋하여 재시도 트리거
        Future.delayed(const Duration(seconds: 2), () {
          ref.invalidateSelf();
        });
      }
      
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
