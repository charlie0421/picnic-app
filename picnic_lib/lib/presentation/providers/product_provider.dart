// product_providers.dart
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/product_provider_helper.dart';
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

      ProductProviderHelper.validateProductsNotEmpty(products);
      return products;
    } catch (e, s) {
      logger.e('Supabase products fetch error', error: e, stackTrace: s);

      // Supabase 초기화 문제인지 확인
      if (ProductProviderHelper.isSupabaseInitError(e.toString())) {
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
    return ProductProviderHelper.findProductById(state.value, id);
  }
}

@Riverpod(keepAlive: true)
class StoreProducts extends _$StoreProducts {
  @override
  FutureOr<List<ProductDetails>> build() async {
    try {
      // 스토어 가용성 확인은 서버 카탈로그와 독립이므로 병렬로 시작해
      // 첫 진입 shimmer 시간을 줄인다. 서버 조회가 먼저 실패해 이 future를
      // 기다리지 못하고 빠져나가도 unhandled async error가 되지 않도록
      // ignore()로 오류 청취자를 미리 붙여 둔다 (아래 await에서는 그대로
      // rethrow된다).
      final availability = InAppPurchase.instance.isAvailable();
      availability.ignore();
      final serverProducts = await ref.watch(serverProductsProvider.future);
      return _loadProducts(serverProducts, availability);
    } catch (e, s) {
      logger.e('Error in StoreProducts build: $e', stackTrace: s);
      rethrow;
    }
  }

  Future<List<ProductDetails>> _loadProducts(
    List<Map<String, dynamic>> serverProducts,
    Future<bool> availability,
  ) async {
    final InAppPurchase inAppPurchase = InAppPurchase.instance;

    try {
      final bool available = await availability;
      if (!available) {
        throw Exception('Store is not available');
      }

      final productIds = ProductProviderHelper.buildProductIds(
        serverProducts,
        isAndroid: Platform.isAndroid,
        appNamePrefix: Environment.inappAppNamePrefix,
        // 단일 출처(Environment.storeQueryNamespace) — 구매 매칭·버튼
        // 판정과 반드시 같은 값이어야 한다.
        androidPrefix: Environment.storeQueryNamespace,
        environment: Environment.currentEnvironment,
      );
      if (ProductProviderHelper.requiresSandboxIsolation(
        environment: Environment.currentEnvironment,
        usesProductionSkus: Environment.sandboxUsesProductionStoreSkus,
      )) {
        ProductProviderHelper.validateSandboxProductIds(
          productIds,
          namespace: Environment.paymentProductNamespace.toLowerCase(),
        );
      } else if (Environment.sandboxUsesProductionStoreSkus) {
        logger.i(
          'Sandbox store queries production SKUs by explicit opt-in '
          '(PICNIC_SANDBOX_USES_PRODUCTION_STORE_SKUS).',
        );
      }

      final ProductDetailsResponse response = await inAppPurchase
          .queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        logger.i(
          'Some product IDs were not recognized: ${response.notFoundIDs}',
        );
      }

      if (response.productDetails.isEmpty) {
        if (ProductProviderHelper.shouldPreviewEmptyStoreCatalog(
          environment: Environment.currentEnvironment,
        )) {
          logger.w(
            'Store returned no products in sandbox; '
            'showing the server catalog with purchases disabled.',
          );
          return const <ProductDetails>[];
        }
        throw Exception('No products found in the store');
      }

      return response.productDetails;
    } catch (e, s) {
      if (ProductProviderHelper.shouldUseServerCatalogPreview(
        environment: Environment.currentEnvironment,
        error: e,
      )) {
        logger.w(
          'Sandbox App Store catalog is not isolated; '
          'showing the server catalog with purchases disabled.',
        );
        return const <ProductDetails>[];
      }
      logger.e('Error loading products: $e', stackTrace: s);
      throw Exception('Error loading products: $e');
    }
  }
}
