import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReceiptQueueService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupMockSupabase({
      'functions:verify_receipt': {'success': true},
    });
    service = ReceiptQueueService();
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('ReceiptQueueService', () {
    group('enqueueAndroid', () {
      test('enqueues an item and returns a client trace ID', () async {
        final traceId = await service.enqueueAndroid(
          receipt: 'test-receipt',
          productId: 'test-product',
          userId: 'test-user',
          environment: 'sandbox',
        );

        expect(traceId, isNotEmpty);
        expect(traceId, startsWith('android-'));
      });

      test('enqueued item is persisted in SharedPreferences', () async {
        await service.enqueueAndroid(
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
        expect(items[0]['attempt'], 0);
        expect(items[0]['nextAt'], 0);
        expect(items[0]['client_trace_id'], isNotEmpty);
        expect(items[0]['createdAt'], isNotEmpty);
      });

      test('multiple enqueue calls add multiple items', () async {
        await service.enqueueAndroid(
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        await service.enqueueAndroid(
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
        final traceId1 = await service.enqueueAndroid(
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        final traceId2 = await service.enqueueAndroid(
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
        final traceId = await service.enqueueAndroid(
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
        final traceId1 = await service.enqueueAndroid(
          receipt: 'receipt-1',
          productId: 'product-1',
          userId: 'user-1',
          environment: 'sandbox',
        );
        await service.enqueueAndroid(
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
        await service.enqueueAndroid(
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
          'functions:verify_receipt': {'success': true},
        });

        await service.enqueueAndroid(
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
          'functions:verify_receipt': {'success': true},
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
          'functions:verify_receipt': {'success': true},
        });

        await service.enqueueAndroid(
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

    group('_computeNextAt backoff', () {
      // We can indirectly test this by causing a failure and checking the nextAt
      test('failed send increments attempt and sets future nextAt', () async {
        // Setup mock that returns failure (non-200 or success=false)
        setupMockSupabase({
          'functions:verify_receipt': {'success': false},
        });

        await service.enqueueAndroid(
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
          'functions:verify_receipt': {'success': false},
        });

        await service.enqueueAndroid(
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
        final traceId = await service.enqueueAndroid(
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
}
