import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';

void main() {
  group('ReusedPurchaseException', () {
    test('creates with message', () {
      final exception = ReusedPurchaseException(message: 'duplicate receipt');
      expect(exception.message, 'duplicate receipt');
      expect(exception.receiptId, isNull);
    });

    test('creates with message and receiptId', () {
      final exception = ReusedPurchaseException(
        message: 'duplicate',
        receiptId: 'abc123',
      );
      expect(exception.message, 'duplicate');
      expect(exception.receiptId, 'abc123');
    });

    test('toString includes message', () {
      final exception = ReusedPurchaseException(message: 'test error');
      final str = exception.toString();
      expect(str, contains('ReusedPurchaseException'));
      expect(str, contains('test error'));
    });

    test('implements Exception', () {
      final exception = ReusedPurchaseException(message: 'test');
      expect(exception, isA<Exception>());
    });
  });

  group('ReceiptVerificationService.isStoreKit2JWT', () {
    test('returns true for valid StoreKit2 JWT', () {
      // A valid JWT format starts with eyJ and has 3 parts
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJ0ZXN0IjoiZGF0YSJ9.signature';
      expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isTrue);
    });

    test('returns false for StoreKit1 Base64', () {
      const receipt = 'MIIT12345abcdef';
      expect(ReceiptVerificationService.isStoreKit2JWT(receipt), isFalse);
    });

    test('returns false for random string', () {
      const receipt = 'some_random_receipt_data';
      expect(ReceiptVerificationService.isStoreKit2JWT(receipt), isFalse);
    });

    test('returns false for empty string', () {
      expect(ReceiptVerificationService.isStoreKit2JWT(''), isFalse);
    });

    test('returns false for JWT starting with eyJ but only 2 parts', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.payload';
      expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isFalse);
    });

    test('returns false for non-eyJ 3-part string', () {
      const data = 'abc.def.ghi';
      expect(ReceiptVerificationService.isStoreKit2JWT(data), isFalse);
    });

    test('returns true for eyJ with exactly 3 parts', () {
      const jwt = 'eyJtest.payload.sig';
      expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isTrue);
    });
  });

  group('ReceiptVerificationService.verifyReceiptV2', () {
    test('handles StoreKit2 JWT format', () async {
      // Create a valid-looking JWT
      const jwt = 'eyJhbGciOiJFUzI1NiJ9.eyJ0cmFuc2FjdGlvbklkIjoiMTIzIn0.sig';
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: jwt,
        productId: 'com.test.product',
        transactionId: '123',
      );
      expect(result, isA<Map<String, dynamic>>());
      expect(result['receipt_type'], contains('StoreKit2'));
    });

    test('handles legacy receipt format', () async {
      const receipt = 'MIIT_legacy_receipt_data';
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: receipt,
        productId: 'com.test.product',
        transactionId: '456',
      );
      expect(result, isA<Map<String, dynamic>>());
      expect(result['receipt_type'], 'Legacy');
      expect(result['validation_method'], 'Server Required');
    });

    test('handles invalid receipt data', () async {
      const receipt = 'invalid_data';
      final result = await ReceiptVerificationService.verifyReceiptV2(
        receiptData: receipt,
        productId: 'com.test.product',
        transactionId: '789',
      );
      expect(result, isA<Map<String, dynamic>>());
      // Should return Legacy type for non-JWT receipts
      expect(result['receipt_type'], 'Legacy');
    });
  });

  group('ReceiptVerificationService receipt format detection', () {
    test('detects StoreKit2 JWT correctly', () {
      final service = ReceiptVerificationService();
      // The private method _detectReceiptFormat is tested indirectly
      // through isStoreKit2JWT
      expect(ReceiptVerificationService.isStoreKit2JWT(
        'eyJhbGciOiJFUzI1NiJ9.eyJ0ZXN0IjoiMSJ9.sig',
      ), isTrue);
    });

    test('detects MIIT format (StoreKit1)', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('MIIT12345'), isFalse);
    });

    test('detects MIIK format (StoreKit1)', () {
      expect(ReceiptVerificationService.isStoreKit2JWT('MIIK12345'), isFalse);
    });
  });
}
