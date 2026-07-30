import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReceiptQueueService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupMockSupabase({
      'functions:verify-receipt-v2': {'success': true},
    });
    service = ReceiptQueueService();
    // 싱글턴이라 테스트 간 상태가 새지 않게 프로덕션 기본값으로 되돌린다.
    service.flushInvokeTimeout = PurchaseConstants.verificationTimeout;
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('ReceiptQueueService', () {
    group('enqueue (android)', () {
      test('enqueues an item and returns a client trace ID', () async {
        final traceId = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        expect(traceId, isNotEmpty);
        expect(traceId, startsWith('android-'));
      });

      test('enqueued item is persisted in SharedPreferences', () async {
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        expect(raw, isNotNull);

        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['receipt'], 'test-receipt');
        expect(items[0]['productId'], 'test-product');
        expect(items[0]['user_id'], 'test-user');
        expect(items[0]['platform'], 'android');
        expect(items[0]['environment'], 'sandbox');
        expect(items[0]['format'], 'google_play');
        expect(items[0]['attempt'], 0);
        expect(items[0]['nextAt'], 0);
        expect(items[0]['client_trace_id'], isNotEmpty);
        expect(items[0]['createdAt'], isNotEmpty);
      });

      test('multiple enqueue calls add multiple items', () async {
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-2',
          productId: 'product-2',
          userId: 'user-2',
          environment: 'production',
        );

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 2);
        expect(items[0]['productId'], 'product-1');
        expect(items[1]['productId'], 'product-2');
      });

      test('each enqueue generates a unique trace ID', () async {
        final traceId1 = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        final traceId2 = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-2',
          productId: 'product-2',
          userId: 'user-2',
          environment: 'sandbox',
        );

        expect(traceId1, isNot(equals(traceId2)));
      });
    });

    group('removeByClientTraceId', () {
      test('removes item with matching trace ID', () async {
        final traceId = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.removeByClientTraceId(traceId);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items, isEmpty);
      });

      test('does not remove other items', () async {
        final traceId1 = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-2',
          productId: 'product-2',
          userId: 'user-2',
          environment: 'sandbox',
        );

        await service.removeByClientTraceId(traceId1);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['productId'], 'product-2');
      });

      test('removing non-existent trace ID does nothing', () async {
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );

        await service.removeByClientTraceId('non-existent-id');

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
      });
    });

    group('_loadQueue edge cases', () {
      test('returns empty list when no data in SharedPreferences', () async {
        // flushPending on empty queue should not throw
        await service.flushPending();
        // If we got here without error, the test passes
      });

      test('handles empty string in SharedPreferences', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', '');

        // Should not throw
        await service.flushPending();
      });

      test('handles malformed JSON in SharedPreferences', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', 'not-valid-json');

        // Should not throw - _loadQueue catches and returns empty list
        await service.flushPending();
      });
    });

    group('flushPending', () {
      test('successfully sends receipt and removes from queue', () async {
        // Setup mock that returns success
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': true},
        });

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        // Successful items should be removed
        expect(items, isEmpty);
      });

      test('does nothing when queue is empty', () async {
        await service.flushPending();
        // Should complete without error
      });

      test('skips items whose nextAt has not been reached', () async {
        // Manually enqueue an item with a future nextAt
        final prefs = await SharedPreferences.getInstance();
        final futureNextAt =
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
        final items = [
          {
            'client_trace_id': 'test-trace-id',
            'receipt': 'test-receipt',
            'productId': 'test-product',
            'user_id': 'test-user',
            'platform': 'android',
            'environment': 'sandbox',
            'attempt': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'nextAt': futureNextAt,
          },
        ];
        await prefs.setString('receipt_queue_v1', json.encode(items));

        await service.flushPending();

        // Item should still be in queue (not yet time to send)
        final raw = prefs.getString('receipt_queue_v1');
        final remaining =
            (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(remaining.length, 1);
        expect(remaining[0]['client_trace_id'], 'test-trace-id');
      });

      test('sends items whose nextAt is in the past', () async {
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': true},
        });

        final prefs = await SharedPreferences.getInstance();
        final pastNextAt =
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
        final items = [
          {
            'client_trace_id': 'test-trace-id',
            'receipt': 'test-receipt',
            'productId': 'test-product',
            'user_id': 'test-user',
            'platform': 'android',
            'environment': 'sandbox',
            'attempt': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'nextAt': pastNextAt,
          },
        ];
        await prefs.setString('receipt_queue_v1', json.encode(items));

        await service.flushPending();

        final raw = prefs.getString('receipt_queue_v1');
        final remaining =
            (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        // Successful send should remove from queue
        expect(remaining, isEmpty);
      });

      test('items with nextAt 0 are sent immediately', () async {
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': true},
        });

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final remaining =
            (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(remaining, isEmpty);
      });
    });

    group('flushPending wallet.v1 success', () {
      test('wallet.v1 settlement response (success 키 없음) removes item',
          () async {
        setupMockSupabase({
          'functions:verify-receipt-v2': {
            'contract_version': 'wallet.v1',
            'operation_id': '00000000-0000-4000-8000-000000000001',
            'replayed': true,
            'base_star_amount': '100',
            'base_bonus_amount': '0',
            'promotion': null,
            'wallet': {},
          },
        });

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items, isEmpty);
      });
    });

    group('flushPending non-2xx handling', () {
      // verify-receipt-v2 는 409 를 반환하지 않는다(엔진 grep 0건). 죽은
      // 제거 분기를 없앤 뒤에는 409 도 "정체 불명의 실패" = 유지 + 백오프다.
      // 지급 확정 여부를 알 수 없는 응답으로 과금된 영수증의 유일한 durable
      // 기록을 지우지 않는 쪽이 안전한 기본값이다.
      test('409(지급 확정 문구)는 더 이상 제거 신호가 아니다 - 유지 + 백오프', () async {
        setupMockSupabase(
          {
            'functions:verify-receipt-v2': {
              'success': false,
              'code': 'DUPLICATE_RECEIPT',
              'message': '이미 처리된 구매입니다.',
            },
          },
          functionStatusCodes: {'functions:verify-receipt-v2': 409},
        );

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['attempt'], 1);
      });

      test('409(지급 실패 문구)도 재시도용으로 유지된다', () async {
        setupMockSupabase(
          {
            'functions:verify-receipt-v2': {
              'success': false,
              'code': 'DUPLICATE_RECEIPT',
              'message': '이미 처리된 구매입니다. 보상 지급에 실패했습니다.',
            },
          },
          functionStatusCodes: {'functions:verify-receipt-v2': 409},
        );

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['attempt'], 1);
      });

      // 헬퍼 자체는 남는다: 레거시 verify_receipt(v162)의 409 를 만나는
      // foreground 검증 경로가 계속 쓴다(receipt_verification_service.dart).
      test('duplicateConfirmsGrant is conservative on unknown bodies', () {
        expect(
          ReceiptQueueService.duplicateConfirmsGrant({
            'code': 'DUPLICATE_RECEIPT',
            'message': '이미 처리된 구매입니다.',
          }),
          isTrue,
        );
        expect(
          ReceiptQueueService.duplicateConfirmsGrant({
            'code': 'DUPLICATE_RECEIPT',
            'message': '이미 처리된 구매입니다. 보상 지급에 실패했습니다.',
          }),
          isFalse,
        );
        expect(ReceiptQueueService.duplicateConfirmsGrant(null), isFalse);
        expect(ReceiptQueueService.duplicateConfirmsGrant('text'), isFalse);
        expect(
          ReceiptQueueService.duplicateConfirmsGrant({'code': 'OTHER'}),
          isFalse,
        );
      });

      test('500 keeps item with backoff for retry', () async {
        setupMockSupabase(
          {
            'functions:verify-receipt-v2': {'error': 'Internal server error'},
          },
          functionStatusCodes: {'functions:verify-receipt-v2': 500},
        );

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['attempt'], 1);
        expect(
          items[0]['nextAt'],
          greaterThan(DateTime.now().millisecondsSinceEpoch),
        );
      });
    });

    group('_computeNextAt backoff', () {
      // We can indirectly test this by causing a failure and checking the nextAt
      test('failed send increments attempt and sets future nextAt', () async {
        // Setup mock that returns failure (non-200 or success=false)
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': false},
        });

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        await service.flushPending();

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        final items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items.length, 1);
        expect(items[0]['attempt'], 1);
        expect(items[0]['nextAt'], greaterThan(0));
        // nextAt should be in the future
        expect(
          items[0]['nextAt'],
          greaterThan(DateTime.now().millisecondsSinceEpoch),
        );
      });

      test('multiple failed sends increment attempt count', () async {
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': false},
        });

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        // First flush - attempt goes from 0 to 1
        await service.flushPending();

        // Manually reset nextAt to 0 so the second flush actually tries to send
        final prefs = await SharedPreferences.getInstance();
        var raw = prefs.getString('receipt_queue_v1');
        var items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        items[0]['nextAt'] = 0;
        await prefs.setString('receipt_queue_v1', json.encode(items));

        // Second flush - attempt goes from 1 to 2
        await service.flushPending();

        raw = prefs.getString('receipt_queue_v1');
        items = (json.decode(raw!) as List).cast<Map<String, dynamic>>();
        expect(items[0]['attempt'], 2);
      });
    });

    group('_generateClientTraceId', () {
      test('generated trace IDs have expected format', () async {
        final traceId = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'r',
          productId: 'p',
          userId: 'u',
          environment: 'e',
        );

        expect(traceId, startsWith('android-'));
        final parts = traceId.split('-');
        // android-<timestamp>-<hexRandom>
        expect(parts.length, greaterThanOrEqualTo(3));
        // Timestamp part should be a valid number
        expect(int.tryParse(parts[1]), isNotNull);
      });
    });
  });

  /// 부팅 직후 플러시는 세션 복원과 경쟁하므로 401 이 정상 시나리오다.
  /// 기존 구현은 401 을 그냥 백오프로 넘겨 첫 플러시를 통째로 낭비했다.
  /// foreground 검증과 같은 [invokeWithAuthRecovery] 계약을 쓴다.
  group('flushPending auth recovery (401)', () {
    late ReceiptQueueService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await setupMockSupabaseWithAuth({
        'functions:verify-receipt-v2': {'success': true},
      }, userId: 'test-user-id');
      authService = ReceiptQueueService();
      authService.flushInvokeTimeout = PurchaseConstants.verificationTimeout;
      capturedMockRequests.clear();
    });

    tearDown(tearDownMockSupabase);

    int verifyCalls() => capturedMockRequests
        .where((u) => u.path.contains('/functions/v1/verify-receipt-v2'))
        .length;

    int refreshCalls() => capturedMockRequests
        .where(
          (u) =>
              u.path.contains('/auth/') &&
              u.queryParameters['grant_type'] == 'refresh_token',
        )
        .length;

    test('401 이면 세션을 갱신해 한 번 더 보내고 성공 시 항목을 제거한다', () async {
      functionStatusQueues['functions:verify-receipt-v2'] = [401];

      await authService.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'test-receipt',
        productId: 'test-product',
        userId: 'test-user-id',
        environment: 'sandbox',
      );

      await authService.flushPending();

      expect(refreshCalls(), greaterThanOrEqualTo(1),
          reason: '401 이면 refresh_token 갱신이 일어나야 한다');
      expect(verifyCalls(), 2, reason: '401 1회 + 갱신 후 재시도 1회');

      final prefs = await SharedPreferences.getInstance();
      final items = (json.decode(prefs.getString('receipt_queue_v1')!) as List)
          .cast<Map<String, dynamic>>();
      expect(items, isEmpty, reason: '갱신 후 성공했으므로 제거되어야 한다');
    });

    test('갱신 후에도 401 이면 항목을 유지하고 백오프한다', () async {
      functionStatusQueues['functions:verify-receipt-v2'] = [401, 401];

      await authService.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'test-receipt',
        productId: 'test-product',
        userId: 'test-user-id',
        environment: 'sandbox',
      );

      await authService.flushPending();

      final prefs = await SharedPreferences.getInstance();
      final items = (json.decode(prefs.getString('receipt_queue_v1')!) as List)
          .cast<Map<String, dynamic>>();
      expect(items.length, 1, reason: '인증 복구 실패는 영구 거부가 아니다 - 유지');
      expect(items[0]['attempt'], 1);
    });
  });
}
