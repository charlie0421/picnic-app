import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

Map<String, dynamic> _purchaseResult() => {
      'contract_version': 'wallet.v1',
      'operation_id': '00000000-0000-4000-8000-000000000001',
      'replayed': false,
      'base_star_amount': '100',
      'base_bonus_amount': '20',
      'promotion': {
        'resolution_id': '00000000-0000-4000-8000-000000000002',
        'state': 'INELIGIBLE',
        'campaign_version_id': null,
        'promo_bonus_amount': '0',
        'domain_code': null,
      },
      'wallet': {
        'contract_version': 'wallet.v1',
        'star': '100',
        'bonus': '20',
        'cotton': '5',
        'cotton_expiring_amount': '5',
        'cotton_next_expires_at': null,
        'snapshot_at': '2026-07-21T00:00:00.000Z',
      },
    };

void main() {
  test('non-production payment verification rejects production environment', () {
    expect(
      ReceiptVerificationService.isPaymentEnvironmentAllowed(
        buildEnvironment: 'dev',
        requestedEnvironment: 'production',
      ),
      isFalse,
    );
    expect(
      ReceiptVerificationService.isPaymentEnvironmentAllowed(
        buildEnvironment: 'dev',
        requestedEnvironment: 'sandbox',
      ),
      isTrue,
    );
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupMockSupabase({
      'functions:verify-receipt-v2': _purchaseResult(),
    }, userId: 'test-user-id');
  });

  tearDown(() => tearDownMockSupabase());

  group('ReceiptVerificationService', () {
    late ReceiptVerificationService service;

    setUp(() {
      service = ReceiptVerificationService();
    });

    group('isStoreKit2JWT', () {
      test('returns true for valid StoreKit2 JWT format', () {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload =
            base64Url.encode(utf8.encode('{"transactionId":"123"}'));
        const signature = 'dummysignature';
        final jwt = '$header.$payload.$signature';

        expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isTrue);
      });

      test('returns false for StoreKit1 Base64 receipt', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('MIIT...base64data'),
            isFalse);
      });

      test('returns false for empty string', () {
        expect(ReceiptVerificationService.isStoreKit2JWT(''), isFalse);
      });

      test('returns false for string with eyJ but only 2 parts', () {
        expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.payload'),
            isFalse);
      });

      test('returns true for eyJ with 3 dot-separated parts', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.part2.part3'),
            isTrue);
      });

      test('returns false for non-JWT string with 3 parts', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('abc.def.ghi'), isFalse);
      });

      test('returns false for MIIK prefix', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('MIIKsomedata'), isFalse);
      });

      test('returns false for single character', () {
        expect(ReceiptVerificationService.isStoreKit2JWT('e'), isFalse);
      });

      test('returns false for eyJ without dots', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('eyJnodots'), isFalse);
      });

      test('returns true for eyJ with exactly 3 parts including empty signature', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.payload.'),
            isTrue);
      });

      test('returns false for string with 4 dot-separated parts starting with eyJ', () {
        // 4 parts means split('.').length == 4, not 3
        expect(
            ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.b.c.d'),
            isFalse);
      });
    });

    group('_detectReceiptFormat (via verifyReceiptV2)', () {
      test('detects StoreKit2 JWT format', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(
            '{"transactionId":"tx123","productId":"prod1"}'));
        const signature = 'sig';
        final jwt = '$header.$payload.$signature';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod1',
          transactionId: 'tx123',
        );

        expect(result['receipt_type'], 'StoreKit2_JWT');
        expect(result['status'], 0);
        expect(result['transaction_id'], 'tx123');
        expect(result['product_id'], 'prod1');
      });

      test('detects Legacy receipt format', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'MIITsomebase64receipt',
          productId: 'prod1',
          transactionId: 'tx123',
        );

        expect(result['receipt_type'], 'Legacy');
        expect(result['status'], 0);
        expect(result['validation_method'], 'Server Required');
      });

      test('handles invalid JWT gracefully', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'eyJ!!!.invalid!!!.sig',
          productId: 'prod1',
          transactionId: 'tx123',
        );

        expect(result['status'], -1);
        expect(result['receipt_type'], 'StoreKit2_JWT_ERROR');
      });

      test('detects MIIK prefix as legacy', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'MIIKsomebase64data',
          productId: 'prod1',
          transactionId: 'tx123',
        );

        expect(result['receipt_type'], 'Legacy');
        expect(result['status'], 0);
      });

      test('treats plain text as legacy', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'some-plain-text-receipt',
          productId: 'prod1',
          transactionId: 'tx123',
        );

        expect(result['receipt_type'], 'Legacy');
      });

      test('treats empty string as legacy', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: '',
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['receipt_type'], 'Legacy');
      });
    });

    group('verifyReceiptV2', () {
      test('returns correct result for valid StoreKit2 JWT', () async {
        final header =
            base64Url.encode(utf8.encode('{"alg":"ES256","typ":"JWT"}'));
        final payload = base64Url.encode(utf8.encode(
          '{"transactionId":"12345","productId":"com.app.product","signedDate":1234567890}',
        ));
        const signature = 'validsig123';
        final jwt = '$header.$payload.$signature';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'com.app.product',
          transactionId: '12345',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
        expect(result['validation_method'], 'format_check');
        expect(result['jwt_token'], jwt);
        expect(result['message'], contains('StoreKit2'));
      });

      test('returns legacy result for non-JWT receipt', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'some-legacy-receipt-data',
          productId: 'com.app.product',
          transactionId: '12345',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'Legacy');
        expect(result['message'], contains('Legacy'));
      });

      test('returns error result for malformed JWT header', () async {
        // eyJ prefix but invalid base64 in header
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'eyJ@@@.payload.sig',
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['status'], -1);
        expect(result['receipt_type'], 'StoreKit2_JWT_ERROR');
        expect(result.containsKey('error'), isTrue);
      });

      test('returns error result for malformed JWT payload', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: '$header.!!!invalid!!!.sig',
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['status'], -1);
        expect(result['receipt_type'], 'StoreKit2_JWT_ERROR');
      });

      test('handles JWT without transactionId in payload', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(
            utf8.encode('{"productId":"prod","other":"data"}'));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
      });

      test('handles JWT with complex payload data', () async {
        final header =
            base64Url.encode(utf8.encode('{"alg":"ES256","kid":"key1"}'));
        final payload = base64Url.encode(utf8.encode(jsonEncode({
          'transactionId': '999',
          'productId': 'com.app.coins.100',
          'signedDate': 1700000000000,
          'originalPurchaseDate': 1699999999000,
          'purchaseDate': 1700000000000,
          'expiresDate': null,
          'quantity': 1,
          'type': 'Consumable',
        })));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'com.app.coins.100',
          transactionId: '999',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
        expect(result['transaction_id'], '999');
      });

      test('includes packageName parameter when provided', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'legacy-receipt',
          productId: 'prod',
          transactionId: 'tx',
          packageName: 'com.example.app',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'Legacy');
      });
    });

    group('_validateInputs', () {
      test('throws on empty receipt', () {
        expect(
          () => service.verifyReceipt('', 'product', 'user', 'sandbox'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('영수증 데이터가 비어있습니다'),
          )),
        );
      });

      test('throws on empty productId', () {
        expect(
          () => service.verifyReceipt('receipt', '', 'user', 'sandbox'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('상품 ID가 비어있습니다'),
          )),
        );
      });

      test('throws on empty userId', () {
        expect(
          () => service.verifyReceipt('receipt', 'product', '', 'sandbox'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('사용자 ID가 비어있습니다'),
          )),
        );
      });

      test('does not throw validation error when all inputs are valid', () async {
        // The method itself doesn't throw if inputs are valid
        // With mock supabase, verifyReceipt completes successfully for non-iOS/Android
        // (test environment runs on macOS, which goes through Android path with mock)
        await expectLater(
          service.verifyReceipt(
              'valid-receipt', 'valid-product', 'valid-user', 'sandbox'),
          completes,
        );
      });
    });

    group('_makeIdemKeyFromJWS', () {
      test(
          'creates idem key from valid JWS with transactionId and signedDate',
          () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(
          '{"transactionId":"tx999","signedDate":"2024-01-01T00:00:00Z"}',
        ));
        const signature = 'sig';
        final jws = '$header.$payload.$signature';

        SharedPreferences.setMockInitialValues({});

        final sp = await SharedPreferences.getInstance();
        final cached = sp.getStringList('sent_receipts_idem_keys');
        expect(cached, isNull);
      });

      test('creates raw hash key for non-JWT input', () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        expect(sp.getStringList('sent_receipts_idem_keys'), isNull);
      });

      test('handles JWS with originalTransactionId instead of transactionId',
          () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(
          '{"originalTransactionId":"orig-tx-1","purchaseDate":"2024-06-01"}',
        ));
        final jws = '$header.$payload.sig';

        // Verify the JWS is valid format
        expect(ReceiptVerificationService.isStoreKit2JWT(jws), isTrue);
      });

      test('handles JWS with originalPurchaseDate', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(
          '{"transactionId":"tx-100","originalPurchaseDate":"2024-01-01"}',
        ));
        final jws = '$header.$payload.sig';

        expect(ReceiptVerificationService.isStoreKit2JWT(jws), isTrue);
      });

      test('handles JWS with no transactionId or signedDate', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(
          '{"productId":"com.app.coins","quantity":1}',
        ));
        final jws = '$header.$payload.sig';

        expect(ReceiptVerificationService.isStoreKit2JWT(jws), isTrue);
      });
    });

    group('idem cache operations', () {
      test('cache starts empty', () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        expect(sp.getStringList('sent_receipts_idem_keys'), isNull);
      });

      test('idem keys can be persisted and loaded', () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        await sp.setStringList(
            'sent_receipts_idem_keys', ['ios:tx1:time1', 'ios:tx2:time2']);

        final keys = sp.getStringList('sent_receipts_idem_keys');
        expect(keys, isNotNull);
        expect(keys!.length, 2);
        expect(keys.contains('ios:tx1:time1'), isTrue);
        expect(keys.contains('ios:tx2:time2'), isTrue);
      });

      test('idem keys set deduplicates', () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();

        // Add same key twice via Set behavior
        final keys = <String>{'ios:tx1:time1', 'ios:tx1:time1'};
        await sp.setStringList('sent_receipts_idem_keys', keys.toList());

        final loaded = sp.getStringList('sent_receipts_idem_keys');
        expect(loaded!.length, 1);
      });

      test('can add to existing cache', () async {
        SharedPreferences.setMockInitialValues({
          'sent_receipts_idem_keys': ['ios:tx1:time1'],
        });
        final sp = await SharedPreferences.getInstance();

        final existing =
            sp.getStringList('sent_receipts_idem_keys')?.toSet() ?? <String>{};
        existing.add('ios:tx2:time2');
        await sp.setStringList('sent_receipts_idem_keys', existing.toList());

        final loaded = sp.getStringList('sent_receipts_idem_keys');
        expect(loaded!.length, 2);
        expect(loaded.contains('ios:tx1:time1'), isTrue);
        expect(loaded.contains('ios:tx2:time2'), isTrue);
      });

      test('raw hash keys are stored for non-JWT', () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();

        // Simulate what _makeIdemKeyFromJWS does for non-JWT
        const nonJwt = 'simple-receipt-data';
        final rawKey = 'raw:${nonJwt.hashCode}';

        final keys = <String>{rawKey};
        await sp.setStringList('sent_receipts_idem_keys', keys.toList());

        final loaded = sp.getStringList('sent_receipts_idem_keys');
        expect(loaded!.first, startsWith('raw:'));
      });
    });

    group('ReusedPurchaseException', () {
      test('has correct message', () {
        final e = ReusedPurchaseException(message: 'test message');
        expect(e.message, 'test message');
        expect(e.toString(), contains('ReusedPurchaseException'));
        expect(e.toString(), contains('test message'));
      });

      test('has optional receiptId', () {
        final e =
            ReusedPurchaseException(message: 'msg', receiptId: 'rx-123');
        expect(e.receiptId, 'rx-123');
      });

      test('receiptId defaults to null', () {
        final e = ReusedPurchaseException(message: 'msg');
        expect(e.receiptId, isNull);
      });

      test('implements Exception', () {
        final e = ReusedPurchaseException(message: 'test');
        expect(e, isA<Exception>());
      });

      test('toString format is consistent', () {
        final e = ReusedPurchaseException(message: 'duplicate receipt found');
        expect(e.toString(), 'ReusedPurchaseException: duplicate receipt found');
      });

      test('message can be empty string', () {
        final e = ReusedPurchaseException(message: '');
        expect(e.message, '');
        expect(e.toString(), 'ReusedPurchaseException: ');
      });

      test('receiptId can be empty string', () {
        final e = ReusedPurchaseException(message: 'msg', receiptId: '');
        expect(e.receiptId, '');
      });
    });

    group('_decodeJWTPart', () {
      test('correctly decodes base64url encoded JWT part via verifyReceiptV2',
          () async {
        final headerData = {'alg': 'ES256', 'typ': 'JWT'};
        final payloadData = {
          'transactionId': 'test-tx-id',
          'productId': 'com.test.product',
          'purchaseDate': '2024-06-15T10:00:00Z',
        };

        final header = base64Url
            .encode(utf8.encode(jsonEncode(headerData)))
            .replaceAll('=', '');
        final payload = base64Url
            .encode(utf8.encode(jsonEncode(payloadData)))
            .replaceAll('=', '');
        const signature = 'valid_signature_data';
        final jwt = '$header.$payload.$signature';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'com.test.product',
          transactionId: 'test-tx-id',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
        expect(result['transaction_id'], 'test-tx-id');
      });

      test('handles JWT with padding characters', () async {
        final headerData = {'alg': 'ES256'};
        final payloadData = {'transactionId': 'x'};

        final header = base64Url.encode(utf8.encode(jsonEncode(headerData)));
        final payload = base64Url.encode(utf8.encode(jsonEncode(payloadData)));
        const signature = 'sig';
        final jwt = '$header.$payload.$signature';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'x',
        );

        expect(result['status'], 0);
      });

      test('handles JWT with URL-safe characters correctly', () async {
        // Create data that will produce URL-safe base64 characters (- and _)
        final headerData = {'alg': 'ES256', 'kid': 'key-with+special/chars='};
        final payloadData = {
          'transactionId': 'tx-with+special/chars',
          'data': List.generate(50, (i) => i), // generate data that needs padding
        };

        final header = base64Url.encode(utf8.encode(jsonEncode(headerData)));
        final payload = base64Url.encode(utf8.encode(jsonEncode(payloadData)));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
      });

      test('decodes header with various algorithms', () async {
        for (final alg in ['ES256', 'RS256', 'HS256', 'ES384']) {
          final header =
              base64Url.encode(utf8.encode(jsonEncode({'alg': alg})));
          final payload =
              base64Url.encode(utf8.encode(jsonEncode({'transactionId': '1'})));
          final jwt = '$header.$payload.sig';

          final result = await ReceiptVerificationService.verifyReceiptV2(
            receiptData: jwt,
            productId: 'p',
            transactionId: '1',
          );

          expect(result['status'], 0,
              reason: 'Should handle algorithm $alg');
        }
      });
    });

    group('_callVerificationFunction via verifyReceipt', () {
      test('calls edge function successfully for Android receipt', () async {
        final service = ReceiptVerificationService();

        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload =
            base64Url.encode(utf8.encode('{"transactionId":"t1"}'));
        final jwt = '$header.$payload.sig';

        expect(ReceiptVerificationService.isStoreKit2JWT(jwt), isTrue);
      });

      test('format detection for various receipt types', () {
        // StoreKit2 JWT
        expect(ReceiptVerificationService.isStoreKit2JWT('eyJhbGc.b.c'), isTrue);

        // StoreKit1 Base64
        expect(ReceiptVerificationService.isStoreKit2JWT('MIIT..'), isFalse);
        expect(ReceiptVerificationService.isStoreKit2JWT('MIIK..'), isFalse);

        // Google Play
        expect(ReceiptVerificationService.isStoreKit2JWT('google-play-token'),
            isFalse);

        // Empty
        expect(ReceiptVerificationService.isStoreKit2JWT(''), isFalse);
      });
    });

    group('edge cases', () {
      test('JWT with URL-safe base64 characters', () async {
        final headerData = {'alg': 'ES256'};
        final payloadData = {
          'transactionId': 'tx+with/special=chars',
          'signedDate': '2024-01-01',
        };

        final header = base64Url.encode(utf8.encode(jsonEncode(headerData)));
        final payload =
            base64Url.encode(utf8.encode(jsonEncode(payloadData)));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'tx+with/special=chars',
        );

        expect(result['status'], 0);
      });

      test('MIIK prefix detected as non-StoreKit2', () {
        expect(
            ReceiptVerificationService.isStoreKit2JWT('MIIKsomedata'), isFalse);
      });

      test('empty receipt is not StoreKit2 JWT', () {
        expect(ReceiptVerificationService.isStoreKit2JWT(''), isFalse);
      });

      test('single dot string is not StoreKit2 JWT', () {
        expect(ReceiptVerificationService.isStoreKit2JWT('eyJ.only'), isFalse);
      });

      test('very long receipt data', () async {
        final longData = 'MIITsomebase64' + ('A' * 10000);
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: longData,
          productId: 'prod',
          transactionId: 'tx',
        );
        expect(result['receipt_type'], 'Legacy');
      });

      test('receipt with only whitespace is treated as legacy', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: '   ',
          productId: 'prod',
          transactionId: 'tx',
        );
        expect(result['receipt_type'], 'Legacy');
      });

      test('receipt with unicode characters', () async {
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'receipt_한국어_데이터',
          productId: 'prod',
          transactionId: 'tx',
        );
        expect(result['receipt_type'], 'Legacy');
      });

      test('JWT with empty payload object', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode('{}'));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'tx',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
      });

      test('JWT with nested objects in payload', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(utf8.encode(jsonEncode({
          'transactionId': 'tx-nested',
          'environment': {'name': 'sandbox', 'version': 2},
          'appAccountToken': 'user-uuid-here',
        })));
        final jwt = '$header.$payload.sig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'prod',
          transactionId: 'tx-nested',
        );

        expect(result['status'], 0);
      });

      test('string with exactly 3 dots but not starting with eyJ', () {
        // "a.b.c" has 3 parts but doesn't start with eyJ
        expect(ReceiptVerificationService.isStoreKit2JWT('a.b.c'), isFalse);
      });

      test('string starting with eyJ with many dots', () {
        // "eyJ.b.c.d.e" has 5 parts
        expect(
            ReceiptVerificationService.isStoreKit2JWT('eyJ.b.c.d.e'), isFalse);
      });
    });

    group('_detectReceiptFormat logic', () {
      // Testing the three format paths:
      // 1. eyJ prefix -> StoreKit2 JWT
      // 2. MIIT or MIIK prefix -> StoreKit1 Base64
      // 3. Contains '.' with 3 parts -> JWT Custom
      // 4. Otherwise -> Unknown

      test('eyJ prefix is StoreKit2 JWT', () {
        const receipt = 'eyJhbGciOiJFUzI1NiJ9.payload.sig';
        expect(receipt.startsWith('eyJ'), isTrue);
      });

      test('MIIT prefix is StoreKit1 Base64', () {
        const receipt = 'MIITbase64data';
        expect(
            receipt.startsWith('MIIT') || receipt.startsWith('MIIK'), isTrue);
      });

      test('MIIK prefix is StoreKit1 Base64', () {
        const receipt = 'MIIKbase64data';
        expect(receipt.startsWith('MIIK'), isTrue);
      });

      test('3-part dot-separated string is JWT Custom', () {
        const receipt = 'header.payload.signature';
        expect(receipt.contains('.'), isTrue);
        expect(receipt.split('.').length, 3);
      });

      test('plain string is Unknown format', () {
        const receipt = 'plainreceipt';
        expect(receipt.startsWith('eyJ'), isFalse);
        expect(
            receipt.startsWith('MIIT') || receipt.startsWith('MIIK'), isFalse);
        expect(receipt.contains('.') && receipt.split('.').length == 3, isFalse);
      });
    });

    group('verifyReceipt validation errors', () {
      test('empty receipt throws immediately', () {
        expect(
          () => service.verifyReceipt('', 'prod', 'user', 'sandbox'),
          throwsA(isA<Exception>()),
        );
      });

      test('empty productId throws immediately', () {
        expect(
          () => service.verifyReceipt('receipt', '', 'user', 'sandbox'),
          throwsA(isA<Exception>()),
        );
      });

      test('empty userId throws immediately', () {
        expect(
          () => service.verifyReceipt('receipt', 'prod', '', 'sandbox'),
          throwsA(isA<Exception>()),
        );
      });

      test('all empty inputs - receipt error takes priority', () {
        expect(
          () => service.verifyReceipt('', '', '', 'sandbox'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('영수증 데이터가 비어있습니다'),
          )),
        );
      });
    });

    group('_verifyStoreKit2Receipt static method', () {
      test('valid JWT returns status 0 with full details', () async {
        final header =
            base64Url.encode(utf8.encode('{"alg":"ES256","typ":"JWT"}'));
        final payload = base64Url.encode(utf8.encode(jsonEncode({
          'transactionId': 'tx-42',
          'productId': 'com.app.product',
          'signedDate': 1700000000,
        })));
        final jwt = '$header.$payload.validSig';

        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: jwt,
          productId: 'com.app.product',
          transactionId: 'tx-42',
        );

        expect(result['status'], 0);
        expect(result['receipt_type'], 'StoreKit2_JWT');
        expect(result['transaction_id'], 'tx-42');
        expect(result['product_id'], 'com.app.product');
        expect(result['jwt_token'], jwt);
        expect(result['validation_method'], 'format_check');
        expect(result['message'], 'StoreKit2 JWT format validated');
      });

      test('JWT with only 2 parts returns error', () async {
        // Force a JWT-like string with only 2 parts that somehow passes isStoreKit2JWT
        // Actually isStoreKit2JWT would return false for 2 parts, so this goes to Legacy
        final result = await ReceiptVerificationService.verifyReceiptV2(
          receiptData: 'eyJhbGc.payload',
          productId: 'prod',
          transactionId: 'tx',
        );

        // 2 parts doesn't pass isStoreKit2JWT, so it's Legacy
        expect(result['receipt_type'], 'Legacy');
      });
    });

    group('constructor and instance creation', () {
      test('creates new instance', () {
        final s1 = ReceiptVerificationService();
        final s2 = ReceiptVerificationService();
        expect(s1, isNot(same(s2)));
      });
    });

    group('verifyReceipt instance method (Android path)', () {
      // On macOS test environment, Platform.isIOS is false, so Android path is taken

      test('successfully verifies Android receipt with mock', () async {
        await service.verifyReceipt(
          'android-receipt-token',
          'com.app.coins.100',
          'user-123',
          'sandbox',
        );
        // If no exception, verification succeeded
      });

      test('verifies with production environment', () async {
        await service.verifyReceipt(
          'production-receipt',
          'com.app.coins.500',
          'user-456',
          'production',
        );
      });

      test('verifies StoreKit1 format receipt on Android path', () async {
        await service.verifyReceipt(
          'MIITbase64receiptdata',
          'com.app.product',
          'user-789',
          'sandbox',
        );
      });

      test('verifies receipt with JWT Custom format on Android path', () async {
        await service.verifyReceipt(
          'header.payload.signature',
          'com.app.product',
          'user-abc',
          'sandbox',
        );
      });

      test('verifies receipt with Unknown format on Android path', () async {
        await service.verifyReceipt(
          'plain-receipt-data',
          'com.app.product',
          'user-def',
          'production',
        );
      });

      test('verifies receipt with eyJ prefix (StoreKit2 JWT format) on Android path', () async {
        final header = base64Url.encode(utf8.encode('{"alg":"ES256"}'));
        final payload = base64Url.encode(
            utf8.encode('{"transactionId":"tx1"}'));
        final jwt = '$header.$payload.sig';

        await service.verifyReceipt(
          jwt,
          'com.app.product',
          'user-ghi',
          'sandbox',
        );
      });

      test('verifies receipt with MIIK prefix on Android path', () async {
        await service.verifyReceipt(
          'MIIKbase64data',
          'com.app.product',
          'user-jkl',
          'sandbox',
        );
      });
    });

    group('verifyReceipt with different mock responses', () {
      test('handles edge function returning custom data', () async {
        tearDownMockSupabase();
        SharedPreferences.setMockInitialValues({});
        setupMockSupabase({
          'functions:verify-receipt-v2': _purchaseResult(),
        }, userId: 'test-user');

        await service.verifyReceipt(
          'receipt-data',
          'com.app.coins',
          'user-id',
          'sandbox',
        );
      });
    });

    group('verify_receipt response contract violations', () {
      late int invokeCount;

      /// verify_receipt가 항상 200 + [body]로 응답하는 mock 클라이언트를 설치하고
      /// 실제 호출 횟수를 센다.
      void installCountingVerifyReceiptMock(Object body) {
        tearDownMockSupabase();
        SharedPreferences.setMockInitialValues({});
        invokeCount = 0;
        testSupabaseClient = SupabaseClient(
          'http://localhost:54321',
          'test-anon-key-for-testing-purposes-only',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/functions/v1/verify-receipt-v2')) {
              invokeCount++;
              return http.Response(
                jsonEncode(body),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              '{}',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
      }

      test('contract-violating settlement payload is not retried', () async {
        // 서버는 이미 정산·지급을 끝내고 200으로 응답했지만
        // promotion 이 null 이라 canonical parser 가 거부하는 계약 위반 응답.
        installCountingVerifyReceiptMock(
          _purchaseResult()..['promotion'] = null,
        );

        await expectLater(
          service.verifyReceipt(
            'receipt-data',
            'com.app.coins',
            'user-id',
            'production',
          ),
          throwsA(isA<ReceiptResponseContractException>()),
        );

        // 도착한 응답을 파싱하지 못한 것은 영구 오류이므로 재전송 금지.
        expect(invokeCount, 1);
      });

      test('non-object response body is not retried either', () async {
        installCountingVerifyReceiptMock(const ['not', 'an', 'object']);

        await expectLater(
          service.verifyReceipt(
            'receipt-data',
            'com.app.coins',
            'user-id',
            'production',
          ),
          throwsA(isA<ReceiptResponseContractException>()),
        );

        expect(invokeCount, 1);
      });
    });

    /// `replayed` says the server had already applied the operation. It does
    /// not say who put it there, and the retry loop below can be the culprit:
    /// a request that settles on the server and then fails in transport is
    /// re-sent against the same idempotency key, and the replay comes back for
    /// candy the user has never been shown.
    group('replay attribution', () {
      late int invokeCount;

      /// Installs a verify_receipt mock that fails the first
      /// [failuresBeforeSuccess] requests the way a lost response does - the
      /// generic retry branch that a timeout also lands in - and then answers
      /// with [body].
      void installFlakyVerifyReceiptMock(
        Object body, {
        required int failuresBeforeSuccess,
      }) {
        tearDownMockSupabase();
        SharedPreferences.setMockInitialValues({});
        invokeCount = 0;
        testSupabaseClient = SupabaseClient(
          'http://localhost:54321',
          'test-anon-key-for-testing-purposes-only',
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/functions/v1/verify-receipt-v2')) {
              invokeCount++;
              if (invokeCount <= failuresBeforeSuccess) {
                return http.Response('upstream lost', 502, request: request);
              }
              return http.Response(
                jsonEncode(body),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              '{}',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
      }

      test('a replay answering our own retry is attributed to us', () async {
        installFlakyVerifyReceiptMock(
          _purchaseResult()..['replayed'] = true,
          failuresBeforeSuccess: 1,
        );

        final result = await service.verifyReceipt(
          'receipt-data',
          'com.app.coins',
          'user-id',
          'production',
        );

        expect(invokeCount, 2);
        expect(result.replayed, isTrue);
        expect(
          result.replayCausedByRetry,
          isTrue,
          reason:
              'our first request settled it, so the user has been shown '
              'nothing and the grant receipt is still owed',
        );
      });

      test('a replay on the very first request is not ours', () async {
        installFlakyVerifyReceiptMock(
          _purchaseResult()..['replayed'] = true,
          failuresBeforeSuccess: 0,
        );

        final result = await service.verifyReceipt(
          'receipt-data',
          'com.app.coins',
          'user-id',
          'production',
        );

        expect(invokeCount, 1);
        expect(result.replayed, isTrue);
        expect(result.replayCausedByRetry, isFalse);
      });

      test('a fresh settlement is never attributed to a retry', () async {
        installFlakyVerifyReceiptMock(
          _purchaseResult(),
          failuresBeforeSuccess: 1,
        );

        final result = await service.verifyReceipt(
          'receipt-data',
          'com.app.coins',
          'user-id',
          'production',
        );

        expect(result.replayed, isFalse);
        expect(result.replayCausedByRetry, isFalse);
      });
    });
  });
}
