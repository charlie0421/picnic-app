// product_providers.dart
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_app/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ServerProducts extends _$ServerProducts {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return _fetchProductsFromSupabase();
  }

  Future<List<Map<String, dynamic>>> _fetchProductsFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('products')
          .select()
          .lt('start_at', 'now()')
          .gt('end_at', 'now()')
          .order('price', ascending: true);

      final List<Map<String, dynamic>> products =
          List<Map<String, dynamic>>.from(response);

      if (products.isEmpty) {
        throw Exception('No products found');
      }

      return products;
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}

@Riverpod(keepAlive: true)
class StoreProducts extends _$StoreProducts {
  @override
  FutureOr<List<ProductDetails>> build() async {
    try {
      final serverProducts = await ref.watch(serverProductsProvider.future);
      return _loadProducts(serverProducts);
    } catch (e) {
      logger.e('Error in StoreProducts build: $e');
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
          .map((product) =>
                  Platform.isAndroid // check if the operating system is Android
                      ? product['id']
                          .toString()
                          .toLowerCase() // convert to lowercase for Android
                      : product['id'].toString() // use original ID for the rest
              )
          .toSet();

      final ProductDetailsResponse response =
          await inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Some product IDs were not recognized: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No products found in the store');
      }

      return response.productDetails;
    } catch (e) {
      logger.e('Error loading products: $e');
      throw Exception('Error loading products: $e');
    }
  }
}
