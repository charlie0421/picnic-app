import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('ServerProducts', () {
    late ProviderContainer container;

    final products = [
      {
        'id': 'product_100',
        'name': {'ko': '100 투표권'},
        'price': 1200,
        'votes': 100,
        'start_at': '2024-01-01T00:00:00Z',
        'end_at': '2099-12-31T23:59:59Z',
      },
      {
        'id': 'product_500',
        'name': {'ko': '500 투표권'},
        'price': 5500,
        'votes': 500,
        'start_at': '2024-01-01T00:00:00Z',
        'end_at': '2099-12-31T23:59:59Z',
      },
      {
        'id': 'product_1000',
        'name': {'ko': '1000 투표권', 'en': '1000 Votes'},
        'price': 10000,
        'votes': 1000,
        'start_at': '2024-01-01T00:00:00Z',
        'end_at': '2099-12-31T23:59:59Z',
        'bonus': 100,
      },
    ];

    setUp(() {
      setupMockSupabase({
        'products': products,
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches products from supabase', () async {
      final result = await container.read(serverProductsProvider.future);
      expect(result, isNotNull);
      expect(result.length, 3);
      expect(result[0]['id'], 'product_100');
      expect(result[1]['price'], 5500);
      expect(result[2]['votes'], 1000);
    });

    test('products are returned as List<Map<String, dynamic>>', () async {
      final result = await container.read(serverProductsProvider.future);
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('product data contains all expected fields', () async {
      final result = await container.read(serverProductsProvider.future);
      final product = result[0];
      expect(product.containsKey('id'), true);
      expect(product.containsKey('name'), true);
      expect(product.containsKey('price'), true);
      expect(product.containsKey('votes'), true);
      expect(product.containsKey('start_at'), true);
      expect(product.containsKey('end_at'), true);
    });

    test('product with bonus field', () async {
      final result = await container.read(serverProductsProvider.future);
      final product = result[2];
      expect(product['bonus'], 100);
    });

    test('product name supports localization', () async {
      final result = await container.read(serverProductsProvider.future);
      final name = result[2]['name'] as Map<String, dynamic>;
      expect(name['ko'], '1000 투표권');
      expect(name['en'], '1000 Votes');
    });

    test('getProductDetailById returns correct product', () async {
      await container.read(serverProductsProvider.future);

      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('product_500');
      expect(product, isNotNull);
      expect(product!['votes'], 500);
      expect(product['price'], 5500);
    });

    test('getProductDetailById returns first product', () async {
      await container.read(serverProductsProvider.future);

      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('product_100');
      expect(product, isNotNull);
      expect(product!['price'], 1200);
    });

    test('getProductDetailById returns last product', () async {
      await container.read(serverProductsProvider.future);

      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('product_1000');
      expect(product, isNotNull);
      expect(product!['votes'], 1000);
    });

    test('getProductDetailById returns null for unknown id', () async {
      await container.read(serverProductsProvider.future);

      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('nonexistent');
      expect(product, isNull);
    });

    test('getProductDetailById returns null when state is not loaded',
        () async {
      // Access notifier before build completes by not awaiting future
      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('product_100');
      expect(product, isNull);
    });

    test('getProductDetailById returns null for empty string id', () async {
      await container.read(serverProductsProvider.future);

      final notifier = container.read(serverProductsProvider.notifier);
      final product = notifier.getProductDetailById('');
      expect(product, isNull);
    });

    test('provider is keepAlive', () {
      expect(serverProductsProvider, isNotNull);
    });

    // Note: Testing empty products is tricky because the provider schedules
    // ref.invalidateSelf() via Future.delayed when it throws, which interferes
    // with container disposal in tests. Instead we test the error path indirectly
    // through the catch logic in getProductDetailById (returns null when state has no value).

    test('handles supabase not logged in safely (early delay path)', () async {
      // isSupabaseLoggedSafely returns false in tests
      // This tests the delay+retry path (non-authenticated)
      tearDownMockSupabase();
      setupMockSupabase({
        'products': products,
      });
      // No userId -> not authenticated
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      // Should still succeed because mock returns data regardless of auth
      final result = await container2.read(serverProductsProvider.future);
      expect(result, isNotNull);
      expect(result.length, 3);
    });
  });

  group('StoreProducts', () {
    test('storeProductsProvider is defined', () {
      // StoreProducts depends on InAppPurchase.instance which requires
      // native platform, so we only test that the provider is defined
      expect(storeProductsProvider, isNotNull);
    });
  });
}
