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
      final serverProducts = await ref.watch(serverProductsProvider.future);
      return _loadProducts(serverProducts);
    } catch (e, s) {
      logger.e('Error in StoreProducts build: $e', stackTrace: s);
      rethrow;
    }
  }

  Future<List<ProductDetails>> _loadProducts(
    List<Map<String, dynamic>> serverProducts,
  ) async {
    final InAppPurchase inAppPurchase = InAppPurchase.instance;

    try {
      final bool available = await inAppPurchase.isAvailable();
      if (!available) {
        throw Exception('Store is not available');
      }

      final productIds = ProductProviderHelper.buildProductIds(
        serverProducts,
        isAndroid: Platform.isAndroid,
        appNamePrefix: Environment.inappAppNamePrefix,
        // 프로덕션 SKU 옵트인이 켜진 샌드박스(스테이징)는 접두사 없이
        // 프로덕션 SKU 를 그대로 조회한다 — Android 에서 실제 스토어 상품이
        // 뜨게 하는 유일한 경로다 (iOS 는 원래부터 프로덕션 ID).
        androidPrefix:
            Environment.currentEnvironment == 'prod' ||
                Environment.currentEnvironment == 'test' ||
                Environment.sandboxUsesProductionStoreSkus
            ? ''
            : Environment.paymentProductNamespace,
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
