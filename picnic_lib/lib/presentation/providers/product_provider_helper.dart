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

  /// Checks if an error message indicates a Supabase initialization issue.
  static bool isSupabaseInitError(String errorMessage) {
    return errorMessage.contains('Project not specified') ||
        errorMessage.contains('not initialized');
  }
}
