import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';

/// A fake IAPError for testing (IAPError has no public constructor usable
/// directly, so we use the in_app_purchase package's IAPError which does).
IAPError _makeIAPError(String code, {String message = ''}) {
  return IAPError(
    source: 'test',
    code: code,
    message: message,
  );
}

/// Minimal fake ProductDetails for testing findProductDetails.
ProductDetails _makeProduct(String id) {
  return ProductDetails(
    id: id,
    title: 'Test $id',
    description: 'Desc',
    price: '1.00',
    rawPrice: 1.0,
    currencyCode: 'USD',
  );
}

void main() {
  const helper = PurchaseServiceHelper();

  // ==================================================================
  // getErrorMessage
  // ==================================================================
  group('getErrorMessage', () {
    test('null error returns GENERIC', () {
      expect(helper.getErrorMessage(null), 'GENERIC');
    });

    test('payment_invalid returns Korean message', () {
      final error = _makeIAPError('payment_invalid');
      expect(helper.getErrorMessage(error), '결제 정보가 유효하지 않습니다.');
    });

    test('payment_canceled returns ERR_PURCHASE_CANCELED', () {
      final error = _makeIAPError('payment_canceled');
      expect(
        helper.getErrorMessage(error),
        PurchaseConstants.errPurchaseCanceled,
      );
    });

    test('store_problem returns ERR_SERVER', () {
      final error = _makeIAPError('store_problem');
      expect(helper.getErrorMessage(error), PurchaseConstants.errServer);
    });

    test('unknown code returns GENERIC', () {
      final error = _makeIAPError('unknown_error_code');
      expect(helper.getErrorMessage(error), 'GENERIC');
    });

    test('empty code returns GENERIC', () {
      final error = _makeIAPError('');
      expect(helper.getErrorMessage(error), 'GENERIC');
    });

    test('numeric-like code returns GENERIC', () {
      final error = _makeIAPError('12345');
      expect(helper.getErrorMessage(error), 'GENERIC');
    });
  });

  // ==================================================================
  // getDetailedErrorMessage
  // ==================================================================
  group('getDetailedErrorMessage', () {
    test('Receipt verification failed', () {
      expect(
        helper.getDetailedErrorMessage(
          Exception('Receipt verification failed'),
        ),
        'RECEIPT_VERIFICATION_FAILED',
      );
    });

    test('timeout in English', () {
      expect(
        helper.getDetailedErrorMessage(Exception('Connection timeout')),
        PurchaseConstants.errTimeout,
      );
    });

    test('timeout in Korean', () {
      expect(
        helper.getDetailedErrorMessage(Exception('요청 타임아웃 발생')),
        PurchaseConstants.errTimeout,
      );
    });

    test('Touch ID error', () {
      expect(
        helper.getDetailedErrorMessage(
          Exception('Touch ID authentication failed'),
        ),
        PurchaseConstants.errAuthTimeout,
      );
    });

    test('Face ID error', () {
      expect(
        helper.getDetailedErrorMessage(Exception('Face ID was cancelled')),
        PurchaseConstants.errAuthTimeout,
      );
    });

    test('USER_NOT_AUTHENTICATED', () {
      expect(
        helper.getDetailedErrorMessage(
          Exception('USER_NOT_AUTHENTICATED'),
        ),
        'USER_NOT_AUTHENTICATED',
      );
    });

    test('PRODUCT_NOT_FOUND', () {
      expect(
        helper.getDetailedErrorMessage(Exception('PRODUCT_NOT_FOUND')),
        'PRODUCT_NOT_FOUND',
      );
    });

    test('network error (case insensitive)', () {
      expect(
        helper.getDetailedErrorMessage(Exception('Network connection lost')),
        PurchaseConstants.errNetwork,
      );
    });

    test('Network uppercase', () {
      expect(
        helper.getDetailedErrorMessage(Exception('NETWORK error')),
        PurchaseConstants.errNetwork,
      );
    });

    test('server error (case insensitive)', () {
      expect(
        helper.getDetailedErrorMessage(Exception('Internal Server Error')),
        PurchaseConstants.errServer,
      );
    });

    test('unknown error returns GENERIC', () {
      expect(
        helper.getDetailedErrorMessage(Exception('Something went wrong')),
        'GENERIC',
      );
    });

    test('empty string returns GENERIC', () {
      expect(helper.getDetailedErrorMessage(''), 'GENERIC');
    });

    test('works with String input (not Exception)', () {
      expect(
        helper.getDetailedErrorMessage('Receipt verification failed here'),
        'RECEIPT_VERIFICATION_FAILED',
      );
    });

    test('works with StateError', () {
      expect(
        helper.getDetailedErrorMessage(StateError('timeout occurred')),
        PurchaseConstants.errTimeout,
      );
    });

    test('priority: receipt verification over server keyword', () {
      // "Receipt verification failed" contains "server" via case-insensitive,
      // but receipt verification should match first.
      expect(
        helper.getDetailedErrorMessage(
          Exception('Receipt verification failed on server'),
        ),
        'RECEIPT_VERIFICATION_FAILED',
      );
    });

    test('priority: Touch ID over timeout', () {
      // If both keywords present, Touch ID check comes after timeout,
      // so if only "Touch ID" is present, it should match AUTH_TIMEOUT.
      expect(
        helper.getDetailedErrorMessage(Exception('Touch ID error')),
        PurchaseConstants.errAuthTimeout,
      );
    });
  });

  // ==================================================================
  // getUserFriendlyErrorMessage
  // ==================================================================
  group('getUserFriendlyErrorMessage', () {
    test('product info error returns product message', () {
      expect(
        helper.getUserFriendlyErrorMessage(Exception('상품 정보를 찾을 수 없습니다')),
        '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.',
      );
    });

    test('network error returns network message', () {
      expect(
        helper.getUserFriendlyErrorMessage(Exception('네트워크 오류 발생')),
        '네트워크 연결을 확인해주세요.',
      );
    });

    test('generic error returns default message', () {
      expect(
        helper.getUserFriendlyErrorMessage(Exception('Unknown error')),
        '구매 시작 중 오류가 발생했습니다',
      );
    });

    test('empty error returns default message', () {
      expect(
        helper.getUserFriendlyErrorMessage(''),
        '구매 시작 중 오류가 발생했습니다',
      );
    });

    test('product info keyword partial match', () {
      expect(
        helper.getUserFriendlyErrorMessage(Exception('서버에서 상품 정보를 가져올 수 없음')),
        '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.',
      );
    });

    test('network keyword partial match', () {
      expect(
        helper.getUserFriendlyErrorMessage(Exception('네트워크 연결 실패')),
        '네트워크 연결을 확인해주세요.',
      );
    });
  });

  // ==================================================================
  // findProductDetails
  // ==================================================================
  group('findProductDetails', () {
    test('staging Android query id selects the same product', () {
      final products = [_makeProduct('staging.star10000')];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: true,
        inappAppNamePrefix: '',
        environment: 'dev',
        paymentProductNamespace: 'staging.',
      );
      expect(result.id, 'staging.star10000');
    });

    test('staging Android rejects a product from the wrong namespace', () {
      final products = [_makeProduct('other.star10000')];
      expect(
        () => helper.findProductDetails(
          storeProducts: products,
          serverProductId: 'STAR10000',
          isAndroid: true,
          inappAppNamePrefix: '',
          environment: 'dev',
          paymentProductNamespace: 'staging.',
        ),
        throwsException,
      );
    });

    test(
      'dev Android without namespace falls back to the production SKU',
      () {
        // 네임스페이스 미설정 dev 빌드는 프로덕션 SKU를 그대로 쓴다
        // (라이선스 테스터 결제). wallet.v1 서버가 정규화 SKU로 Google을
        // 조회하므로 이 경로가 서버 설계와 정합하다.
        final products = [_makeProduct('star10000')];
        final result = helper.findProductDetails(
          storeProducts: products,
          serverProductId: 'STAR10000',
          isAndroid: true,
          inappAppNamePrefix: '',
          environment: 'dev',
          paymentProductNamespace: '',
        );
        expect(result.id, 'star10000');
      },
    );

    test('production Android remains unprefixed and case normalized', () {
      final products = [_makeProduct('star10000')];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'Star10000',
        isAndroid: true,
        inappAppNamePrefix: '',
        environment: 'prod',
        paymentProductNamespace: 'staging.',
      );
      expect(result.id, 'star10000');
    });

    test('finds Android product by uppercase ID match', () {
      final products = [
        _makeProduct('star10000'),
        _makeProduct('star7000'),
      ];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: true,
        inappAppNamePrefix: 'com.example.',
      );
      expect(result.id, 'star10000');
    });

    test('finds iOS product by prefix + ID match', () {
      final products = [
        _makeProduct('com.example.STAR10000'),
        _makeProduct('com.example.STAR7000'),
      ];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: false,
        inappAppNamePrefix: 'com.example.',
      );
      expect(result.id, 'com.example.STAR10000');
    });

    test('throws when Android product not found', () {
      final products = [_makeProduct('star7000')];
      expect(
        () => helper.findProductDetails(
          storeProducts: products,
          serverProductId: 'STAR10000',
          isAndroid: true,
          inappAppNamePrefix: 'com.example.',
        ),
        throwsException,
      );
    });

    test('throws when iOS product not found', () {
      final products = [_makeProduct('com.example.STAR7000')];
      expect(
        () => helper.findProductDetails(
          storeProducts: products,
          serverProductId: 'STAR10000',
          isAndroid: false,
          inappAppNamePrefix: 'com.example.',
        ),
        throwsException,
      );
    });

    test('throws when store products list is empty', () {
      expect(
        () => helper.findProductDetails(
          storeProducts: [],
          serverProductId: 'STAR10000',
          isAndroid: true,
          inappAppNamePrefix: 'com.example.',
        ),
        throwsException,
      );
    });

    test('Android: case sensitivity - id must uppercase match serverProductId',
        () {
      final products = [_makeProduct('STAR10000')];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: true,
        inappAppNamePrefix: '',
      );
      expect(result.id, 'STAR10000');
    });

    test('iOS: exact prefix match required', () {
      final products = [_makeProduct('wrong.prefix.STAR10000')];
      expect(
        () => helper.findProductDetails(
          storeProducts: products,
          serverProductId: 'STAR10000',
          isAndroid: false,
          inappAppNamePrefix: 'com.example.',
        ),
        throwsException,
      );
    });

    test('finds first matching product when duplicates exist', () {
      final products = [
        _makeProduct('star10000'),
        _makeProduct('star10000'),
      ];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: true,
        inappAppNamePrefix: '',
      );
      expect(result.id, 'star10000');
    });
  });

  // ==================================================================
  // buildSuccessResult
  // ==================================================================
  group('buildSuccessResult', () {
    test('returns correct structure', () {
      final result = helper.buildSuccessResult();
      expect(result['success'], isTrue);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], isNull);
    });

    test('has exactly 3 keys', () {
      final result = helper.buildSuccessResult();
      expect(result.keys.length, 3);
    });
  });

  // ==================================================================
  // buildCancelledResult
  // ==================================================================
  group('buildCancelledResult', () {
    test('returns correct structure', () {
      final result = helper.buildCancelledResult();
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isTrue);
      expect(result['errorMessage'], isNull);
    });

    test('has exactly 3 keys', () {
      final result = helper.buildCancelledResult();
      expect(result.keys.length, 3);
    });
  });

  // ==================================================================
  // buildErrorResult
  // ==================================================================
  group('buildErrorResult', () {
    test('returns correct structure without denyType', () {
      final result = helper.buildErrorResult('Something went wrong');
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], 'Something went wrong');
      expect(result.containsKey('denyType'), isFalse);
    });

    test('returns correct structure with denyType', () {
      final result = helper.buildErrorResult(
        'Duplicate detected',
        denyType: 'COOLDOWN',
      );
      expect(result['success'], isFalse);
      expect(result['wasCancelled'], isFalse);
      expect(result['errorMessage'], 'Duplicate detected');
      expect(result['denyType'], 'COOLDOWN');
    });

    test('has 3 keys without denyType', () {
      final result = helper.buildErrorResult('error');
      expect(result.keys.length, 3);
    });

    test('has 4 keys with denyType', () {
      final result = helper.buildErrorResult('error', denyType: 'TYPE');
      expect(result.keys.length, 4);
    });

    test('preserves Korean error messages', () {
      final result = helper.buildErrorResult('로그인이 필요합니다');
      expect(result['errorMessage'], '로그인이 필요합니다');
    });

    test('preserves empty error message', () {
      final result = helper.buildErrorResult('');
      expect(result['errorMessage'], '');
    });
  });

  // ==================================================================
  // ReusedPurchaseException (from receipt_verification_service.dart)
  // ==================================================================
  group('ReusedPurchaseException', () {
    test('creates with message', () {
      final exception = ReusedPurchaseException(message: 'Duplicate');
      expect(exception.message, 'Duplicate');
      expect(exception.receiptId, isNull);
    });

    test('creates with message and receiptId', () {
      final exception = ReusedPurchaseException(
        message: 'Duplicate',
        receiptId: 'receipt_123',
      );
      expect(exception.message, 'Duplicate');
      expect(exception.receiptId, 'receipt_123');
    });

    test('toString format', () {
      final exception =
          ReusedPurchaseException(message: 'Already processed');
      expect(
        exception.toString(),
        'ReusedPurchaseException: Already processed',
      );
    });

    test('implements Exception', () {
      final exception = ReusedPurchaseException(message: 'test');
      expect(exception, isA<Exception>());
    });
  });

  // ==================================================================
  // getErrorMessage - additional edge cases
  // ==================================================================
  group('getErrorMessage - additional', () {
    test('code with whitespace returns GENERIC', () {
      final error = _makeIAPError(' payment_invalid ');
      expect(helper.getErrorMessage(error), 'GENERIC');
    });

    test('case sensitive code matching', () {
      final error = _makeIAPError('PAYMENT_INVALID');
      expect(helper.getErrorMessage(error), 'GENERIC');
    });

    test('payment_canceled message content', () {
      final error = _makeIAPError('payment_canceled');
      expect(helper.getErrorMessage(error), isNotEmpty);
    });
  });

  // ==================================================================
  // getDetailedErrorMessage - additional edge cases
  // ==================================================================
  group('getDetailedErrorMessage - additional', () {
    test('null input returns GENERIC', () {
      expect(helper.getDetailedErrorMessage(null), 'GENERIC');
    });

    test('integer input returns GENERIC', () {
      expect(helper.getDetailedErrorMessage(42), 'GENERIC');
    });

    test('error with multiple matching keywords returns first match', () {
      // "timeout" comes before "network" in the check order
      expect(
        helper.getDetailedErrorMessage(Exception('timeout network error')),
        PurchaseConstants.errTimeout,
      );
    });

    test('Touch ID with timeout - Touch ID comes after timeout', () {
      // "timeout" check is before "Touch ID" check
      expect(
        helper.getDetailedErrorMessage(Exception('timeout Touch ID')),
        PurchaseConstants.errTimeout,
      );
    });

    test('SERVER in all caps matches case insensitive', () {
      expect(
        helper.getDetailedErrorMessage(Exception('SERVER error occurred')),
        PurchaseConstants.errServer,
      );
    });

    test('Boolean input returns GENERIC', () {
      expect(helper.getDetailedErrorMessage(true), 'GENERIC');
    });

    test('list input returns GENERIC', () {
      expect(helper.getDetailedErrorMessage([1, 2, 3]), 'GENERIC');
    });
  });

  // ==================================================================
  // getUserFriendlyErrorMessage - additional
  // ==================================================================
  group('getUserFriendlyErrorMessage - additional', () {
    test('null input returns default', () {
      expect(
        helper.getUserFriendlyErrorMessage(null),
        '구매 시작 중 오류가 발생했습니다',
      );
    });

    test('integer input returns default', () {
      expect(
        helper.getUserFriendlyErrorMessage(42),
        '구매 시작 중 오류가 발생했습니다',
      );
    });

    test('priority: 상품 정보 over 네트워크', () {
      expect(
        helper.getUserFriendlyErrorMessage(
            Exception('상품 정보 네트워크 오류')),
        '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.',
      );
    });
  });

  // ==================================================================
  // findProductDetails - additional
  // ==================================================================
  group('findProductDetails - additional', () {
    test('Android: lowercase id matches uppercase serverProductId', () {
      final products = [_makeProduct('star7000')];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR7000',
        isAndroid: true,
        inappAppNamePrefix: 'com.example.',
      );
      expect(result.id, 'star7000');
    });

    test('iOS: empty prefix matches id exactly', () {
      final products = [_makeProduct('STAR10000')];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR10000',
        isAndroid: false,
        inappAppNamePrefix: '',
      );
      expect(result.id, 'STAR10000');
    });

    test('Android: multiple products, matches correct one', () {
      final products = [
        _makeProduct('star1000'),
        _makeProduct('star5000'),
        _makeProduct('star10000'),
      ];
      final result = helper.findProductDetails(
        storeProducts: products,
        serverProductId: 'STAR5000',
        isAndroid: true,
        inappAppNamePrefix: '',
      );
      expect(result.id, 'star5000');
    });
  });

  // ==================================================================
  // buildErrorResult - additional
  // ==================================================================
  group('buildErrorResult - additional', () {
    test('denyType with empty string', () {
      final result = helper.buildErrorResult('error', denyType: '');
      expect(result['denyType'], '');
      expect(result.keys.length, 4);
    });

    test('null denyType produces 3 keys', () {
      final result = helper.buildErrorResult('error', denyType: null);
      expect(result.containsKey('denyType'), isFalse);
      expect(result.keys.length, 3);
    });
  });

  // ==================================================================
  // PurchaseStatusExtension (comprehensive)
  // ==================================================================
  group('PurchaseStatusExtension (all statuses)', () {
    test('all statuses have exactly one true state', () {
      for (final status in PurchaseStatus.values) {
        final states = [
          status.isCompleted,
          status.isFailed,
          status.isPending,
        ];
        final trueCount = states.where((s) => s).length;
        expect(trueCount, 1,
            reason: '$status should have exactly one true state');
      }
    });
  });

  group('storeHasProduct — 구매 버튼 활성 판정', () {
    // 실제 회귀: 서버 ID 는 대문자 STARxxx, Play SKU 는 소문자 강제.
    // raw 비교(product.id == serverId)는 Android 에서 구조적으로 false 라
    // 스토어에 상품이 떠 있는데 구매 버튼이 전부 죽었다 (252b7c54b 도입,
    // 미출시). findProductDetails 와 같은 정책이어야 한다.
    const helper = PurchaseServiceHelper();

    test('Android: 프로덕션 SKU(소문자)와 서버 ID(대문자)를 매칭한다', () {
      expect(
        helper.storeHasProduct(
          storeProducts: [_makeProduct('star100')],
          serverProductId: 'STAR100',
          isAndroid: true,
          inappAppNamePrefix: '',
          environment: 'dev',
          paymentProductNamespace: '', // 프로덕션 SKU 옵트인 상태
        ),
        isTrue,
        reason: 'raw 비교로 되돌리면 여기서 실패한다',
      );
    });

    test('Android: 네임스페이스 격리 모드에서는 접두사 ID 로 매칭한다', () {
      expect(
        helper.storeHasProduct(
          storeProducts: [_makeProduct('staging.star100')],
          serverProductId: 'STAR100',
          isAndroid: true,
          inappAppNamePrefix: '',
          environment: 'dev',
          paymentProductNamespace: 'staging.',
        ),
        isTrue,
      );
    });

    test('iOS: 접두사 규칙으로 매칭한다', () {
      expect(
        helper.storeHasProduct(
          storeProducts: [_makeProduct('PICNICSTAR100')],
          serverProductId: 'STAR100',
          isAndroid: false,
          inappAppNamePrefix: 'PICNIC',
          environment: 'dev',
        ),
        isTrue,
      );
      // 접두사 없는 iOS (현 프로덕션 설정: prefix '')
      expect(
        helper.storeHasProduct(
          storeProducts: [_makeProduct('STAR100')],
          serverProductId: 'STAR100',
          isAndroid: false,
          inappAppNamePrefix: '',
          environment: 'dev',
        ),
        isTrue,
      );
    });

    test('카탈로그에 없는 상품은 false — 버튼이 비활성이어야 한다', () {
      expect(
        helper.storeHasProduct(
          storeProducts: [_makeProduct('star100')],
          serverProductId: 'STAR9999',
          isAndroid: true,
          inappAppNamePrefix: '',
          environment: 'dev',
          paymentProductNamespace: '',
        ),
        isFalse,
      );
    });

    test('findProductDetails 와 판정이 항상 일치한다', () {
      // 두 함수가 다른 정책을 쓰기 시작하면 "버튼은 활성인데 구매에서
      // 상품을 못 찾는" (또는 그 반대) 반쪽 동작이 된다.
      final products = [_makeProduct('star100'), _makeProduct('PICNICSTAR200')];
      for (final c in [
        ('STAR100', true, '', ''),
        ('STAR200', false, 'PICNIC', ''),
        ('STAR300', true, '', ''),
      ]) {
        final (serverId, isAndroid, iosPrefix, ns) = c;
        final has = helper.storeHasProduct(
          storeProducts: products,
          serverProductId: serverId,
          isAndroid: isAndroid,
          inappAppNamePrefix: iosPrefix,
          environment: 'dev',
          paymentProductNamespace: ns,
        );
        ProductDetails? found;
        try {
          found = helper.findProductDetails(
            storeProducts: products,
            serverProductId: serverId,
            isAndroid: isAndroid,
            inappAppNamePrefix: iosPrefix,
            environment: 'dev',
            paymentProductNamespace: ns,
          );
        } catch (_) {
          found = null;
        }
        expect(has, found != null,
            reason: '$serverId: storeHasProduct=$has 인데 '
                'findProductDetails=${found != null}');
      }
    });
  });
}
