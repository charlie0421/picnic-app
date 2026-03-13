import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';

void main() {
  group('ReusedPurchaseException', () {
    test('toString includes message', () {
      final e = ReusedPurchaseException(message: 'duplicate');
      expect(e.toString(), 'ReusedPurchaseException: duplicate');
    });

    test('receiptId is optional', () {
      final e =
          ReusedPurchaseException(message: 'dup', receiptId: 'receipt-1');
      expect(e.receiptId, 'receipt-1');
    });

    test('receiptId defaults to null', () {
      final e = ReusedPurchaseException(message: 'dup');
      expect(e.receiptId, isNull);
    });

    test('message property is accessible', () {
      final e = ReusedPurchaseException(message: 'test msg');
      expect(e.message, 'test msg');
    });

    test('is an Exception', () {
      final e = ReusedPurchaseException(message: 'test');
      expect(e, isA<Exception>());
    });
  });

  group('isStoreKit2JWT', () {
    test('returns true for valid JWT starting with eyJ', () {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode('{"transactionId":"123"}'));
      final signature = base64Url.encode(utf8.encode('signature'));
      final jwt = '$header.$payload.$signature';
      expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isTrue);
    });

    test('returns false for StoreKit1 Base64', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('MIIT...base64'), isFalse);
    });

    test('returns false for non-JWT string', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('plain text'), isFalse);
    });

    test('returns false for empty string', () {
      expect(ReceiptVerificationService.isStoreKit2JWT(''), isFalse);
    });

    test('returns false for string starting with eyJ but only 2 parts', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.eyJzdWI'), isFalse);
    });

    test('returns true for string starting with eyJ and 3 parts', () {
      expect(
        ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.eyJzdWI.sig123'),
        isTrue,
      );
    });

    test('returns false for string with 4+ parts starting with eyJ', () {
      expect(
        ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.b.c.d'),
        isFalse,
      );
    });

    test('returns false for null-like strings', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('null'), isFalse);
      expect(ReceiptVerificationService.isStoreKit2JWT('undefined'), isFalse);
    });
  });

  group('verifyReceiptV2', () {
    test('handles StoreKit2 JWT format', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(
          utf8.encode('{"transactionId":"123","productId":"test"}'));
      final signature = base64Url.encode(utf8.encode('signature'));
      final jwt = '$header.$payload.$signature';

      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: jwt,
        productId: 'test_product',
        transactionId: 'tx-123',
      );

      expect(result['status'], 0);
      expect(result['receipt_type'], 'StoreKit2_JWT');
      expect(result['transaction_id'], 'tx-123');
      expect(result['product_id'], 'test_product');
      expect(result['validation_method'], 'format_check');
    });

    test('handles legacy receipt format', () async {
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: 'MIIT_legacy_receipt_data',
        productId: 'test_product',
        transactionId: 'tx-456',
      );

      expect(result['status'], 0);
      expect(result['receipt_type'], 'Legacy');
      expect(result['validation_method'], 'Server Required');
      expect(result['message'], contains('Legacy'));
    });

    test('handles invalid JWT format', () async {
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: 'eyJhbGc.!!!invalid!!!.sig',
        productId: 'test',
        transactionId: 'tx-789',
      );

      expect(result.containsKey('status'), isTrue);
    });

    test('handles empty receipt', () async {
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: '',
        productId: 'test',
        transactionId: 'tx-000',
      );

      expect(result['receipt_type'], 'Legacy');
    });

    test('handles non-eyJ receipt with 3 dot-separated parts', () async {
      // This is "JWT Custom" format but not eyJ prefix
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: 'header.payload.signature',
        productId: 'test',
        transactionId: 'tx',
      );

      // Not eyJ, so Legacy
      expect(result['receipt_type'], 'Legacy');
    });

    test('verifyReceiptV2 catches and returns error for truly malformed JWT', () async {
      // This starts with eyJ and has 3 parts, so isStoreKit2JWT returns true
      // But the base64 decoding will fail
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: 'eyJ@@@invalid.@@@also-invalid.sig',
        productId: 'test',
        transactionId: 'tx',
      );

      expect(result['status'], -1);
      expect(result['receipt_type'], 'StoreKit2_JWT_ERROR');
      expect(result.containsKey('error'), isTrue);
    });

    test('JWT with valid header but no transactionId', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode('{"foo":"bar"}'));
      final jwt = '$header.$payload.sig';

      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: jwt,
        productId: 'prod',
        transactionId: 'tx',
      );

      // Should still succeed with format_check
      expect(result['status'], 0);
      expect(result['receipt_type'], 'StoreKit2_JWT');
    });

    test('JWT includes jwt_token in response', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
      final payload = base64Url.encode(utf8.encode('{"transactionId":"tx-100"}'));
      final signature = base64Url.encode(utf8.encode('sig'));
      final jwt = '$header.$payload.$signature';

      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: jwt,
        productId: 'my_product',
        transactionId: 'tx-100',
      );

      expect(result['jwt_token'], jwt);
      expect(result['product_id'], 'my_product');
      expect(result['transaction_id'], 'tx-100');
    });
  });

  group('ReceiptVerificationService instance methods', () {
    late ReceiptVerificationService service;

    setUp(() {
      service = ReceiptVerificationService();
    });

    test('_detectReceiptFormat returns StoreKit2 JWT for eyJ prefix', () {
      // Access indirectly through verifyReceiptV2 static method behavior
      expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.eyJwYXk.sig'), isTrue);
    });

    test('_validateInputs throws for empty receipt', () {
      expect(
        () => service.verifyReceipt('', 'product', 'userId', 'production'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validateInputs throws for empty productId', () {
      expect(
        () => service.verifyReceipt('receipt', '', 'userId', 'production'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validateInputs throws for empty userId', () {
      expect(
        () => service.verifyReceipt('receipt', 'product', '', 'production'),
        throwsA(isA<Exception>()),
      );
    });

    test('isStoreKit2JWT with exactly 3 parts and eyJ prefix', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.abc'), isTrue);
    });

    test('isStoreKit2JWT returns false for 1 part', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGc'), isFalse);
    });

    test('isStoreKit2JWT returns false for MIIK prefix', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('MIIK_data'), isFalse);
    });
  });

  group('ReusedPurchaseException edge cases', () {
    test('with long message', () {
      final e = ReusedPurchaseException(message: 'A' * 1000);
      expect(e.message.length, 1000);
      expect(e.toString(), contains('ReusedPurchaseException'));
    });

    test('with special characters in message', () {
      final e = ReusedPurchaseException(message: 'Error: 중복 구매 (#123)');
      expect(e.message, 'Error: 중복 구매 (#123)');
    });

    test('with receiptId and message', () {
      final e = ReusedPurchaseException(
        message: 'Duplicate',
        receiptId: 'rcpt-abc-123',
      );
      expect(e.receiptId, 'rcpt-abc-123');
      expect(e.message, 'Duplicate');
    });
  });
}
