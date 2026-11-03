import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> clearStorage() async => data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      data[key] ?? defaultValue;

  @override
  Future<void> removeData(String key) async => data.remove(key);

  @override
  Future<void> saveData(String key, String value) async => data[key] = value;
}

class _SentPurchase {
  _SentPurchase(this.transactionId, this.currency, this.value);
  final String? transactionId;
  final String? currency;
  final num? value;
}

class _RecordingSink implements Ga4Sink {
  bool deliver = true;
  final List<_SentPurchase> purchases = <_SentPurchase>[];

  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) async =>
      deliver;

  @override
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) async {
    purchases.add(_SentPurchase(transactionId, currency, value));
    return deliver;
  }

  @override
  Future<bool> setUserId(String? id) async => true;

  @override
  Future<bool> setUserProperty(String name, String? value) async => true;
}

/// Store catalogue lookups the retry path makes while an event is deferred.
class _StubResolver implements PurchaseCurrencyResolver {
  _StubResolver([this.currency]);

  String? currency;
  bool hang = false;
  final List<String> calls = <String>[];

  @override
  Future<String?> resolve(String storeProductId) {
    calls.add(storeProductId);
    if (hang) return Completer<String?>().future;
    return Future<String?>.value(currency);
  }
}


/// resolver 가 답하기 전에 다른 일이 끼어들 수 있게 만드는 게이트.
class _GatedResolver implements PurchaseCurrencyResolver {
  _GatedResolver(this.currency);

  final String currency;
  final Completer<void> started = Completer<void>();
  final Completer<String?> _answer = Completer<String?>();

  void release() => _answer.complete(currency);

  @override
  Future<String?> resolve(String storeProductId) {
    if (!started.isCompleted) started.complete();
    return _answer.future;
  }
}

/// 시계를 주입하는 테스트가 공유하는 기준 시각.
final _fixtureNow = DateTime.utc(2026, 8, 24, 12);

/// 주입 시계. fixture 의 생성 시각과 만료 판정 시각을 같은 축에 올린다.
///
/// `clock` 만 주입하고 항목은 `DateTime.now()` 로 만들면 항목의 나이가
/// "주입한 시각 − 실제 실행 날짜"가 되어, retention 테스트가 실행 달력에
/// 종속된다(만료 테스트가 오늘은 통과하고 내년에는 실패하거나 그 반대).
/// 이 fixture 를 쓰는 테스트는 [now] 를 그대로 `createdAt` 으로 넘겨
/// 두 축을 일치시킨다.
class _TestClock {
  DateTime now = _fixtureNow;

  /// `AnalyticsOutbox(clock: ...)` 에 그대로 넘기는 읽기 함수.
  DateTime call() => now;

  void advance(Duration delta) => now = now.add(delta);
}

const _items = <Ga4PurchaseItem>[
  Ga4PurchaseItem(
    itemId: 'star100',
    itemName: 'STAR100',
    virtualCurrencyName: '스타캔디',
    baseAmount: 100,
    bonusAmount: 0,
  ),
];

void main() {
  setUp(AnalyticsOutbox.resetProcessStateForTest);
  tearDown(AnalyticsOutbox.resetProcessStateForTest);

  Future<PurchaseOutboxResult> enqueue(
    AnalyticsOutbox outbox, {
    String id = 'tx-1',
    String? serverCurrency,
    num? serverValue,
    String? catalogCurrency,
    num? catalogValue,
    String? clientObservedCurrency,
    String? storeProductId = 'star100',
    // 시계를 주입한 테스트는 반드시 같은 축의 시각을 넘긴다. 넘기지 않으면
    // 항목은 `DateTime.now()` 로 만들어져 나이 계산이 실행 날짜에 끌려간다.
    DateTime? createdAt,
  }) => outbox.enqueueOrMergePurchase(
    id: id,
    aliases: <String>[id, 'op:$id'],
    transactionId: id,
    items: _items,
    serverCurrency: serverCurrency,
    serverValue: serverValue,
    catalogCurrency: catalogCurrency,
    catalogValue: catalogValue,
    clientObservedCurrency: clientObservedCurrency,
    storeProductId: storeProductId,
    createdAt: createdAt,
  );

  group('§7 priority when the event is first stored', () {
    test('the server currency wins over a catalogue that disagrees', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      expect(
        await enqueue(
          outbox,
          serverCurrency: 'USD',
          serverValue: 1.99,
          catalogCurrency: 'KRW',
          catalogValue: 2500,
        ),
        PurchaseOutboxResult.ready,
      );
      await outbox.flush();

      expect(sink.purchases.single.currency, 'USD');
      expect(sink.purchases.single.value, 1.99);
    });

    test('an empty catalogue no longer costs the revenue figure', () async {
      // §4 의 문제 그 자체: 카탈로그가 비어 있어도 서버 값이 있으면 매출이 남는다.
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, serverCurrency: 'KRW', serverValue: 2500);
      await outbox.flush();

      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 2500);
    });

    test('a server currency with no value never borrows the catalogue price', () async {
      // Google 폴백은 통화만 확보한다. 카탈로그 금액을 끌어다 붙이면
      // 서버가 확정한 통화와 다른 통화 기준의 금액이 섞인다(§7-1).
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      expect(
        await enqueue(
          outbox,
          serverCurrency: 'KRW',
          catalogCurrency: 'USD',
          catalogValue: 1.99,
        ),
        PurchaseOutboxResult.ready,
      );
      await outbox.flush();

      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, isNull, reason: 'B-3: value 키만 생략');
    });

    test('with no server currency the catalogue pair is used, as today', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, catalogCurrency: 'KRW', catalogValue: 2500);
      await outbox.flush();

      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 2500);
    });

    test('the client-observed currency is the last resort, currency only', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, clientObservedCurrency: 'jpy');
      await outbox.flush();

      expect(sink.purchases.single.currency, 'JPY');
      expect(sink.purchases.single.value, isNull);
    });

    test('a currency that is not ISO 4217 is treated as no currency', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      expect(
        await enqueue(outbox, serverCurrency: 'ja', serverValue: 1.99),
        PurchaseOutboxResult.deferred,
      );
      await outbox.flush();

      expect(sink.purchases, isEmpty);
    });
  });

  group('§7.2 awaiting_currency', () {
    test('value without currency is deferred and never reaches the sink', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      expect(
        await enqueue(outbox, serverValue: 1.99),
        PurchaseOutboxResult.deferred,
      );
      await outbox.flush();

      expect(sink.purchases, isEmpty, reason: 'B-2: sink 호출 0회');
      expect(await outbox.pendingCount(), 1);
      expect(await outbox.awaitingCurrencyCount(), 1);
    });

    test('a resolved currency sends the candidate value exactly once', () async {
      final sink = _RecordingSink();
      final resolver = _StubResolver();
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        currencyResolver: resolver,
        clock: clock.call,
      );

      await enqueue(outbox, serverValue: 1.99, createdAt: clock.now);
      await outbox.flush();
      expect(sink.purchases, isEmpty);
      expect(resolver.calls, <String>['star100']);

      resolver.currency = 'USD';
      clock.advance(const Duration(minutes: 1));
      await outbox.flush();

      expect(sink.purchases, hasLength(1));
      expect(sink.purchases.single.currency, 'USD');
      expect(sink.purchases.single.value, 1.99);
      expect(await outbox.pendingCount(), 0);

      await outbox.flush();
      expect(sink.purchases, hasLength(1), reason: '재전송 없음');
    });

    test('resolver failures persist attempts and back off, capped at 5 minutes', () async {
      final storage = _MemoryStorage();
      final resolver = _StubResolver();
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
        currencyResolver: resolver,
        clock: clock.call,
      );

      await enqueue(outbox, serverValue: 1.99, createdAt: clock.now);
      await outbox.flush();
      expect(resolver.calls, hasLength(1));

      // 백오프가 지나기 전에는 resolver 를 다시 부르지 않는다.
      clock.advance(const Duration(seconds: 29));
      await outbox.flush();
      expect(resolver.calls, hasLength(1));

      clock.advance(const Duration(seconds: 2));
      await outbox.flush();
      expect(resolver.calls, hasLength(2));

      // 지수 백오프는 5분에서 멈춘다.
      for (var i = 0; i < 10; i++) {
        clock.advance(const Duration(minutes: 6));
        await outbox.flush();
      }
      final attempts = await outbox.awaitingCurrencyAttempts('tx-1');
      expect(attempts, 12);
      expect(
        await outbox.currencyRetryDelayFor('tx-1'),
        const Duration(minutes: 5),
      );
    });

    test('the deferred state and its attempts survive a restart', () async {
      final storage = _MemoryStorage();
      final clock = _TestClock();
      final first = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
        currencyResolver: _StubResolver(),
        clock: clock.call,
      );
      await enqueue(first, serverValue: 1.99, createdAt: clock.now);
      await first.flush();

      AnalyticsOutbox.resetProcessStateForTest();
      clock.advance(const Duration(minutes: 10));
      final sink = _RecordingSink();
      final restarted = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        currencyResolver: _StubResolver('KRW'),
        clock: clock.call,
      );

      expect(await restarted.awaitingCurrencyAttempts('tx-1'), 1);
      await restarted.flush();
      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 1.99);
    });

    test('a hung resolver does not block the rest of the drain', () async {
      final sink = _RecordingSink();
      final resolver = _StubResolver()..hang = true;
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        currencyResolver: resolver,
        currencyResolveTimeout: const Duration(milliseconds: 10),
      );

      await enqueue(outbox, id: 'tx-hung', serverValue: 1.99);
      await enqueue(outbox, id: 'tx-ok', serverCurrency: 'KRW', serverValue: 1);
      await outbox.flush();

      expect(sink.purchases.map((p) => p.transactionId), <String>['tx-ok']);
      expect(await outbox.awaitingCurrencyCount(), 1);
    });
  });

  group('alias merge', () {
    test('a later delivery with a currency upgrades the deferred entry', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, serverValue: 1.99);
      expect(await outbox.pendingCount(), 1);

      // 같은 거래의 재전달: alias 가 겹치므로 새 항목을 만들지 않는다.
      expect(
        await enqueue(outbox, serverCurrency: 'USD', serverValue: 1.99),
        PurchaseOutboxResult.ready,
      );
      expect(await outbox.pendingCount(), 1);
      expect(await outbox.awaitingCurrencyCount(), 0);

      await outbox.flush();
      expect(sink.purchases, hasLength(1));
      expect(sink.purchases.single.currency, 'USD');
    });

    test('an already delivered transaction is not re-enqueued', () async {
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, serverCurrency: 'USD', serverValue: 1.99);
      await outbox.flush();
      expect(sink.purchases, hasLength(1));

      expect(
        await enqueue(outbox, serverCurrency: 'USD', serverValue: 1.99),
        PurchaseOutboxResult.ready,
      );
      await outbox.flush();
      expect(sink.purchases, hasLength(1));
    });
  });

  group('교차 리뷰 회귀', () {
    test('보류 중 서버가 통화만 주면 예전 candidate 금액을 붙이지 않는다', () async {
      // 서버가 통화만 준 정상 케이스(Google 폴백)에서 보류 중 모아 둔
      // 카탈로그 금액을 그 통화 옆에 붙이면, 서로 다른 출처의 통화와 금액이
      // 한 쌍이 되어 조작된 매출이 만들어진다.
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: _MemoryStorage(), sink: sink);

      await enqueue(outbox, catalogValue: 2500);
      expect(await outbox.awaitingCurrencyCount(), 1);

      await enqueue(outbox, serverCurrency: 'USD');
      await outbox.flush();

      expect(sink.purchases.single.currency, 'USD');
      expect(sink.purchases.single.value, isNull);
    });

    test('resolver 가 늦게 끝나도 서버가 확정한 통화를 덮어쓰지 않는다', () async {
      // resolver 를 await 하는 동안 같은 거래의 재전달이 서버 통화로 승격한다.
      final sink = _RecordingSink();
      final resolver = _GatedResolver('KRW');
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        currencyResolver: resolver,
      );

      await enqueue(outbox, serverValue: 1.99);
      final draining = outbox.flush();
      await resolver.started.future;

      // resolver 가 아직 답하지 않은 사이 서버 응답이 도착한다.
      await enqueue(outbox, serverCurrency: 'USD', serverValue: 1.99);
      resolver.release();
      await draining;
      await outbox.flush();

      expect(sink.purchases, hasLength(1));
      expect(sink.purchases.single.currency, 'USD');
      expect(sink.purchases.single.value, 1.99);
    });

    test('저장된 통화의 철자가 아니라 정규화한 값을 보낸다', () async {
      final storage = _MemoryStorage();
      await storage.saveData(
        AnalyticsOutbox.storageKey,
        jsonEncode(<String, Object?>{
          'version': 2,
          'pending': <Object?>[
            <String, Object?>{
              'kind': 'purchase',
              'id': 'tx-lower',
              'aliases': <String>['tx-lower'],
              'payload': <String, Object?>{
                'transaction_id': 'tx-lower',
                'items': <Object?>[],
                'currency': ' krw ',
                'value': 2500,
              },
              'user_id': null,
              'created_at': _fixtureNow.toIso8601String(),
              'delivery_confirmed': false,
              'delivery_state': 'ready',
            },
          ],
          'delivered': <Object?>[],
          'dead_letters': <Object?>[],
        }),
      );

      final sink = _RecordingSink();
      // 시계를 fixture 의 created_at 에 고정한다. 실제 시각을 쓰면 항목의
      // 나이가 실행 날짜에 따라 커져 언젠가 만료 제거로 바뀐다.
      await AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: _TestClock().call,
      ).flush();

      expect(sink.purchases.single.currency, 'KRW');
    });
  });

  group('storage v1 → v2 migration', () {
    // 마이그레이션 대상은 "며칠 전에 저장된" 항목이다. 아래 테스트들은 시계를
    // [_fixtureNow] 에 고정하므로 이 나이는 실행 날짜와 무관하게 4일이다.
    final v1CreatedAt = _fixtureNow.subtract(const Duration(days: 4));

    Future<void> seedV1(_MemoryStorage storage, Map<String, Object?> payload) {
      final entry = <String, Object?>{
        'kind': 'purchase',
        'id': 'tx-old',
        'aliases': <String>['tx-old'],
        'payload': payload,
        'user_id': null,
        'created_at': v1CreatedAt.toIso8601String(),
        'delivery_confirmed': false,
      };
      return storage.saveData(
        AnalyticsOutbox.storageKey,
        jsonEncode(<String, Object?>{
          'version': 1,
          'pending': <Object?>[entry],
          'delivered': <Object?>[],
        }),
      );
    }

    Map<String, Object?> payloadWith({String? currency, num? value}) =>
        <String, Object?>{
          'transaction_id': 'tx-old',
          'items': <Object?>[
            <String, Object?>{
              'item_id': 'star100',
              'item_name': 'STAR100',
              'virtual_currency_name': '스타캔디',
              'base_amount': 100,
              'bonus_amount': 0,
            },
          ],
          // null-aware element: 값이 null 이면 그 키 자체가 빠진다 —
          // `if (x != null) k: x` 와 동일하다(use_null_aware_elements).
          'currency': ?currency,
          'value': ?value,
        };

    test('a v1 purchase that already has a currency stays sendable', () async {
      final storage = _MemoryStorage();
      await seedV1(storage, payloadWith(currency: 'KRW', value: 2500));
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: _TestClock().call,
      );

      await outbox.flush();
      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 2500);
    });

    test('a v1 purchase without a currency migrates to awaiting, not to a send', () async {
      final storage = _MemoryStorage();
      await seedV1(storage, payloadWith(value: 2500));
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: _TestClock().call,
      );

      expect(await outbox.awaitingCurrencyCount(), 1);
      await outbox.flush();
      expect(sink.purchases, isEmpty, reason: '과거 항목도 통화 없이는 보내지 않는다');
      expect(await outbox.pendingCount(), 1);
    });

    test('the migrated candidate value is not lost', () async {
      // v1 항목에는 store_product_id 가 없다. item_name 의 canonical 상품 ID 로
      // 재조회해 되살린다.
      final storage = _MemoryStorage();
      await seedV1(storage, payloadWith(value: 2500));
      final sink = _RecordingSink();
      final resolver = _StubResolver('KRW');
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        currencyResolver: resolver,
        clock: _TestClock().call,
      );

      await outbox.flush();
      expect(resolver.calls, <String>['STAR100']);
      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 2500);
    });

    test('v2 state round-trips through storage', () async {
      final storage = _MemoryStorage();
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
      );
      await enqueue(outbox, serverValue: 1.99);

      final stored =
          jsonDecode(storage.data[AnalyticsOutbox.storageKey]!) as Map;
      expect(stored['version'], 2);

      final reloaded = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
      );
      expect(await reloaded.awaitingCurrencyCount(), 1);
    });
  });

  group('dead letter', () {
    const maxAge = Duration(days: 365);

    test('a purchase at the retention boundary is preserved, not summarised', () async {
      // 만료는 나이가 상한을 "넘었을 때"다(`> maxAge`). 상한 정각에 지우면 아직
      // 통화를 되찾을 수 있는 매출이 하루 일찍 요약으로 떨어진다.
      final sink = _RecordingSink();
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        clock: clock.call,
        purchasePendingMaxAge: maxAge,
      );

      await enqueue(outbox, serverValue: 1.99, createdAt: clock.now);
      clock.advance(maxAge);
      await outbox.flush();

      expect(
        await outbox.pendingCount(),
        1,
        reason: '상한 정각은 아직 만료가 아니다',
      );
      expect(await outbox.awaitingCurrencyCount(), 1);
      expect(await outbox.deadLetters(), isEmpty);
      expect(sink.purchases, isEmpty);
    });

    test('expiry ends in a bounded summary, never in a currency-less send', () async {
      final sink = _RecordingSink();
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        clock: clock.call,
        purchasePendingMaxAge: maxAge,
      );

      // 나이는 오직 주입 시계 위에서만 잰다. `createdAt` 을 실제 시각으로 두면
      // "상한을 1ms 넘긴 시점"이 실행 날짜에 따라 만료가 되기도 안 되기도 한다.
      await enqueue(outbox, serverValue: 1.99, createdAt: clock.now);
      // 만료 전에 한 번 돌려 재조회 실패를 쌓아 둔다 — 요약은 그 이력을 담아야
      // "왜 이 거래의 매출이 없는가"에 답할 수 있다.
      await outbox.flush();
      expect(await outbox.awaitingCurrencyAttempts('tx-1'), 1);

      clock.advance(maxAge + const Duration(milliseconds: 1));
      await outbox.flush();

      expect(sink.purchases, isEmpty, reason: '만료돼도 통화 없이 보내지 않는다');
      expect(await outbox.pendingCount(), 0);

      final letters = await outbox.deadLetters();
      expect(letters, hasLength(1));
      expect(letters.single.id, 'tx-1');
      expect(letters.single.aliases, contains('op:tx-1'));
      expect(letters.single.reason, PurchaseCurrencyError.catalogUnavailable.name);
      expect(letters.single.attempts, 1);
      expect(letters.single.expiredAt, clock.now);
      // 영수증/payload 는 dead letter 에 남기지 않는다. 키 집합을 통째로 고정해
      // 나중에 payload 성 필드가 슬쩍 끼어드는 것까지 막는다.
      expect(letters.single.toJson().keys.toSet(), <String>{
        'id',
        'aliases',
        'attempts',
        'reason',
        'expired_at',
      });
    });

    test('the summary list is bounded and keeps the newest entries', () async {
      // "bounded" 의 실제 계약: 상한을 넘으면 가장 오래된 요약부터 버린다.
      // 상한이 없으면 만료가 몰린 계정에서 요약이 저장소를 무한정 먹는다.
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: _RecordingSink(),
        clock: clock.call,
        purchasePendingMaxAge: maxAge,
        maxDeadLetters: 2,
      );

      for (final id in <String>['tx-a', 'tx-b', 'tx-c']) {
        await enqueue(outbox, id: id, serverValue: 1.99, createdAt: clock.now);
      }
      clock.advance(maxAge + const Duration(milliseconds: 1));
      await outbox.flush();

      expect(await outbox.pendingCount(), 0);
      expect(
        (await outbox.deadLetters()).map((letter) => letter.id),
        <String>['tx-b', 'tx-c'],
      );
    });

    test('a delivered purchase never becomes a dead letter', () async {
      final sink = _RecordingSink();
      final clock = _TestClock();
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        // 보류 상한만 짧게 잡고 delivered 마커 보존기간(기본 180일)은 그대로
        // 둔다. 예전처럼 366일을 흘려보내면 마커 자체가 만료돼 사라지므로,
        // "전달된 건은 요약 대상이 아니다"가 아니라 "아무것도 남지 않았다"를
        // 확인하는 셈이 된다.
        purchasePendingMaxAge: const Duration(days: 1),
        clock: clock.call,
      );

      await enqueue(
        outbox,
        serverCurrency: 'KRW',
        serverValue: 2500,
        createdAt: clock.now,
      );
      // 같은 flush 가 실제로 만료 처리해야 할 항목을 하나 함께 둔다. 만료 경로가
      // 돌았다는 증거가 있어야 "전달된 건만 살아남았다"가 의미를 갖는다.
      await enqueue(
        outbox,
        id: 'tx-stuck',
        serverValue: 1.99,
        createdAt: clock.now,
      );
      await outbox.flush();
      expect(sink.purchases.map((p) => p.transactionId), <String>['tx-1']);

      clock.advance(const Duration(days: 2));
      await outbox.flush();

      expect(
        (await outbox.deadLetters()).map((letter) => letter.id),
        <String>['tx-stuck'],
        reason: '전달된 거래는 만료 경로가 돌아도 요약 대상이 아니다',
      );
      expect(sink.purchases, hasLength(1), reason: '재전송 없음');
    });
  });

  group('sink-time gate', () {
    test('a stored entry whose currency is not ISO 4217 is not dispatched', () async {
      // 저장 시점 이후 어떤 경로로든 payload 가 오염돼도 마지막 방어선이 잡는다.
      final storage = _MemoryStorage();
      final entry = <String, Object?>{
        'kind': 'purchase',
        'id': 'tx-bad',
        'aliases': <String>['tx-bad'],
        'payload': <String, Object?>{
          'transaction_id': 'tx-bad',
          'items': <Object?>[],
          'currency': 'ja',
          'value': 1.99,
        },
        'user_id': null,
        'created_at': _fixtureNow.toIso8601String(),
        'delivery_confirmed': false,
        'delivery_state': 'ready',
      };
      await storage.saveData(
        AnalyticsOutbox.storageKey,
        jsonEncode(<String, Object?>{
          'version': 2,
          'pending': <Object?>[entry],
          'delivered': <Object?>[],
          'dead_letters': <Object?>[],
        }),
      );

      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: _TestClock().call,
      );
      await outbox.flush();

      expect(sink.purchases, isEmpty);
      expect(await outbox.awaitingCurrencyCount(), 1);
    });
  });
}
