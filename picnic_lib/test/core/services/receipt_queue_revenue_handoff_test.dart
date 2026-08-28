import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

/// 서버가 200 으로 돌려주는 wallet.v1 정산 본문.
Map<String, dynamic> settlementBody({String? currency, String? value}) =>
    <String, dynamic>{
      'contract_version': 'wallet.v1',
      'operation_id': 'operation-1',
      'replayed': false,
      'base_star_amount': '100',
      'base_bonus_amount': '10',
      // canonical 파서는 promotion 객체를 요구한다 — foreground 경로와 같은
      // 파서를 쓰므로 여기서도 같은 모양이어야 한다.
      'promotion': <String, dynamic>{
        'resolution_id': '00000000-0000-4000-8000-000000000611',
        'state': 'ELIGIBLE',
        'campaign_version_id': null,
        'promo_bonus_amount': '0',
        'domain_code': null,
      },
      'wallet': <String, dynamic>{
        'contract_version': 'wallet.v1',
        'star': '100',
        'bonus': '0',
        'cotton': '0',
        'cotton_expiring_amount': '0',
        'cotton_next_expires_at': null,
        'snapshot_at': '2026-08-24T00:00:00.000Z',
      },
      if (currency != null) 'currency': currency,
      if (value != null) 'value': value,
    };


/// StoreKit2 JWS 모양의 영수증. 서명은 검증하지 않고 transactionId 만 읽히면
/// 되므로 페이로드만 진짜다 — 이 테스트가 보는 것은 큐 키의 결정성이다.
final String _jws = <String>[
  base64Url.encode(utf8.encode('{"alg":"ES256"}')).replaceAll('=', ''),
  base64Url
      .encode(utf8.encode('{"transactionId":"2000001213180810"}'))
      .replaceAll('=', ''),
  'signature',
].join('.');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReceiptQueueService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ReceiptQueueService();
    service.flushInvokeTimeout = PurchaseConstants.verificationTimeout;
  });

  tearDown(() {
    // 싱글턴이라 훅을 남기면 다음 테스트로 샌다.
    service.onSettlementRecovered = null;
    tearDownMockSupabase();
  });

  Future<List<Map<String, dynamic>>> queue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('receipt_queue_v1');
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  group('관측 통화의 큐 왕복', () {
    setUp(() {
      setupMockSupabase({
        'functions:verify-receipt-v2': {'success': true},
      });
    });

    test('관측 통화는 정규화돼 저장되고 재전송 본문에 복원된다', () async {
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'krw',
      );

      final items = await queue();
      expect(items.single['client_observed_currency'], 'KRW');

      final body = ReceiptQueueService.buildQueuedRequestBody(items.single);
      expect(body['client_observed_currency'], 'KRW');
      // 재전송 본문이 foreground 본문과 달라지면 서버는 구버전 클라이언트로
      // 읽고 7키로 낮춰 답한다 — 큐 경로만 조용히 매출을 잃는다.
      expect(body['parser_capabilities'], <String>['purchase_revenue_v1']);
    });

    test('ISO 4217 이 아닌 값은 저장하지 않는다', () async {
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'ja',
      );

      final items = await queue();
      expect(items.single.containsKey('client_observed_currency'), isFalse);
    });

    test('통화가 없던 기존 항목은 재전달 때 채워진다', () async {
      // iOS 키는 StoreKit transactionId 기반이라 같은 거래의 재전달이 같은
      // 항목으로 돌아온다. 최초 요청 때는 카탈로그가 아직 없었고, 재전달
      // 시점에는 로드돼 있는 상황이다.
      final first = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: _jws,
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );
      expect(
        (await queue()).single.containsKey('client_observed_currency'),
        isFalse,
      );

      final second = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: _jws,
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'KRW',
      );

      expect(second, first, reason: 'iOS 키는 재전달마다 같아야 한다');
      final items = await queue();
      expect(items, hasLength(1));
      expect(items.single['client_observed_currency'], 'KRW');
    });

    test('이미 통화가 있는 항목은 다른 값으로 덮어쓰지 않는다', () async {
      // 같은 거래의 통화가 재전달마다 바뀌면 어느 쪽이 맞는지 판단할 근거가
      // 없다. 최초 값을 정본으로 둔다.
      await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: _jws,
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'KRW',
      );
      await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: _jws,
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'USD',
      );

      expect((await queue()).single['client_observed_currency'], 'KRW');
    });
  });

  group('큐 복구의 durable 인계', () {
    test('analytics 가 이어받지 못하면 큐 항목을 지우지 않는다', () async {
      setupMockSupabase({
        'functions:verify-receipt-v2': settlementBody(
          currency: 'KRW',
          value: '2500',
        ),
      });
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );

      var called = 0;
      service.onSettlementRecovered =
          (
            settlement, {
            required String storeProductId,
            required String? clientObservedCurrency,
          }) async {
            called++;
            return false;
          };

      await service.flushPending();

      expect(called, 1);
      expect(
        await queue(),
        hasLength(1),
        reason: '이 항목은 그 거래의 매출을 되살릴 마지막 재료다',
      );
    });

    test('이어받으면 서버 값과 저장된 관측 통화가 함께 전달되고 큐가 비워진다', () async {
      setupMockSupabase({
        'functions:verify-receipt-v2': settlementBody(
          currency: 'KRW',
          value: '2500',
        ),
      });
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
        clientObservedCurrency: 'JPY',
      );

      PurchaseSettlementResultModel? received;
      String? receivedProductId;
      String? receivedObserved;
      service.onSettlementRecovered =
          (
            settlement, {
            required String storeProductId,
            required String? clientObservedCurrency,
          }) async {
            received = settlement;
            receivedProductId = storeProductId;
            receivedObserved = clientObservedCurrency;
            return true;
          };

      await service.flushPending();

      expect(received!.currency, 'KRW');
      expect(received!.value, 2500);
      expect(receivedProductId, 'star100');
      expect(receivedObserved, 'JPY');
      expect(await queue(), isEmpty);
    });

    test('레거시 success 응답은 넘길 정산이 없으므로 예전처럼 제거된다', () async {
      setupMockSupabase({
        'functions:verify-receipt-v2': {'success': true},
      });
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );

      var called = 0;
      service.onSettlementRecovered =
          (
            settlement, {
            required String storeProductId,
            required String? clientObservedCurrency,
          }) async {
            called++;
            return true;
          };

      await service.flushPending();

      expect(called, 0);
      expect(await queue(), isEmpty);
    });

    test('넘길 곳이 아직 연결되지 않았으면 항목을 남긴다', () async {
      // 여기서 제거하면 그 거래의 매출은 되살릴 재료 없이 사라진다.
      // 콜백이 연결된 다음 부팅 플러시에 맡긴다.
      setupMockSupabase({
        'functions:verify-receipt-v2': settlementBody(currency: 'KRW'),
      });
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );

      await service.flushPending();

      expect(await queue(), hasLength(1));
    });

    test('파싱할 수 없는 정산 본문은 격리하되 TTL 밖으로 고정하지는 않는다', () async {
      // 본문이 파싱되지 않는 것은 이 요청의 성질이 아니라 그 순간 서버가
      // 무엇을 배포하고 있었는지의 함수다. 일시적 배포 오류가 롤백되면 같은
      // 영수증이 정상 본문을 받는다 — 지우면 그때 재시도할 재료가 없다.
      final broken = settlementBody(currency: 'KRW')
        ..['base_star_amount'] = 100; // 계약은 10진 문자열을 요구한다
      setupMockSupabase({'functions:verify-receipt-v2': broken});
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );

      var called = 0;
      service.onSettlementRecovered =
          (
            settlement, {
            required String storeProductId,
            required String? clientObservedCurrency,
          }) async {
            called++;
            return true;
          };

      await service.flushPending();

      expect(called, 0);
      final kept = await queue();
      expect(kept, hasLength(1));
      expect(
        kept.single['analytics_pending'],
        isNot(true),
        reason: '소비자가 실패를 답한 것이 아니므로 TTL 밖으로 고정하지 않는다',
      );
    });

    test('상한 직전 새 적재는 인계 대기 항목을 먼저 밀어내지 않는다', () async {
      // 프룬 경로만 pending 을 보호하고 적재 경로가 앞에서 잘라 버리면,
      // 상한 직전에 새 결제가 들어오는 순간 가장 오래된 인계 대기 항목이
      // 정렬도 로그도 없이 사라진다.
      setupMockSupabase({
        'functions:verify-receipt-v2': settlementBody(currency: 'KRW'),
      });
      final prefs = await SharedPreferences.getInstance();
      final seeded = <Map<String, dynamic>>[
        <String, dynamic>{
          'client_trace_id': 'android-pending',
          'receipt': 'r',
          'productId': 'star100',
          'user_id': 'u',
          'platform': 'android',
          'environment': 'sandbox',
          'format': 'google_play',
          'attempt': 1,
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'nextAt': 0,
          'analytics_pending': true,
        },
        for (var i = 0; i < PurchaseConstants.receiptQueueMaxEntries - 1; i++)
          <String, dynamic>{
            'client_trace_id': 'android-filler-\$i',
            'receipt': 'r',
            'productId': 'star100',
            'user_id': 'u',
            'platform': 'android',
            'environment': 'sandbox',
            'format': 'google_play',
            'attempt': 0,
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'nextAt': 0,
          },
      ];
      await prefs.setString('receipt_queue_v1', json.encode(seeded));

      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'new',
        productId: 'star200',
        userId: 'u',
        environment: 'sandbox',
      );

      final remaining = await queue();
      expect(
        remaining.where((e) => e['client_trace_id'] == 'android-pending'),
        hasLength(1),
        reason: '인계 대기 항목은 마지막에 잘린다',
      );
    });

    test('인계 대기 항목은 TTL 이 지나도 잘리지 않는다', () async {
      // 이 거래의 스토어 트랜잭션은 이미 finish 됐다 — 스윕이 다시 찾아낼
      // 것이 없으므로 "잘라도 스윕이 회수한다"는 전제가 성립하지 않는다.
      setupMockSupabase({
        'functions:verify-receipt-v2': settlementBody(currency: 'KRW'),
      });
      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'r',
        productId: 'star100',
        userId: 'u',
        environment: 'sandbox',
      );
      service.onSettlementRecovered =
          (
            settlement, {
            required String storeProductId,
            required String? clientObservedCurrency,
          }) async => false;

      await service.flushPending();
      expect(await queue(), hasLength(1));

      // 항목을 TTL 밖으로 밀어 놓고 다시 프룬이 도는 경로를 태운다.
      final items = await queue();
      items[0]['createdAt'] = DateTime.now()
          .subtract(const Duration(days: 400))
          .toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('receipt_queue_v1', json.encode(items));

      await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'other',
        productId: 'star200',
        userId: 'u',
        environment: 'sandbox',
      );

      final remaining = await queue();
      expect(
        remaining.where((e) => e['productId'] == 'star100'),
        hasLength(1),
        reason: '정산 완료·인계 대기 항목은 나이로 자르지 않는다',
      );
    });
  });
}
