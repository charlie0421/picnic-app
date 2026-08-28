import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_format_helper.dart';

void main() {
  group('ReceiptFormatHelper.detectReceiptFormat', () {
    test('returns StoreKit2 JWT for eyJ prefix', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('eyJhbGciOiJFUzI1NiJ9.payload.sig'),
        'StoreKit2 JWT',
      );
    });

    test('returns StoreKit2 JWT for eyJ prefix without dots', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('eyJdata'),
        'StoreKit2 JWT',
      );
    });

    test('returns StoreKit1 Base64 for MIIT prefix', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('MIITsomeBase64Data'),
        'StoreKit1 Base64',
      );
    });

    test('returns StoreKit1 Base64 for MIIK prefix', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('MIIKsomeOtherBase64'),
        'StoreKit1 Base64',
      );
    });

    test('returns JWT Custom for 3-part dot-separated string', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('header.payload.signature'),
        'JWT Custom',
      );
    });

    test('returns Unknown for plain text', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('plain-receipt-data'),
        'Unknown',
      );
    });

    test('returns Unknown for empty string', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat(''),
        'Unknown',
      );
    });

    test('returns Unknown for 2-part dot-separated string', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('part1.part2'),
        'Unknown',
      );
    });

    test('returns Unknown for 4-part dot-separated string (not starting with eyJ)', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('a.b.c.d'),
        'Unknown',
      );
    });

    test('eyJ prefix takes priority over 3-part check', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('eyJhbGc.payload.sig'),
        'StoreKit2 JWT',
      );
    });

    test('MIIT prefix takes priority over 3-part check', () {
      expect(
        ReceiptFormatHelper.detectReceiptFormat('MIIT.some.data'),
        'StoreKit1 Base64',
      );
    });
  });

  group('ReceiptFormatHelper.validateInputs', () {
    test('does not throw for valid inputs', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('receipt', 'product', 'user'),
        returnsNormally,
      );
    });

    test('throws for empty receipt', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('', 'product', 'user'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('영수증 데이터가 비어있습니다'),
        )),
      );
    });

    test('throws for empty productId', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('receipt', '', 'user'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('상품 ID가 비어있습니다'),
        )),
      );
    });

    test('throws for empty userId', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('receipt', 'product', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('사용자 ID가 비어있습니다'),
        )),
      );
    });

    test('receipt error takes priority when all empty', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('', '', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('영수증 데이터가 비어있습니다'),
        )),
      );
    });

    test('productId error comes before userId when receipt is valid', () {
      expect(
        () => ReceiptFormatHelper.validateInputs('receipt', '', ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('상품 ID가 비어있습니다'),
        )),
      );
    });
  });

  group('ReceiptFormatHelper.makeIdemKeyFromJWS', () {
    test('creates ios key from valid JWS with transactionId and signedDate', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"transactionId":"tx-999","signedDate":"2024-01-01T00:00:00Z"}',
      ));
      final jws = '$header.$payload.signature';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, 'ios:tx-999:2024-01-01T00:00:00Z');
    });

    test('uses originalTransactionId when transactionId is absent', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"originalTransactionId":"orig-tx-1","purchaseDate":"2024-06-01"}',
      ));
      final jws = '$header.$payload.sig';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, 'ios:orig-tx-1:2024-06-01');
    });

    test('uses originalPurchaseDate when signedDate and purchaseDate absent', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"transactionId":"tx-100","originalPurchaseDate":"2024-03-15"}',
      ));
      final jws = '$header.$payload.sig';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, 'ios:tx-100:2024-03-15');
    });

    test('returns empty strings for missing fields in payload', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"productId":"com.app.coins","quantity":1}',
      ));
      final jws = '$header.$payload.sig';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, 'ios::');
    });

    test('returns raw hash key for non-JWT input', () {
      const nonJwt = 'simple-receipt-data';
      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(nonJwt);
      expect(key, startsWith('raw:'));
      expect(key, 'raw:${nonJwt.hashCode}');
    });

    test('returns raw hash key for StoreKit1 Base64', () {
      const receipt = 'MIITbase64data';
      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(receipt);
      expect(key, startsWith('raw:'));
    });

    test('returns raw hash key for malformed JWT payload', () {
      final key = ReceiptFormatHelper.makeIdemKeyFromJWS('eyJ@@@.invalid.sig');
      expect(key, startsWith('raw:'));
    });

    test('returns raw hash key for empty string', () {
      final key = ReceiptFormatHelper.makeIdemKeyFromJWS('');
      expect(key, startsWith('raw:'));
    });

    test('handles URL-safe base64 characters in payload', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url
          .encode(utf8.encode('{"transactionId":"tx+special","signedDate":"2024-01-01"}'))
          .replaceAll('=', '');
      final jws = '$header.$payload.sig';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, startsWith('ios:'));
      expect(key, contains('tx+special'));
    });

    test('handles numeric transactionId and signedDate', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode(
        '{"transactionId":12345,"signedDate":1700000000}',
      ));
      final jws = '$header.$payload.sig';

      final key = ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
      expect(key, 'ios:12345:1700000000');
    });
  });

  group('ReceiptFormatHelper.getIOSReceiptFormatParam', () {
    test('returns storekit2_jwt for StoreKit2 JWT format', () {
      expect(
        ReceiptFormatHelper.getIOSReceiptFormatParam('StoreKit2 JWT'),
        'storekit2_jwt',
      );
    });

    test('returns legacy for StoreKit1 Base64 format', () {
      expect(
        ReceiptFormatHelper.getIOSReceiptFormatParam('StoreKit1 Base64'),
        'legacy',
      );
    });

    test('returns legacy for JWT Custom format', () {
      expect(
        ReceiptFormatHelper.getIOSReceiptFormatParam('JWT Custom'),
        'legacy',
      );
    });

    test('returns legacy for Unknown format', () {
      expect(
        ReceiptFormatHelper.getIOSReceiptFormatParam('Unknown'),
        'legacy',
      );
    });

    test('returns legacy for empty string', () {
      expect(
        ReceiptFormatHelper.getIOSReceiptFormatParam(''),
        'legacy',
      );
    });
  });

  group('ReceiptFormatHelper.isStoreKit2JWT', () {
    test('returns true for valid JWT with eyJ prefix and 3 parts', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode('{"sub":"123"}'));
      final jwt = '$header.$payload.signature';
      expect(ReceiptFormatHelper.isStoreKit2JWT(jwt), isTrue);
    });

    test('returns true for minimal eyJ with 3 parts', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('eyJhbGc.eyJzdWI.sig'), isTrue);
    });

    test('returns false for empty string', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT(''), isFalse);
    });

    test('returns false for non-eyJ prefix', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('abc.def.ghi'), isFalse);
    });

    test('returns false for eyJ prefix with only 2 parts', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('eyJhbGc.eyJzdWI'), isFalse);
    });

    test('returns false for eyJ prefix with 4 parts', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('eyJhbGc.b.c.d'), isFalse);
    });

    test('returns false for eyJ prefix with 1 part (no dots)', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('eyJhbGciOiJFUzI1NiJ9'), isFalse);
    });

    test('returns false for StoreKit1 Base64', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('MIITbase64data'), isFalse);
    });

    test('returns false for plain text', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('hello world'), isFalse);
    });
  });

  group('ReceiptFormatHelper.decodeJWTPart', () {
    test('decodes standard base64url-encoded JSON', () {
      final encoded = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result, {'alg': 'ES256'});
    });

    test('decodes payload with multiple fields', () {
      final payload = {
        'transactionId': 'tx-123',
        'productId': 'com.app.coins',
        'quantity': 1,
      };
      final encoded = base64Url.encode(utf8.encode(json.encode(payload)));
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result['transactionId'], 'tx-123');
      expect(result['productId'], 'com.app.coins');
      expect(result['quantity'], 1);
    });

    test('handles base64url without padding', () {
      final encoded = base64Url.encode(utf8.encode('{"a":"b"}'))
          .replaceAll('=', '');
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result, {'a': 'b'});
    });

    test('handles base64url with URL-safe characters (- and _)', () {
      // Manually create a string that would have - and _ in base64url
      final data = '{"key":"value with special chars +/="}';
      final encoded = base64Url.encode(utf8.encode(data));
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result['key'], 'value with special chars +/=');
    });

    test('throws for invalid base64', () {
      expect(
        () => ReceiptFormatHelper.decodeJWTPart('!!!invalid!!!'),
        throwsA(anything),
      );
    });

    test('throws for valid base64 but invalid JSON', () {
      final encoded = base64Url.encode(utf8.encode('not json'));
      expect(
        () => ReceiptFormatHelper.decodeJWTPart(encoded),
        throwsA(anything),
      );
    });

    test('decodes empty JSON object', () {
      final encoded = base64Url.encode(utf8.encode('{}'));
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result, isEmpty);
    });

    test('decodes nested JSON', () {
      final payload = {'data': {'nested': true, 'count': 42}};
      final encoded = base64Url.encode(utf8.encode(json.encode(payload)));
      final result = ReceiptFormatHelper.decodeJWTPart(encoded);
      expect(result['data'], isA<Map>());
      expect(result['data']['nested'], isTrue);
    });
  });

  group('ReceiptFormatHelper.detectIOSEnvironment', () {
    test('returns sandbox for TestFlight installer store', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.testflight',
          appName: 'MyApp',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when installerStore is null', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: null,
          appName: 'MyApp',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when appName contains testflight (case-insensitive)', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.AppStore',
          appName: 'MyApp TestFlight Build',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when appName contains TESTFLIGHT (uppercase)', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.AppStore',
          appName: 'TESTFLIGHT APP',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when buildSignature is non-empty', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.AppStore',
          appName: 'MyApp',
          buildSignature: 'some-signature',
        ),
        'sandbox',
      );
    });

    test('returns production for App Store with no test indicators', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.AppStore',
          appName: 'MyApp',
          buildSignature: '',
        ),
        'production',
      );
    });

    test('returns production when all conditions are false', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.AppStore',
          appName: 'Picnic',
          buildSignature: '',
        ),
        'production',
      );
    });
  });

  group('ReceiptFormatHelper.detectAndroidEnvironment', () {
    test('returns production for Google Play Store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.android.vending',
        ),
        'production',
      );
    });

    test('returns sandbox for null installer store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: null,
        ),
        'sandbox',
      );
    });

    test('returns sandbox for Samsung store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.sec.android.app.samsungapps',
        ),
        'sandbox',
      );
    });

    test('returns sandbox for sideloaded apps (empty string)', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox for unknown store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.amazon.venezia',
        ),
        'sandbox',
      );
    });
  });

  group('ReceiptFormatHelper.buildIOSRequestBody', () {
    test('builds correct request body with StoreKit2 format', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'eyJhbGc.payload.sig',
        productId: 'com.app.coins100',
        userId: 'user-123',
        environment: 'production',
        receiptFormat: 'StoreKit2 JWT',
      );

      expect(body['receipt'], 'eyJhbGc.payload.sig');
      expect(body['platform'], 'ios');
      expect(body['productId'], 'com.app.coins100');
      expect(body['user_id'], 'user-123');
      expect(body['environment'], 'production');
      expect(body['format'], 'storekit2_jwt');
    });

    test('builds correct request body with legacy format', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'MIITbase64receipt',
        productId: 'com.app.premium',
        userId: 'user-456',
        environment: 'sandbox',
        receiptFormat: 'StoreKit1 Base64',
      );

      expect(body['platform'], 'ios');
      expect(body['format'], 'legacy');
      expect(body['environment'], 'sandbox');
    });

    test('uses legacy format for Unknown receipt format', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'unknown-data',
        productId: 'prod',
        userId: 'usr',
        environment: 'sandbox',
        receiptFormat: 'Unknown',
      );

      expect(body['format'], 'legacy');
    });

    test('uses legacy format for JWT Custom receipt format', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'header.payload.signature',
        productId: 'prod',
        userId: 'usr',
        environment: 'production',
        receiptFormat: 'JWT Custom',
      );

      expect(body['format'], 'legacy');
    });

    test('includes all required keys', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'e',
        receiptFormat: 'f',
      );

      expect(body.containsKey('receipt'), isTrue);
      expect(body.containsKey('platform'), isTrue);
      expect(body.containsKey('productId'), isTrue);
      expect(body.containsKey('user_id'), isTrue);
      expect(body.containsKey('environment'), isTrue);
      expect(body.containsKey('format'), isTrue);
      expect(body.containsKey('parser_capabilities'), isTrue);
      expect(body.length, 7);
    });

    test('declares the revenue parser capability, and omits an absent currency', () {
      // 서버는 이 선언을 보고 응답에 currency/value 를 넣을지 정한다.
      // build number 로는 알 수 없다 — OTA 는 build number 를 바꾸지 않는다.
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'e',
        receiptFormat: 'f',
      );
      expect(body['parser_capabilities'], <String>['purchase_revenue_v1']);
      expect(body.containsKey('client_observed_currency'), isFalse);
    });

    test('carries the observed storefront currency when there is one', () {
      final body = ReceiptFormatHelper.buildIOSRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'e',
        receiptFormat: 'f',
        clientObservedCurrency: 'JPY',
      );
      expect(body['client_observed_currency'], 'JPY');
    });
  });

  group('ReceiptFormatHelper.buildAndroidRequestBody', () {
    test('builds correct request body', () {
      final body = ReceiptFormatHelper.buildAndroidRequestBody(
        receipt: '{"orderId":"GPA.123"}',
        productId: 'com.app.coins100',
        userId: 'user-789',
        environment: 'production',
        clientTraceId: 'trace-abc-123',
      );

      expect(body['receipt'], '{"orderId":"GPA.123"}');
      expect(body['platform'], 'android');
      expect(body['productId'], 'com.app.coins100');
      expect(body['user_id'], 'user-789');
      expect(body['environment'], 'production');
      expect(body['format'], 'google_play');
      expect(body['client_trace_id'], 'trace-abc-123');
    });

    test('always uses google_play format', () {
      final body = ReceiptFormatHelper.buildAndroidRequestBody(
        receipt: 'receipt',
        productId: 'prod',
        userId: 'usr',
        environment: 'sandbox',
        clientTraceId: 'trace-1',
      );

      expect(body['format'], 'google_play');
    });

    test('includes all required keys', () {
      final body = ReceiptFormatHelper.buildAndroidRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'e',
        clientTraceId: 'c',
      );

      expect(body.containsKey('receipt'), isTrue);
      expect(body.containsKey('platform'), isTrue);
      expect(body.containsKey('productId'), isTrue);
      expect(body.containsKey('user_id'), isTrue);
      expect(body.containsKey('environment'), isTrue);
      expect(body.containsKey('format'), isTrue);
      expect(body.containsKey('client_trace_id'), isTrue);
      expect(body.containsKey('parser_capabilities'), isTrue);
      expect(body.length, 8);
    });

    test('declares the revenue parser capability and the observed currency', () {
      final body = ReceiptFormatHelper.buildAndroidRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'e',
        clientTraceId: 'c',
        clientObservedCurrency: 'KRW',
      );
      expect(body['parser_capabilities'], <String>['purchase_revenue_v1']);
      // Google 은 provider 응답에 통화 필드가 없다. 이 값이 서버의 마지막
      // 폴백이라 Android 경로에서 특히 중요하다.
      expect(body['client_observed_currency'], 'KRW');
    });

    test('preserves sandbox environment', () {
      final body = ReceiptFormatHelper.buildAndroidRequestBody(
        receipt: 'r',
        productId: 'p',
        userId: 'u',
        environment: 'sandbox',
        clientTraceId: 'c',
      );

      expect(body['environment'], 'sandbox');
    });
  });

  group('ReceiptFormatHelper.isTimeoutError', () {
    test('returns true for TimeoutException', () {
      final exception = TimeoutException('Timed out');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isTrue);
    });

    test('returns true for exception containing "time" in message', () {
      final exception = Exception('Connection timed out');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isTrue);
    });

    test('returns true for exception with "timeout" in message', () {
      final exception = Exception('Request timeout');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isTrue);
    });

    test('returns true for exception with "TIME" in message (case-insensitive)', () {
      final exception = Exception('TIMEOUT ERROR');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isTrue);
    });

    test('returns false for null exception', () {
      expect(ReceiptFormatHelper.isTimeoutError(null), isFalse);
    });

    test('returns false for non-timeout exception', () {
      final exception = Exception('Network error');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isFalse);
    });

    test('returns false for generic exception', () {
      final exception = Exception('Something went wrong');
      expect(ReceiptFormatHelper.isTimeoutError(exception), isFalse);
    });

    test('returns true for TimeoutException with null message', () {
      final exception = TimeoutException(null);
      expect(ReceiptFormatHelper.isTimeoutError(exception), isTrue);
    });
  });

  group('ReceiptFormatHelper.calculateRetryDelay', () {
    test('returns correct delay for attempt 1 with base 2', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 1,
        baseRetryDelaySeconds: 2,
      );
      expect(delay, const Duration(seconds: 2));
    });

    test('returns correct delay for attempt 2 with base 2', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 2,
        baseRetryDelaySeconds: 2,
      );
      expect(delay, const Duration(seconds: 4));
    });

    test('returns correct delay for attempt 3 with base 2', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 3,
        baseRetryDelaySeconds: 2,
      );
      expect(delay, const Duration(seconds: 6));
    });

    test('returns correct delay for attempt 1 with base 5', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 1,
        baseRetryDelaySeconds: 5,
      );
      expect(delay, const Duration(seconds: 5));
    });

    test('returns zero delay for attempt 0', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 0,
        baseRetryDelaySeconds: 2,
      );
      expect(delay, Duration.zero);
    });

    test('returns zero delay for base 0', () {
      final delay = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 3,
        baseRetryDelaySeconds: 0,
      );
      expect(delay, Duration.zero);
    });

    test('scales linearly with attempt number', () {
      final delay1 = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 1,
        baseRetryDelaySeconds: 2,
      );
      final delay3 = ReceiptFormatHelper.calculateRetryDelay(
        attempt: 3,
        baseRetryDelaySeconds: 2,
      );
      expect(delay3.inSeconds, delay1.inSeconds * 3);
    });
  });
}
