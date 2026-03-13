import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_format_helper.dart';

void main() {
  group('ReceiptFormatHelper.isStoreKit2JWT', () {
    test('returns true for valid StoreKit2 JWT (eyJ prefix + 3 parts)', () {
      expect(
        ReceiptFormatHelper.isStoreKit2JWT('eyJhbGciOiJFUzI1NiJ9.payload.sig'),
        isTrue,
      );
    });

    test('returns false for eyJ prefix with only 2 parts', () {
      expect(
        ReceiptFormatHelper.isStoreKit2JWT('eyJhbGc.payload'),
        isFalse,
      );
    });

    test('returns false for eyJ prefix with 4 parts', () {
      expect(
        ReceiptFormatHelper.isStoreKit2JWT('eyJhbGc.a.b.c'),
        isFalse,
      );
    });

    test('returns false for non-eyJ 3-part string', () {
      expect(
        ReceiptFormatHelper.isStoreKit2JWT('abc.def.ghi'),
        isFalse,
      );
    });

    test('returns false for empty string', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT(''), isFalse);
    });

    test('returns false for StoreKit1 Base64', () {
      expect(ReceiptFormatHelper.isStoreKit2JWT('MIIT12345'), isFalse);
    });

    test('returns true for eyJ with exactly 3 dot-separated parts', () {
      expect(
        ReceiptFormatHelper.isStoreKit2JWT('eyJtest.payload.sig'),
        isTrue,
      );
    });
  });

  group('ReceiptFormatHelper.decodeJWTPart', () {
    test('decodes a standard base64url-encoded JSON payload', () {
      final payload = base64Url.encode(utf8.encode('{"key":"value"}'));
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result, {'key': 'value'});
    });

    test('decodes payload without padding', () {
      // Remove trailing '=' from base64url
      final payload =
          base64Url.encode(utf8.encode('{"a":"b"}')).replaceAll('=', '');
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result, {'a': 'b'});
    });

    test('decodes payload with numeric values', () {
      final payload = base64Url.encode(utf8.encode('{"num":42,"flag":true}'));
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result['num'], 42);
      expect(result['flag'], true);
    });

    test('decodes payload with nested object', () {
      final payload = base64Url.encode(
        utf8.encode('{"outer":{"inner":"deep"}}'),
      );
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result['outer'], {'inner': 'deep'});
    });

    test('decodes payload with URL-safe characters (- and _)', () {
      // Manually create base64url with - and _
      final payload = base64Url
          .encode(utf8.encode('{"transactionId":"tx-123_456"}'))
          .replaceAll('=', '');
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result['transactionId'], 'tx-123_456');
    });

    test('decodes a JWT header', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256","typ":"JWT"}'));
      final result = ReceiptFormatHelper.decodeJWTPart(header);
      expect(result['alg'], 'ES256');
      expect(result['typ'], 'JWT');
    });

    test('decodes payload with empty object', () {
      final payload = base64Url.encode(utf8.encode('{}'));
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result, isEmpty);
    });

    test('throws on invalid base64', () {
      expect(
        () => ReceiptFormatHelper.decodeJWTPart('!!!invalid!!!'),
        throwsA(anything),
      );
    });

    test('throws on valid base64 but invalid JSON', () {
      final payload = base64Url.encode(utf8.encode('not json'));
      expect(
        () => ReceiptFormatHelper.decodeJWTPart(payload),
        throwsA(anything),
      );
    });

    test('decodes payload with array value', () {
      final payload = base64Url.encode(utf8.encode('{"items":[1,2,3]}'));
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result['items'], [1, 2, 3]);
    });

    test('decodes payload with unicode characters', () {
      final payload = base64Url.encode(utf8.encode('{"name":"테스트"}'));
      final result = ReceiptFormatHelper.decodeJWTPart(payload);
      expect(result['name'], '테스트');
    });
  });

  group('ReceiptFormatHelper.detectIOSEnvironment', () {
    test('returns sandbox for TestFlight installer', () {
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

    test('returns sandbox when appName contains testflight', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.appstore',
          appName: 'MyApp TestFlight',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when appName contains testflight case-insensitive', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.appstore',
          appName: 'MyApp TESTFLIGHT Build',
          buildSignature: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox when buildSignature is non-empty', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.appstore',
          appName: 'MyApp',
          buildSignature: 'some-signature',
        ),
        'sandbox',
      );
    });

    test('returns production for App Store with no test indicators', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.appstore',
          appName: 'MyApp',
          buildSignature: '',
        ),
        'production',
      );
    });

    test('returns production for valid store and clean app name', () {
      expect(
        ReceiptFormatHelper.detectIOSEnvironment(
          installerStore: 'com.apple.appstore',
          appName: 'Picnic',
          buildSignature: '',
        ),
        'production',
      );
    });
  });

  group('ReceiptFormatHelper.detectAndroidEnvironment', () {
    test('returns production for Google Play store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.android.vending',
        ),
        'production',
      );
    });

    test('returns sandbox for null installer', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: null,
        ),
        'sandbox',
      );
    });

    test('returns sandbox for sideloaded app', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.some.other.store',
        ),
        'sandbox',
      );
    });

    test('returns sandbox for empty string installer', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: '',
        ),
        'sandbox',
      );
    });

    test('returns sandbox for Samsung Galaxy Store', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.sec.android.app.samsungapps',
        ),
        'sandbox',
      );
    });

    test('returns sandbox for Amazon Appstore', () {
      expect(
        ReceiptFormatHelper.detectAndroidEnvironment(
          installerStore: 'com.amazon.venezia',
        ),
        'sandbox',
      );
    });
  });
}
