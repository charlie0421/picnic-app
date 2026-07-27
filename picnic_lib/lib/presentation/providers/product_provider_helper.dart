import 'package:picnic_lib/core/config/payment_product_id_policy.dart';

/// Pure helper methods extracted from ProductProvider for testability.
class ProductProviderHelper {
  /// Finds a product by its ID from a list of products.
  /// Returns null if the list is null, empty, or no product matches.
  static Map<String, dynamic>? findProductById(
    List<Map<String, dynamic>>? products,
    String id,
  ) {
    if (products == null) return null;
    try {
      return products.firstWhere((product) => product['id'] == id);
    } catch (_) {
      return null;
    }
  }

  /// Builds a set of platform-specific product IDs from server products.
  /// On Android, IDs are lowercased. On other platforms, a prefix is prepended.
  static Set<String> buildProductIds(
    List<Map<String, dynamic>> serverProducts, {
    required bool isAndroid,
    required String appNamePrefix,
    String androidPrefix = '',
    String environment = 'prod',
  }) {
    return serverProducts
        .map(
          (product) => PaymentProductIdPolicy.effectiveProductId(
            environment: environment,
            isAndroid: isAndroid,
            paymentNamespace: androidPrefix,
            serverProductId: product['id'].toString(),
            iosAppPrefix: appNamePrefix,
          ),
        )
        .toSet();
  }

  /// Validates that the products list is not empty.
  /// Throws an exception if it is.
  static void validateProductsNotEmpty(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      throw Exception('No products found');
    }
  }

  static void validateSandboxProductIds(
    Set<String> productIds, {
    required String namespace,
  }) {
    if (namespace.isEmpty ||
        productIds.any((productId) => !productId.startsWith(namespace))) {
      throw StateError('Sandbox product catalog is not isolated');
    }
  }

  static bool shouldUseServerCatalogPreview({
    required String environment,
    required Object error,
  }) {
    if (environment == 'prod' || environment == 'test') return false;
    return error is StateError &&
        error.message == 'Sandbox product catalog is not isolated';
  }

  /// 샌드박스에서 스토어가 상품 0개를 돌려줬을 때도 서버 카탈로그
  /// 미리보기(구매 비활성)로 폴백할지 여부.
  ///
  /// 스테이징은 프로덕션 상품을 그대로 쓰되 구매 테스트는 iOS 만 하기로
  /// 결정돼 있다 — Android 스테이징 빌드는 dev 환경이라 상품 ID 에
  /// 네임스페이스가 붙어 스토어 매칭이 0개가 되는 것이 정상이다. 그 경우
  /// 사용자에게 raw 예외 문자열 대신 카탈로그(버튼 비활성)를 보여준다.
  /// 프로덕션에서 상품 0개는 실제 장애이므로 여전히 오류다.
  static bool shouldPreviewEmptyStoreCatalog({required String environment}) =>
      environment != 'prod' && environment != 'test';

  /// Checks if an error message indicates a Supabase initialization issue.
  static bool isSupabaseInitError(String errorMessage) {
    return errorMessage.contains('Project not specified') ||
        errorMessage.contains('not initialized');
  }
}
