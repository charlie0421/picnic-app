import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/purchase_failure_classifier.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

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

    test('payment_invalid returns an error code, never a Korean sentence', () {
      // App Review 리뷰어를 포함한 비한국어 사용자가 한국어 오류 문장을
      // 그대로 보던 자리다. 문장은 arb 에서 온다.
      final error = _makeIAPError('payment_invalid');
      expect(helper.getErrorMessage(error), PurchaseConstants.errPaymentInvalid);
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
        PurchaseConstants.errProcessing,
      );
    });

    test('timeout in Korean', () {
      expect(
        helper.getDetailedErrorMessage(Exception('요청 타임아웃 발생')),
        PurchaseConstants.errProcessing,
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
        PurchaseConstants.errProcessing,
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
  // getPurchaseInitiationErrorCode
  //
  // 런치 단계 실패도 사용자 문장이 아니라 **에러 코드**를 돌려준다. 예전에
  // 여기서 만든 한국어 문장('상품 정보를 찾을 수 없습니다…' 등)이 그대로
  // 다이얼로그에 올라가, 로케일과 무관하게 한국어 오류가 노출됐다.
  // ==================================================================
  group('getPurchaseInitiationErrorCode', () {
    test('product info error maps to PRODUCT_NOT_FOUND', () {
      expect(
        helper.getPurchaseInitiationErrorCode(Exception('상품 정보를 찾을 수 없습니다')),
        'PRODUCT_NOT_FOUND',
      );
    });

    test('store catalogue miss also maps to PRODUCT_NOT_FOUND', () {
      // _findProductDetails 가 던지는 내부 문장.
      expect(
        helper.getPurchaseInitiationErrorCode(
          Exception('스토어에서 상품을 찾을 수 없습니다'),
        ),
        'PRODUCT_NOT_FOUND',
      );
    });

    test('network error maps to NETWORK', () {
      expect(
        helper.getPurchaseInitiationErrorCode(Exception('네트워크 오류 발생')),
        PurchaseConstants.errNetwork,
      );
    });

    test('English network error maps to NETWORK too', () {
      expect(
        helper.getPurchaseInitiationErrorCode(Exception('Network unreachable')),
        PurchaseConstants.errNetwork,
      );
    });

    test('generic error maps to GENERIC', () {
      expect(
        helper.getPurchaseInitiationErrorCode(Exception('Unknown error')),
        'GENERIC',
      );
    });

    test('empty error maps to GENERIC', () {
      expect(helper.getPurchaseInitiationErrorCode(''), 'GENERIC');
    });

    test('never returns a Korean sentence', () {
      for (final error in <Object>[
        Exception('상품 정보를 찾을 수 없습니다'),
        Exception('네트워크 연결 실패'),
        Exception('Unknown error'),
        TimeoutException('boom'),
      ]) {
        final code = helper.getPurchaseInitiationErrorCode(error);
        expect(
          RegExp(r'[가-힣]').hasMatch(code),
          isFalse,
          reason: '$error -> "$code" 에 한글이 섞이면 그대로 UI 에 노출된다',
        );
      }
    });

    test('a launch that timed out is not reported as a failure', () {
      expect(
        helper.getPurchaseInitiationErrorCode(TimeoutException('launch')),
        PurchaseConstants.errProcessing,
      );
    });
  });

  // ==================================================================
  // C-1: 타입/상태 코드 기반 분류
  //
  // 회귀 재현: 예전 구현은 errorString.contains('timeout') 으로 타임아웃을
  // 판별했다. TimeoutException.toString() 은 "TimeoutException after
  // 0:00:30.000000: Future not completed" — 소문자 'timeout' 이 없으므로
  // GENERIC → purchaseFailed(종결 실패)로 떨어졌다. FunctionException 은
  // 매칭할 단어가 아예 없어 503(재시도 가능)과 422(영구 거부)가 같은
  // 다이얼로그로 붕괴했다.
  // ==================================================================
  group('C-1 정산 실패 분류 (타입/상태 코드)', () {
    FunctionException status(int code, {Object? details}) =>
        FunctionException(status: code, details: details, reasonPhrase: 'test');

    test('TimeoutException.toString() 에는 소문자 timeout 이 없다 (회귀 전제)', () {
      expect(
        TimeoutException('x', const Duration(seconds: 30))
            .toString()
            .contains('timeout'),
        isFalse,
        reason: '이 전제가 깨지면 문자열 매칭 회귀의 재현 조건이 사라진다',
      );
    });

    test('TimeoutException 은 비종결(PROCESSING) 이다', () {
      expect(
        helper.getDetailedErrorMessage(
          TimeoutException('x', const Duration(seconds: 30)),
        ),
        PurchaseConstants.errProcessing,
      );
    });

    test('SocketException / HttpException / ClientException 도 비종결', () {
      for (final error in <Object>[
        const SocketException('connection reset'),
        const HttpException('bad gateway'),
        http.ClientException('connection closed'),
      ]) {
        expect(
          helper.getDetailedErrorMessage(error),
          PurchaseConstants.errProcessing,
          reason: '$error - 응답을 못 받았으니 정산 여부를 알 수 없다',
        );
      }
    });

    test('5xx 는 모두 비종결', () {
      for (final code in [500, 502, 503, 504]) {
        expect(
          helper.getDetailedErrorMessage(status(code)),
          PurchaseConstants.errProcessing,
          reason: 'HTTP $code',
        );
      }
    });

    test('서버가 retryable 로 표시한 응답은 상태 코드와 무관하게 비종결', () {
      expect(
        helper.getDetailedErrorMessage(
          status(409, details: {'retryable': true}),
        ),
        PurchaseConstants.errProcessing,
      );
      expect(
        helper.getDetailedErrorMessage(
          status(409, details: {
            'error': {'retryable': true},
          }),
        ),
        PurchaseConstants.errProcessing,
      );
    });

    test('422/400/403 은 영구 거부 - 재전송으로 뒤집히지 않는다', () {
      for (final code in PurchaseFailureClassifier.permanentStatuses) {
        expect(
          helper.getDetailedErrorMessage(status(code)),
          'RECEIPT_VERIFICATION_FAILED',
          reason: 'HTTP $code',
        );
      }
    });

    test('503 과 422 는 서로 다른 결과로 갈린다', () {
      // 서버가 의도적으로 구분한 두 응답이 하나의 다이얼로그로 붕괴하던 자리.
      expect(
        helper.getDetailedErrorMessage(status(503)),
        isNot(helper.getDetailedErrorMessage(status(422))),
      );
    });

    test('응답 계약 위반은 비종결 - 서버 정산은 이미 끝났다', () {
      expect(
        helper.getDetailedErrorMessage(
          ReceiptResponseContractException(message: 'schema mismatch'),
        ),
        PurchaseConstants.errProcessing,
      );
    });

    test('분류기는 문자열을 보지 않는다', () {
      // 'timeout' 이라는 단어가 없어도 타입만으로 판정되어야 한다.
      expect(
        PurchaseFailureClassifier.isStillProcessing(
          TimeoutException('Future not completed'),
        ),
        isTrue,
      );
      expect(
        PurchaseFailureClassifier.isStillProcessing(Exception('timeout')),
        isFalse,
        reason: '단순 Exception 은 타입 분류 대상이 아니다 (문자열 폴백이 처리)',
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
        PurchaseConstants.errProcessing,
      );
    });

    test('Touch ID with timeout - Touch ID comes after timeout', () {
      // "timeout" check is before "Touch ID" check
      expect(
        helper.getDetailedErrorMessage(Exception('timeout Touch ID')),
        PurchaseConstants.errProcessing,
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
  // getPurchaseInitiationErrorCode - additional
  // ==================================================================
  group('getPurchaseInitiationErrorCode - additional', () {
    test('null input returns GENERIC', () {
      expect(helper.getPurchaseInitiationErrorCode(null), 'GENERIC');
    });

    test('integer input returns GENERIC', () {
      expect(helper.getPurchaseInitiationErrorCode(42), 'GENERIC');
    });

    test('priority: 상품 정보 over 네트워크', () {
      expect(
        helper.getPurchaseInitiationErrorCode(Exception('상품 정보 네트워크 오류')),
        'PRODUCT_NOT_FOUND',
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
