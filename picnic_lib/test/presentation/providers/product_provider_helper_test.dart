import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/product_provider_helper.dart';

void main() {
  final sampleProducts = [
    {
      'id': 'product_100',
      'name': {'ko': '100 투표권'},
      'price': 1200,
      'votes': 100,
    },
    {
      'id': 'product_500',
      'name': {'ko': '500 투표권'},
      'price': 5500,
      'votes': 500,
    },
    {
      'id': 'PRODUCT_1000',
      'name': {'ko': '1000 투표권'},
      'price': 10000,
      'votes': 1000,
    },
  ];

  group('ProductProviderHelper.findProductById', () {
    test('returns correct product when id matches', () {
      final result =
          ProductProviderHelper.findProductById(sampleProducts, 'product_500');
      expect(result, isNotNull);
      expect(result!['id'], 'product_500');
      expect(result['price'], 5500);
    });

    test('returns first product when id matches first item', () {
      final result =
          ProductProviderHelper.findProductById(sampleProducts, 'product_100');
      expect(result, isNotNull);
      expect(result!['price'], 1200);
    });

    test('returns last product when id matches last item', () {
      final result = ProductProviderHelper.findProductById(
          sampleProducts, 'PRODUCT_1000');
      expect(result, isNotNull);
      expect(result!['votes'], 1000);
    });

    test('returns null when id does not match any product', () {
      final result =
          ProductProviderHelper.findProductById(sampleProducts, 'nonexistent');
      expect(result, isNull);
    });

    test('returns null when products list is null', () {
      final result =
          ProductProviderHelper.findProductById(null, 'product_100');
      expect(result, isNull);
    });

    test('returns null when products list is empty', () {
      final result =
          ProductProviderHelper.findProductById([], 'product_100');
      expect(result, isNull);
    });

    test('returns null for empty string id', () {
      final result = ProductProviderHelper.findProductById(sampleProducts, '');
      expect(result, isNull);
    });

    test('is case-sensitive for id matching', () {
      final result =
          ProductProviderHelper.findProductById(sampleProducts, 'product_1000');
      expect(result, isNull); // 'PRODUCT_1000' != 'product_1000'
    });
  });

  group('ProductProviderHelper.buildProductIds', () {
    test('builds the canonical staging Android query id', () {
      final result = ProductProviderHelper.buildProductIds(
        [
          {'id': 'Star10000'}
        ],
        isAndroid: true,
        appNamePrefix: '',
        androidPrefix: 'staging.',
        environment: 'dev',
      );
      expect(result, {'staging.star10000'});
    });

    test('lowercases ids on Android', () {
      final result = ProductProviderHelper.buildProductIds(
        sampleProducts,
        isAndroid: true,
        appNamePrefix: 'com.example.',
      );
      expect(result, contains('product_100'));
      expect(result, contains('product_500'));
      expect(result, contains('product_1000')); // lowercased from PRODUCT_1000
      expect(result.length, 3);
    });

    test('prepends prefix on non-Android (iOS)', () {
      final result = ProductProviderHelper.buildProductIds(
        sampleProducts,
        isAndroid: false,
        appNamePrefix: 'com.example.',
      );
      expect(result, contains('com.example.product_100'));
      expect(result, contains('com.example.product_500'));
      expect(result, contains('com.example.PRODUCT_1000'));
      expect(result.length, 3);
    });

    test('returns empty set for empty products list', () {
      final result = ProductProviderHelper.buildProductIds(
        [],
        isAndroid: true,
        appNamePrefix: 'com.example.',
      );
      expect(result, isEmpty);
    });

    test('returns a Set (no duplicates)', () {
      final duplicateProducts = [
        {'id': 'product_100'},
        {'id': 'product_100'},
      ];
      final result = ProductProviderHelper.buildProductIds(
        duplicateProducts,
        isAndroid: true,
        appNamePrefix: '',
      );
      expect(result.length, 1);
    });

    test('handles empty prefix on non-Android', () {
      final result = ProductProviderHelper.buildProductIds(
        [
          {'id': 'test_id'}
        ],
        isAndroid: false,
        appNamePrefix: '',
      );
      expect(result, contains('test_id'));
    });
  });

  group('ProductProviderHelper.validateProductsNotEmpty', () {
    test('does not throw for non-empty list', () {
      expect(
        () => ProductProviderHelper.validateProductsNotEmpty(sampleProducts),
        returnsNormally,
      );
    });

    test('throws Exception for empty list', () {
      expect(
        () => ProductProviderHelper.validateProductsNotEmpty([]),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No products found'),
        )),
      );
    });
  });

  group('ProductProviderHelper.validateSandboxProductIds', () {
    test('rejects a production product id in a sandbox catalog', () {
      expect(
        () => ProductProviderHelper.validateSandboxProductIds(
          {'STAR100'},
          namespace: 'staging.',
        ),
        throwsStateError,
      );
    });

    test('accepts only explicitly namespaced sandbox product ids', () {
      expect(
        () => ProductProviderHelper.validateSandboxProductIds(
          {'staging.STAR100'},
          namespace: 'staging.',
        ),
        returnsNormally,
      );
    });
  });

  group('ProductProviderHelper.isSupabaseInitError', () {
    test('returns true for "Project not specified" error', () {
      expect(
        ProductProviderHelper.isSupabaseInitError(
            'Error: Project not specified in request'),
        isTrue,
      );
    });

    test('returns true for "not initialized" error', () {
      expect(
        ProductProviderHelper.isSupabaseInitError(
            'Supabase client not initialized'),
        isTrue,
      );
    });

    test('returns false for unrelated error', () {
      expect(
        ProductProviderHelper.isSupabaseInitError('Network timeout'),
        isFalse,
      );
    });

    test('returns false for empty string', () {
      expect(
        ProductProviderHelper.isSupabaseInitError(''),
        isFalse,
      );
    });

    test('is case-sensitive', () {
      expect(
        ProductProviderHelper.isSupabaseInitError('NOT INITIALIZED'),
        isFalse,
      );
    });
  });
}
