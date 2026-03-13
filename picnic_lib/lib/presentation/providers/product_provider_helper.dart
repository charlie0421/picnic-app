import 'package:flutter/foundation.dart';

/// Pure helper methods extracted from ProductProvider for testability.
@visibleForTesting
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
  }) {
    return serverProducts
        .map((product) => isAndroid
            ? product['id'].toString().toLowerCase()
            : appNamePrefix + product['id'].toString())
        .toSet();
  }

  /// Validates that the products list is not empty.
  /// Throws an exception if it is.
  static void validateProductsNotEmpty(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      throw Exception('No products found');
    }
  }

  /// Checks if an error message indicates a Supabase initialization issue.
  static bool isSupabaseInitError(String errorMessage) {
    return errorMessage.contains('Project not specified') ||
        errorMessage.contains('not initialized');
  }
}
