import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/analytics/analytics.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_analytics_dedup.dart';

/// 프로세스 재시작을 흉내 내려면 저장소 내용은 유지하면서 인스턴스만 갈아끼울 수
/// 있어야 한다. 실제 SharedPreferences 없이 그 성질만 재현한다.
class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({Map<String, String>? seed})
    : _data = <String, String>{...?seed};

  final Map<String, String> _data;

  int writes = 0;
  bool failReads = false;
  bool failWrites = false;

  Map<String, String> get snapshot => Map<String, String>.from(_data);

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    if (failReads) throw StateError('storage unavailable');
    return _data[key] ?? defaultValue;
  }

  @override
  Future<void> saveData(String key, String value) async {
    writes++;
    if (failWrites) throw StateError('storage unavailable');
    _data[key] = value;
  }

  @override
  Future<void> removeData(String key) async => _data.remove(key);

  @override
  Future<void> clearStorage() async => _data.clear();
}

/// 저장소 왕복이 즉시 끝나지 않는 환경. 실제 SharedPreferences 는 플랫폼
/// 채널을 타므로 이쪽이 현실에 가깝고, 동시 진입 창이 눈에 보인다.
class _SlowLocalStorage extends _FakeLocalStorage {
  _SlowLocalStorage(this.latency);

  final Duration latency;

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    await Future<void>.delayed(latency);
    return super.loadData(key, defaultValue);
  }

  @override
  Future<void> saveData(String key, String value) async {
    await Future<void>.delayed(latency);
    return super.saveData(key, value);
  }
}

ProductDetails _product(String id) => ProductDetails(
  id: id,
  title: 'Star Candy',
  description: '',
  price: r'$0.99',
  rawPrice: 0.99,
  currencyCode: 'USD',
);

/// 기록된 거래 항목들. 상한이 항목 단위인지 확인할 때 쓴다.
List<List<String>> _entries(String? raw) => <List<String>>[
  for (final entry in jsonDecode(raw!) as List<dynamic>)
    <String>[for (final key in entry as List<dynamic>) key as String],
];

void main() {
  setUp(() {
    PurchaseAnalyticsDedup.resetProcessCache();
    AnalyticsOutbox.resetProcessStateForTest();
  });
  tearDown(() {
    PurchaseAnalyticsDedup.resetProcessCache();
    AnalyticsOutbox.resetProcessStateForTest();
    PicnicAnalytics.resetInstance();
  });

  /// "예약하고 실제로 보냈다"를 한 줄로. 반환값은 발송했는지 여부.
  Future<bool> send(
    PurchaseAnalyticsDedup dedup,
    String? transactionId, {
    String? fallbackKey,
    bool delivered = true,
  }) async {
    final reservation = await dedup.reserve(
      transactionId,
      fallbackKey: fallbackKey,
    );
    if (reservation == null) return false;
    if (delivered) {
      await reservation.commit();
    } else {
      reservation.release();
    }
    return true;
  }

  group('PurchaseAnalyticsDedup', () {
    test('같은 거래 ID 는 처음 한 번만 통과한다', () async {
      final dedup = PurchaseAnalyticsDedup(storage: _FakeLocalStorage());

      expect(await send(dedup, 'tx-1'), isTrue);
      expect(await send(dedup, 'tx-1'), isFalse);
      expect(await send(dedup, 'tx-1'), isFalse);
    });

    test('서로 다른 거래는 각각 통과한다', () async {
      final dedup = PurchaseAnalyticsDedup(storage: _FakeLocalStorage());

      expect(await send(dedup, 'tx-1'), isTrue);
      expect(await send(dedup, 'tx-2'), isTrue);
    });

    test('인스턴스가 달라도 막는다 — AnalyticsService 는 호출부마다 새로 생성된다', () async {
      final storage = _FakeLocalStorage();

      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-1'),
        isTrue,
      );
      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-1'),
        isFalse,
      );
    });

    test('앱 재시작(메모리 소실) 후에도 저장소 기록이 막는다', () async {
      final storage = _FakeLocalStorage();
      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-1'),
        isTrue,
      );

      // 프로세스가 다시 뜬 상황: 정적 메모리 캐시는 비었지만 저장소는 남아 있다.
      // 스토어 큐의 미완료 트랜잭션이 스윕으로 재검증되는 경로가 이것이다.
      PurchaseAnalyticsDedup.resetProcessCache();

      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-1'),
        isFalse,
      );
    });

    test('거래 ID 가 없으면 서버 operation_id 로 막는다', () async {
      final dedup = PurchaseAnalyticsDedup(storage: _FakeLocalStorage());

      expect(await send(dedup, null, fallbackKey: 'op-1'), isTrue);
      expect(await send(dedup, '', fallbackKey: 'op-1'), isFalse);
    });

    test('거래 ID 와 operation_id 가 모두 없으면 막지 못하고 통과시킨다', () async {
      final dedup = PurchaseAnalyticsDedup(storage: _FakeLocalStorage());

      // 확실한 매출 누락보다 잠재적 중복이 낫다는 판단. 대신 경고를 남긴다.
      expect(await send(dedup, null), isTrue);
      expect(await send(dedup, null), isTrue);
    });

    test('저장소가 죽어도 같은 실행 안의 중복은 메모리가 막는다', () async {
      final storage = _FakeLocalStorage()
        ..failReads = true
        ..failWrites = true;
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      expect(await send(dedup, 'tx-1'), isTrue);
      expect(await send(dedup, 'tx-1'), isFalse);
    });

    test('동시에 두 번 호출해도 정확히 한 번만 통과한다', () async {
      // 발송 지점이 둘(검증 성공 경로 · 복구 스윕)이라 같은 키로 거의 동시에
      // 진입할 수 있다. 예약이 첫 await 뒤에 있으면 둘 다 키 없는 저장소를 읽고
      // 둘 다 통과한다 - purchase 가 두 번 나가고 그만큼 매출이 과대계상된다.
      final storage = _FakeLocalStorage();
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      final results = await Future.wait([
        dedup.reserve('tx-1'),
        dedup.reserve('tx-1'),
      ]);
      final winners = results.whereType<AnalyticsSendReservation>().toList();
      expect(winners, hasLength(1));

      await winners.single.commit();
      expect(
        _entries(storage.snapshot[PurchaseAnalyticsDedup.storageKey]),
        <List<String>>[
          <String>['tx-1'],
        ],
        reason: '경쟁에서 진 쪽이 같은 키를 한 번 더 적으면 안 된다',
      );
    });

    test('동시 호출이 여러 인스턴스에서 와도 한 번만 통과한다', () async {
      // 실제 경합의 모양: 스윕과 검증 성공 경로는 각자 AnalyticsService 를
      // 새로 만들므로 dedup 인스턴스도 서로 다르다. 방어선이 static 이어야
      // 하는 이유이기도 하다.
      final storage = _FakeLocalStorage();

      final results = await Future.wait([
        PurchaseAnalyticsDedup(storage: storage).reserve('tx-1'),
        PurchaseAnalyticsDedup(storage: storage).reserve('tx-1'),
        PurchaseAnalyticsDedup(storage: storage).reserve('tx-1'),
      ]);

      expect(results.whereType<AnalyticsSendReservation>(), hasLength(1));
    });

    test('저장소가 느려도 그 사이에 들어온 두 번째 호출이 통과하지 못한다', () async {
      // 경합의 실제 모양: 첫 호출이 저장소 왕복에서 양보해 있는 동안 두 번째
      // 호출이 진입한다. 예약이 첫 await 뒤에 있던 동안에는 둘 다 키 없는
      // 스냅샷을 읽고 둘 다 통과했다.
      final storage = _SlowLocalStorage(const Duration(milliseconds: 50));
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      final winner = dedup.reserve('tx-1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final loser = dedup.reserve('tx-1');

      final won = await winner;
      expect(won, isNotNull);
      expect(await loser, isNull);

      await won!.commit();
      expect(storage.writes, 1);
    });

    test('서로 다른 두 거래가 동시에 커밋해도 마커가 둘 다 남는다', () async {
      // A 와 B 는 서로 다른 키라 예약으로 서로를 막지 못한다. 갱신이
      // 직렬화되지 않으면 둘 다 같은 스냅샷을 읽고 마지막 쓰기가 이겨
      // 한쪽 마커가 사라진다 → 재시작 재전달 시 그 거래가 중복 발송된다.
      final storage = _SlowLocalStorage(const Duration(milliseconds: 20));
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      final a = await dedup.reserve('tx-a');
      final b = await dedup.reserve('tx-b');
      await Future.wait<bool>(<Future<bool>>[a!.commit(), b!.commit()]);

      PurchaseAnalyticsDedup.resetProcessCache();
      final afterRestart = PurchaseAnalyticsDedup(storage: storage);
      expect(await afterRestart.reserve('tx-a'), isNull);
      expect(await afterRestart.reserve('tx-b'), isNull);
    });

    test('전송에 실패하면(release) 다음 재전달에서 다시 보낸다', () async {
      // 이 dedup 은 단독 게이트다. "보내지 않았는데 보냈다고 기록"이 되면
      // 그 결제의 매출은 GA4 에서 영구히 사라진다.
      final storage = _FakeLocalStorage();
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      expect(await send(dedup, 'tx-1', delivered: false), isTrue);
      expect(storage.snapshot[PurchaseAnalyticsDedup.storageKey], isNull);

      // 프로세스가 죽고, 스토어 큐의 미완료 트랜잭션이 스윕으로 재검증된다.
      PurchaseAnalyticsDedup.resetProcessCache();
      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-1'),
        isTrue,
      );
    });

    test('거래 ID 로 보낸 뒤 같은 결제가 operation_id 만 들고 와도 막는다', () async {
      // 재전달 플래그를 발송 증거로 쓰지 않게 된 뒤로 이 dedup 이 단독
      // 게이트다. 한 실행에서는 거래 ID 로, 다른 실행에서는 operation_id 로
      // 해석되면 같은 결제가 두 번 나간다.
      final storage = _FakeLocalStorage();

      expect(
        await send(
          PurchaseAnalyticsDedup(storage: storage),
          'tx-1',
          fallbackKey: 'op-1',
        ),
        isTrue,
      );
      PurchaseAnalyticsDedup.resetProcessCache();
      expect(
        await send(
          PurchaseAnalyticsDedup(storage: storage),
          null,
          fallbackKey: 'op-1',
        ),
        isFalse,
      );
    });

    test('operation_id 로 보낸 뒤 같은 결제가 거래 ID 를 들고 와도 막는다', () async {
      final storage = _FakeLocalStorage();

      expect(
        await send(
          PurchaseAnalyticsDedup(storage: storage),
          null,
          fallbackKey: 'op-1',
        ),
        isTrue,
      );
      PurchaseAnalyticsDedup.resetProcessCache();
      expect(
        await send(
          PurchaseAnalyticsDedup(storage: storage),
          'tx-1',
          fallbackKey: 'op-1',
        ),
        isFalse,
      );
    });

    test('해석 키는 GA4 로 나가는 transaction_id 와 같은 규칙을 쓴다', () {
      expect(PurchaseAnalyticsDedup.resolvePrimaryKey('tx-1', 'op-1'), 'tx-1');
      expect(PurchaseAnalyticsDedup.resolvePrimaryKey(null, 'op-1'), 'op:op-1');
      expect(PurchaseAnalyticsDedup.resolvePrimaryKey('  ', 'op-1'), 'op:op-1');
      expect(PurchaseAnalyticsDedup.resolvePrimaryKey(null, null), isNull);
      expect(PurchaseAnalyticsDedup.resolvePrimaryKey('', '  '), isNull);
    });

    test('기록은 상한을 넘지 않고 오래된 것부터 밀려난다', () async {
      final storage = _FakeLocalStorage();
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      const overflow = PurchaseAnalyticsDedup.maxTrackedTransactions + 5;
      for (var i = 0; i < overflow; i++) {
        expect(await send(dedup, 'tx-$i'), isTrue);
      }

      final stored = _entries(
        storage.snapshot[PurchaseAnalyticsDedup.storageKey],
      );
      expect(stored, hasLength(PurchaseAnalyticsDedup.maxTrackedTransactions));
      expect(stored.first.single, 'tx-5');
      expect(stored.last.single, 'tx-${overflow - 1}');
    });

    test('상한은 별칭이 아니라 거래 단위로 센다', () async {
      // 별칭(거래 ID · op:operation_id)을 각각 세면 실효 추적 폭이 절반(50건)이
      // 되고, 밀려난 오래된 미완료 거래가 재전달될 때 다시 매출로 잡힌다.
      final storage = _FakeLocalStorage();
      final dedup = PurchaseAnalyticsDedup(storage: storage);

      const total = PurchaseAnalyticsDedup.maxTrackedTransactions;
      for (var i = 0; i < total; i++) {
        expect(await send(dedup, 'tx-$i', fallbackKey: 'op-$i'), isTrue);
      }

      final stored = _entries(
        storage.snapshot[PurchaseAnalyticsDedup.storageKey],
      );
      expect(stored, hasLength(total), reason: '거래 $total 건이 모두 남아야 한다');

      // 가장 오래된 거래도 여전히 차단된다 — 별칭 단위로 셌다면 밀려났을 것이다.
      PurchaseAnalyticsDedup.resetProcessCache();
      expect(
        await send(PurchaseAnalyticsDedup(storage: storage), 'tx-0'),
        isFalse,
      );
    });
  });

  group('AnalyticsService.logPurchaseEvent', () {
    late RecordingGa4Sink sink;

    setUp(() {
      sink = RecordingGa4Sink();
      PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: sink));
    });

    test('같은 거래가 다시 흘러도 purchase 는 한 번만 나간다', () async {
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: _FakeLocalStorage()),
      );

      for (var i = 0; i < 3; i++) {
        await service.logPurchaseEvent(
          _product('star200'),
          transactionId: 'tx-1',
          baseAmount: 200,
          bonusAmount: 25,
        );
      }

      expect(sink.purchases, hasLength(1));
    });

    test('legacy flat tx/op 마커가 있으면 outbox 이행 중 purchase를 재전송하지 않는다', () async {
      final storage = _FakeLocalStorage(
        seed: <String, String>{
          PurchaseAnalyticsDedup.storageKey: jsonEncode(<String>[
            'tx-old',
            'op:op-old',
          ]),
        },
      );
      final outbox = AnalyticsOutbox(storage: storage, sink: sink);
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
        outbox: outbox,
      );

      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-old',
        idempotencyFallbackKey: 'op-old',
        baseAmount: 200,
        bonusAmount: 25,
      );
      await outbox.flush();

      expect(sink.purchases, isEmpty);
      expect(
        _entries(storage.snapshot[PurchaseAnalyticsDedup.storageKey]),
        <List<String>>[
          <String>['tx-old', 'op:op-old'],
        ],
        reason: 'alias 별 용량 차감 없이 한 거래로 이관되어야 한다',
      );
    });

    test('전송이 실패하면 마커가 남지 않고 다음 재전달에서 다시 나간다', () async {
      // 이 시나리오가 blocker 였다: Firebase 미초기화/예외로 sink 가 조용히
      // no-op 했는데 마커는 이미 영속화돼 있어 그 결제가 영구히 차단됐다.
      final storage = _FakeLocalStorage();
      sink.deliver = false;

      await AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
      ).logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        baseAmount: 200,
        bonusAmount: 25,
      );

      expect(storage.snapshot[PurchaseAnalyticsDedup.storageKey], isNull);

      // 프로세스가 죽고 스윕이 같은 트랜잭션을 다시 검증에 태운다.
      PurchaseAnalyticsDedup.resetProcessCache();
      sink.deliver = true;
      await AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
      ).logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        baseAmount: 200,
        bonusAmount: 25,
      );

      expect(sink.purchases, hasLength(2));
      expect(sink.purchases.last.transactionId, 'tx-1');
    });

    test('전송이 시간 초과되면 예약이 풀려 다음 재전달에서 다시 나간다', () async {
      // Future.timeout 은 하위 future 를 취소하지 못한다. 예약 해제를 하지
      // 않으면 그 거래는 프로세스 수명 내내(그리고 마커를 먼저 남기던 시절에는
      // 영구히) 다시 시도조차 되지 않는다.
      final storage = _FakeLocalStorage();
      sink.sendDelay = const Duration(milliseconds: 200);

      await AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
      ).logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        baseAmount: 200,
        bonusAmount: 25,
        sendTimeout: const Duration(milliseconds: 10),
      );

      expect(storage.snapshot[PurchaseAnalyticsDedup.storageKey], isNull);

      sink.sendDelay = null;
      sink.clear();
      await AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
      ).logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        baseAmount: 200,
        bonusAmount: 25,
      );

      expect(
        sink.purchases,
        hasLength(1),
        reason: '타임아웃 후에는 같은 실행 안에서도 재시도할 수 있어야 한다',
      );
      expect(
        _entries(storage.snapshot[PurchaseAnalyticsDedup.storageKey]),
        <List<String>>[
          <String>['tx-1'],
        ],
      );
    });

    test('전송 성공 뒤에만 마커가 남는다', () async {
      final storage = _FakeLocalStorage();

      await AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: storage),
      ).logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        idempotencyFallbackKey: 'op-1',
        baseAmount: 200,
        bonusAmount: 25,
      );

      expect(
        _entries(storage.snapshot[PurchaseAnalyticsDedup.storageKey]),
        <List<String>>[
          <String>['tx-1', 'op:op-1'],
        ],
      );
    });

    test('스펙 §2-9 파라미터를 스펙 예시값 형태로 싣는다', () async {
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: _FakeLocalStorage()),
      );

      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        baseAmount: 200,
        bonusAmount: 25,
      );

      final purchase = sink.purchases.single;
      expect(purchase.transactionId, 'tx-1');
      expect(purchase.currency, 'USD');
      expect(purchase.value, 0.99);

      final item = purchase.items.single;
      expect(item.resolvedItemId, 'star200');
      expect(item.resolvedItemName, 'STAR200');
      expect(item.virtualCurrencyName, Ga4CurrencyNames.starCandy);
      expect(item.baseAmount, 200);
      expect(item.bonusAmount, 25);
    });

    test('거래 ID 가 없는 서로 다른 결제는 서로 다른 transaction_id 로 나간다', () async {
      // 예전에는 dedup 에만 operation_id 를 넘기고 GA4 에는 비어 있는
      // purchaseID 를 그대로 넘겼다. T2 레이어가 그것을 'undefined' 로 바꾸면
      // 서로 다른 결제 두 건이 GA4 에서 같은 거래가 되고, GA4 는
      // transaction_id 로 purchase 를 중복 제거하므로 두 번째 매출이 사라진다.
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: _FakeLocalStorage()),
      );

      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: null,
        idempotencyFallbackKey: 'op-1',
        baseAmount: 200,
        bonusAmount: 0,
      );
      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: '',
        idempotencyFallbackKey: 'op-2',
        baseAmount: 200,
        bonusAmount: 0,
      );

      expect(sink.purchases.map((p) => p.transactionId), [
        'op:op-1',
        'op:op-2',
      ]);
      expect(
        sink.purchases.map((p) => p.transactionId).toSet(),
        hasLength(2),
        reason: "'undefined' 로 뭉개지면 두 결제가 같은 거래로 집계된다",
      );
    });

    test('거래 ID 가 있으면 그것이 그대로 transaction_id 다', () async {
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: _FakeLocalStorage()),
      );

      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: 'tx-1',
        idempotencyFallbackKey: 'op-1',
        baseAmount: 200,
        bonusAmount: 0,
      );

      expect(sink.purchases.single.transactionId, 'tx-1');
    });

    test('거래 ID 와 operation_id 가 모두 없으면 아예 보내지 않는다', () async {
      // 매출 1건이 빠지는 것과 그 거래의 집계가 무너지는 것 사이의 선택이다.
      // 빠진 건은 서버 정산 기록으로 복원할 수 있지만 오염된 GA4 집계는
      // 되돌릴 수 없다.
      final service = AnalyticsService(
        dedup: PurchaseAnalyticsDedup(storage: _FakeLocalStorage()),
      );

      await service.logPurchaseEvent(
        _product('star200'),
        transactionId: null,
        idempotencyFallbackKey: null,
        baseAmount: 200,
        bonusAmount: 0,
      );

      expect(sink.purchases, isEmpty);
    });

    test('플랫폼별 상품 ID 가 달라도 같은 item_id/item_name 으로 정규화된다', () {
      // iOS 는 접두사가 붙은 대문자 SKU, Android 는 소문자 강제, dev 는 네임스페이스.
      expect(canonicalStoreProductId('STAR100'), 'STAR100');
      expect(canonicalStoreProductId('star100'), 'STAR100');
      expect(canonicalStoreProductId('io.picnic.STAR100'), 'STAR100');
      expect(canonicalStoreProductId('staging.star100'), 'STAR100');
    });
  });
}
