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
      // eyJ prefix alone triggers StoreKit2 JWT detection
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
      // Even though it has 3 parts, eyJ prefix should match first
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
          .replaceAll('=', ''); // Remove padding to simulate URL-safe encoding
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
}
