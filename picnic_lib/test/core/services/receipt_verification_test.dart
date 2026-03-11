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
  });

  group('isStoreKit2JWT', () {
    test('returns true for valid JWT starting with eyJ', () {
      // Create a fake JWT with 3 parts
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
    });

    test('handles invalid JWT format', () async {
      // JWT with 3 parts but invalid base64 in payload
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: 'eyJhbGc.!!!invalid!!!.sig',
        productId: 'test',
        transactionId: 'tx-789',
      );

      // Should handle error gracefully
      expect(result.containsKey('status'), isTrue);
    });

    test('handles empty receipt', () async {
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: '',
        productId: 'test',
        transactionId: 'tx-000',
      );

      // Empty string doesn't start with eyJ, so treated as Legacy
      expect(result['receipt_type'], 'Legacy');
    });
  });
}
