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
    service.canFlushPendingIntake = null;
  });

  tearDown(() {
    service.canFlushPendingIntake = null;
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

      test(
        'the same purchase token reuses one deterministic queue item',
        () async {
          final traceId1 = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'same-purchase-token',
            productId: 'product-1',
            userId: 'user-1',
            environment: 'sandbox',
          );
          final traceId2 = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'same-purchase-token',
            productId: 'product-1',
            userId: 'user-1',
            environment: 'sandbox',
          );

          expect(traceId2, traceId1);
          expect(traceId1, matches(RegExp(r'^android-[0-9a-f]{32}$')));

          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString('receipt_queue_v1');
          final items = (json.decode(raw!) as List)
              .cast<Map<String, dynamic>>();
          expect(items, hasLength(1));
          expect(items.single['receipt'], 'same-purchase-token');
        },
      );
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

    group('Android pending intake flush gate', () {
      int verificationRequests() => capturedMockRequests
          .where((uri) => uri.path.endsWith('/functions/v1/verify-receipt-v2'))
          .length;

      Future<List<Map<String, dynamic>>> queuedItems() async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        return raw == null || raw.isEmpty
            ? []
            : (json.decode(raw) as List).cast<Map<String, dynamic>>();
      }

      test(
        'persisted pending rows are never sent while the gate is OFF',
        () async {
          await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'pending-token',
            productId: 'STAR100',
            userId: 'user-1',
            environment: 'sandbox',
            pendingIntake: true,
          );
          service.canFlushPendingIntake = () async => false;

          await service.flushPending();

          expect(verificationRequests(), 0);
          final queue = await queuedItems();
          expect(queue, hasLength(1));
          expect(queue.single['pending_intake'], isTrue);
          expect(queue.single['attempt'], 0);
        },
      );

      test(
        'a 422 on a pending intake keeps the row so the sweep cannot re-create it',
        () async {
          // The Android key is derived from the purchase token, so the row's
          // existence is what stops the next cold-start/resume sweep from
          // enqueuing the same token again. Dropping it on 422 would let the
          // sweep re-intake every five minutes for Play's three-day pending
          // window.
          tearDownMockSupabase();
          setupMockSupabase(
            {
              'functions:verify-receipt-v2': {'error': 'PURCHASE_REJECTED'},
            },
            functionStatusCodes: {'functions:verify-receipt-v2': 422},
          );
          final trace = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'rejected-pending-token',
            productId: 'STAR100',
            userId: 'user-1',
            environment: 'sandbox',
            pendingIntake: true,
          );
          service.canFlushPendingIntake = () async => true;

          await service.flushPending();

          final afterReject = await queuedItems();
          expect(afterReject, hasLength(1), reason: 'row must survive the 422');
          expect(afterReject.single['intake_rejected'], isTrue);
          expect(verificationRequests(), 1);

          // A second flush must not spend another request on it.
          await service.flushPending();
          expect(verificationRequests(), 1);
          expect(await queuedItems(), hasLength(1));

          // Re-intake from a later sweep joins the surviving row instead of
          // creating a new one.
          final again = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'rejected-pending-token',
            productId: 'STAR100',
            userId: 'user-1',
            environment: 'sandbox',
            pendingIntake: true,
          );
          expect(again, trace);
          expect(await queuedItems(), hasLength(1));
        },
      );

      test('gate lookup exceptions are fail-closed at flush time', () async {
        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'pending-token',
          productId: 'STAR100',
          userId: 'user-1',
          environment: 'sandbox',
          pendingIntake: true,
        );
        service.canFlushPendingIntake = () async => throw StateError('offline');

        await service.flushPending();

        expect(verificationRequests(), 0);
        expect(await queuedItems(), hasLength(1));
      });

      test(
        'a later purchased enqueue promotes the same token and can flush',
        () async {
          final pendingTrace = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'transition-token',
            productId: 'STAR100',
            userId: 'pending-observer',
            environment: 'sandbox',
            pendingIntake: true,
          );

          final purchasedTrace = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'transition-token',
            productId: 'STAR100',
            userId: 'wrong-session',
            environment: 'sandbox',
          );
          final ownerRetryTrace = await service.enqueue(
            platform: ReceiptQueueService.platformAndroid,
            receipt: 'transition-token',
            productId: 'STAR100',
            userId: 'settlement-owner',
            environment: 'production',
          );
          service.canFlushPendingIntake = () async => false;

          expect(purchasedTrace, pendingTrace);
          expect(ownerRetryTrace, pendingTrace);
          final promoted = await queuedItems();
          expect(promoted, hasLength(1));
          expect(promoted.single['pending_intake'], isFalse);
          expect(promoted.single['user_id'], 'settlement-owner');
          expect(promoted.single['environment'], 'production');
          // A promoted row is a NEW request. Backoff accumulated while the
          // user had not paid yet must not delay the settlement that is now
          // due (the cap is five minutes).
          expect(promoted.single['attempt'], 0);
          expect(promoted.single['nextAt'], 0);
          expect(promoted.single['intake_rejected'], isFalse);

          await service.flushPending();

          expect(verificationRequests(), 1);
          expect(await queuedItems(), isEmpty);
        },
      );
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

    group('queue growth bound (TTL/count cap)', () {
      Map<String, dynamic> itemAged(String traceId, Duration age) => {
        'client_trace_id': traceId,
        'receipt': 'receipt-for-$traceId',
        'productId': 'STAR100',
        'user_id': 'user-1',
        'platform': 'android',
        'environment': 'sandbox',
        'format': 'google_play',
        'attempt': 5,
        // 아직 도래하지 않은 백오프 - 실제 정산 시도 없이 순수하게
        // 정리(prune) 로직만 관찰한다.
        'nextAt': DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'createdAt': DateTime.now().subtract(age).toIso8601String(),
      };

      Future<List<dynamic>> queuedItems() async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        return raw == null || raw.isEmpty
            ? const []
            : json.decode(raw) as List<dynamic>;
      }

      test('flushPending drops entries older than receiptQueueMaxAge, keeps '
          'fresh ones', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'receipt_queue_v1',
          json.encode([
            itemAged(
              'stale',
              PurchaseConstants.receiptQueueMaxAge + const Duration(days: 1),
            ),
            itemAged('fresh', const Duration(hours: 1)),
          ]),
        );

        await service.flushPending();

        final items = await queuedItems();
        expect(
          items.map((e) => e['client_trace_id']),
          ['fresh'],
          reason:
              '오래돼도 정산 못 한 항목은 로컬 큐에서만 지운다 - 스토어 '
              '트랜잭션은 손대지 않으므로(finish/consume 안 함) 다음 '
              '콜드스타트/재개 스윕이 스토어에서 직접 다시 찾아내 '
              '재검증한다',
        );
      });

      test('flushPending caps total entries at receiptQueueMaxEntries, '
          'evicting the oldest first', () async {
        final seedCount = PurchaseConstants.receiptQueueMaxEntries + 3;
        final seeded = List.generate(
          seedCount,
          (i) => itemAged('seed-$i', Duration(minutes: seedCount - i)),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', json.encode(seeded));

        await service.flushPending();

        final items = await queuedItems();
        expect(items.length, PurchaseConstants.receiptQueueMaxEntries);
        expect(
          items.map((e) => e['client_trace_id']),
          isNot(contains('seed-0')),
          reason: '가장 오래된(제일 먼저 넣은) 항목부터 잘려야 한다',
        );
        expect(
          items.last['client_trace_id'],
          'seed-${seedCount - 1}',
          reason: '가장 최근 항목은 남아 있어야 한다',
        );
      });

      test('overflow eviction goes by actual createdAt, not list position - '
          'a stray old entry out of order is still the one dropped', () async {
        // 리스트 순서와 실제 나이가 어긋난 상황(동시 쓰기·복구된 데이터
        // 등)을 흉내낸다: 목록의 첫 항목이 오히려 가장 최근이고, 목록
        // 중간의 항목이 실제로는 가장 오래됐다.
        final seedCount = PurchaseConstants.receiptQueueMaxEntries + 1;
        final seeded = List.generate(
          seedCount,
          (i) => itemAged('seed-$i', const Duration(minutes: 10)),
        );
        // seed-3 만 실제로 훨씬 오래된 것으로 만든다.
        final oldestIndex = 3;
        seeded[oldestIndex] = itemAged(
          'seed-$oldestIndex',
          const Duration(days: 3),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', json.encode(seeded));

        await service.flushPending();

        final items = await queuedItems();
        expect(items.length, PurchaseConstants.receiptQueueMaxEntries);
        expect(
          items.map((e) => e['client_trace_id']),
          isNot(contains('seed-$oldestIndex')),
          reason:
              '목록에서는 앞쪽이 아니어도, 실제 createdAt 이 가장 오래된 '
              '항목이 잘려야 한다 - 목록 순서에만 의존하면 동시 쓰기나 '
              '복구된 데이터에서 엉뚱한(더 최근) 항목이 잘릴 수 있다',
        );
        expect(items.map((e) => e['client_trace_id']), contains('seed-0'));
      });

      test('enqueue itself enforces the count cap immediately, not just on '
          'the next flush', () async {
        final seedCount = PurchaseConstants.receiptQueueMaxEntries;
        final seeded = List.generate(
          seedCount,
          (i) => itemAged('seed-$i', Duration(minutes: seedCount - i)),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', json.encode(seeded));

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'brand-new-receipt',
          productId: 'STAR200',
          userId: 'user-1',
          environment: 'sandbox',
        );

        final items = await queuedItems();
        expect(
          items.length,
          PurchaseConstants.receiptQueueMaxEntries,
          reason:
              '재개 스윕은 최대 5분마다만 돈다 - enqueue 시점에도 상한을 '
              '지키지 않으면, 포그라운드에 오래 머물며 연속 구매하는 '
              '동안 다음 flush 전까지 큐가 상한을 넘어 계속 자란다',
        );
        expect(
          items.map((e) => e['client_trace_id']),
          isNot(contains('seed-0')),
        );
      });

      test(
        'onItemsEvicted fires when pruning actually drops entries',
        () async {
          var evictedCallCount = 0;
          service.onItemsEvicted = () => evictedCallCount++;
          addTearDown(() => service.onItemsEvicted = null);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'receipt_queue_v1',
            json.encode([
              itemAged(
                'stale',
                PurchaseConstants.receiptQueueMaxAge + const Duration(days: 1),
              ),
            ]),
          );

          await service.flushPending();

          expect(
            evictedCallCount,
            1,
            reason:
                '잘려나간 항목의 실제 결제 복구는 다음 콜드스타트/재개까지 '
                '기다리지 않고, 이 콜백을 통해 즉시 리컨사일을 걸 수 있어야 '
                '한다',
          );
        },
      );

      // Codex Frontier 리뷰 지적 (PR #137): enqueue()가 새 항목을 더한 뒤
      // 상한을 다시 넘는 극단적 상황을 방어하려고 sublist(overflow)로 한 번
      // 더 잘라내는데, 이 경로는 onItemsEvicted를 호출하지 않았다. 그러면
      // 잘린 결제의 회수용 리컨사일이 즉시 걸리지 않고 다음 콜드스타트/
      // 재개까지 미뤄진다 - _pruneStale의 정리와 같은 보장을 못 받는다.
      test('onItemsEvicted also fires when enqueue itself has to trim the '
          'freshly-added item back down to the cap', () async {
        var evictedCallCount = 0;
        service.onItemsEvicted = () => evictedCallCount++;
        addTearDown(() => service.onItemsEvicted = null);

        final seedCount = PurchaseConstants.receiptQueueMaxEntries;
        final seeded = List.generate(
          seedCount,
          (i) => itemAged('seed-$i', Duration(minutes: seedCount - i)),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receipt_queue_v1', json.encode(seeded));

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'brand-new-receipt',
          productId: 'STAR200',
          userId: 'user-1',
          environment: 'sandbox',
        );

        expect(
          evictedCallCount,
          1,
          reason:
              '_pruneStale 경로와 동일하게, 이 트림도 실제로 항목을 '
              '잘라냈으니 즉시 리컨사일을 걸 수 있어야 한다',
        );
      });

      test('onItemsEvicted does NOT fire when nothing is pruned', () async {
        var evictedCallCount = 0;
        service.onItemsEvicted = () => evictedCallCount++;
        addTearDown(() => service.onItemsEvicted = null);

        await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'fresh-receipt',
          productId: 'STAR100',
          userId: 'user-1',
          environment: 'sandbox',
        );

        expect(
          evictedCallCount,
          0,
          reason:
              '아무것도 안 잘렸는데 매번 리컨사일을 걸면 정상적인 '
              '연속 구매마다 불필요한 스토어 조회가 발생한다',
        );
      });
    });

    group('concurrent mutation safety', () {
      Future<List<dynamic>> queuedItems() async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('receipt_queue_v1');
        return raw == null || raw.isEmpty
            ? const []
            : json.decode(raw) as List<dynamic>;
      }

      test('two concurrent enqueue calls for different receipts both survive '
          '(no lost update)', () async {
        // await 없이 동시에 호출한다 - 실제 구매 도중 enqueue 가, 다른
        // 스레드가 아니라 같은 이벤트 루프에서 겹치는 상황(예: 연속
        // 구매·큐 플러시와 동시)을 흉내낸다.
        final future1 = service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-A',
          productId: 'product-A',
          userId: 'user-1',
          environment: 'sandbox',
        );
        final future2 = service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'receipt-B',
          productId: 'product-B',
          userId: 'user-1',
          environment: 'sandbox',
        );

        await Future.wait([future1, future2]);

        final items = await queuedItems();
        expect(
          items.map((e) => e['productId']),
          containsAll(['product-A', 'product-B']),
          reason:
              '두 enqueue 가 직렬화되지 않으면 같은 스냅샷을 읽고 나중에 '
              '저장한 쪽이 먼저 저장된 영수증을 통째로 덮어써, 과금된 '
              '구매 하나가 이 durable 큐에서 조용히 사라진다',
        );
      });

      test('enqueue racing with _dropItem (as flushPending would call it) '
          'does not lose the new enqueue', () async {
        final existingTraceId = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'existing-receipt',
          productId: 'existing-product',
          userId: 'user-1',
          environment: 'sandbox',
        );

        final dropFuture = service.removeByClientTraceId(existingTraceId);
        final enqueueFuture = service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'new-receipt',
          productId: 'new-product',
          userId: 'user-1',
          environment: 'sandbox',
        );

        await Future.wait([dropFuture, enqueueFuture]);

        final items = await queuedItems();
        expect(
          items.map((e) => e['productId']),
          contains('new-product'),
          reason:
              '동시에 진행 중인 제거 작업이 새로 적재된 영수증까지 '
              '함께 지워서는 안 된다',
        );
        expect(
          items.map((e) => e['client_trace_id']),
          isNot(contains(existingTraceId)),
          reason: '반대로 제거도 실제로 반영되어야 한다',
        );
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
        final futureNextAt = DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch;
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
        final remaining = (json.decode(raw!) as List)
            .cast<Map<String, dynamic>>();
        expect(remaining.length, 1);
        expect(remaining[0]['client_trace_id'], 'test-trace-id');
      });

      test('sends items whose nextAt is in the past', () async {
        setupMockSupabase({
          'functions:verify-receipt-v2': {'success': true},
        });

        final prefs = await SharedPreferences.getInstance();
        final pastNextAt = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch;
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
        final remaining = (json.decode(raw!) as List)
            .cast<Map<String, dynamic>>();
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
        final remaining = (json.decode(raw!) as List)
            .cast<Map<String, dynamic>>();
        expect(remaining, isEmpty);
      });
    });

    group('flushPending wallet.v1 success', () {
      test(
        'wallet.v1 settlement response (success 키 없음) removes item',
        () async {
          setupMockSupabase({
            'functions:verify-receipt-v2': {
              'contract_version': 'wallet.v1',
              'operation_id': '00000000-0000-4000-8000-000000000001',
              'replayed': true,
              'base_star_amount': '100',
              'base_bonus_amount': '0',
              // 큐는 이제 이 본문을 파싱해 analytics 로 넘긴 뒤에만 항목을
              // 제거한다 — 계약을 만족하는 본문이어야 성공 경로가 된다.
              'promotion': {
                'resolution_id': '00000000-0000-4000-8000-000000000611',
                'state': 'ELIGIBLE',
                'campaign_version_id': null,
                'promo_bonus_amount': '0',
                'domain_code': null,
              },
              'wallet': {
                'contract_version': 'wallet.v1',
                'star': '100',
                'bonus': '0',
                'cotton': '0',
                'cotton_expiring_amount': '0',
                'cotton_next_expires_at': null,
                'snapshot_at': '2026-08-24T00:00:00.000Z',
              },
            },
          });
          service.onSettlementRecovered =
              (
                settlement, {
                required String storeProductId,
                required String? clientObservedCurrency,
              }) async => true;
          addTearDown(() => service.onSettlementRecovered = null);

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
          final items = (json.decode(raw!) as List)
              .cast<Map<String, dynamic>>();
          expect(items, isEmpty);
        },
      );
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

    group('Android deterministic client trace ID', () {
      test('generated trace IDs have expected format', () async {
        final traceId = await service.enqueue(
          platform: ReceiptQueueService.platformAndroid,
          receipt: 'r',
          productId: 'p',
          userId: 'u',
          environment: 'e',
        );

        expect(traceId, matches(RegExp(r'^android-[0-9a-f]{32}$')));
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

      expect(
        refreshCalls(),
        greaterThanOrEqualTo(1),
        reason: '401 이면 refresh_token 갱신이 일어나야 한다',
      );
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
