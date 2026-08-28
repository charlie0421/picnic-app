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
      var now = DateTime.utc(2026, 8, 24, 12);
      final outbox = AnalyticsOutbox(
        storage: _MemoryStorage(),
        sink: sink,
        currencyResolver: resolver,
        clock: () => now,
      );

      await enqueue(outbox, serverValue: 1.99);
      await outbox.flush();
      expect(sink.purchases, isEmpty);
      expect(resolver.calls, <String>['star100']);

      resolver.currency = 'USD';
      now = now.add(const Duration(minutes: 1));
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
      var now = DateTime.utc(2026, 8, 24, 12);
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
        currencyResolver: resolver,
        clock: () => now,
      );

      await enqueue(outbox, serverValue: 1.99);
      await outbox.flush();
      expect(resolver.calls, hasLength(1));

      // 백오프가 지나기 전에는 resolver 를 다시 부르지 않는다.
      now = now.add(const Duration(seconds: 29));
      await outbox.flush();
      expect(resolver.calls, hasLength(1));

      now = now.add(const Duration(seconds: 2));
      await outbox.flush();
      expect(resolver.calls, hasLength(2));

      // 지수 백오프는 5분에서 멈춘다.
      for (var i = 0; i < 10; i++) {
        now = now.add(const Duration(minutes: 6));
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
      var now = DateTime.utc(2026, 8, 24, 12);
      final first = AnalyticsOutbox(
        storage: storage,
        sink: _RecordingSink(),
        currencyResolver: _StubResolver(),
        clock: () => now,
      );
      await enqueue(first, serverValue: 1.99);
      await first.flush();

      AnalyticsOutbox.resetProcessStateForTest();
      now = now.add(const Duration(minutes: 10));
      final sink = _RecordingSink();
      final restarted = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        currencyResolver: _StubResolver('KRW'),
        clock: () => now,
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
              'created_at': DateTime.utc(2026, 8, 24).toIso8601String(),
              'delivery_confirmed': false,
              'delivery_state': 'ready',
            },
          ],
          'delivered': <Object?>[],
          'dead_letters': <Object?>[],
        }),
      );

      final sink = _RecordingSink();
      await AnalyticsOutbox(storage: storage, sink: sink).flush();

      expect(sink.purchases.single.currency, 'KRW');
    });
  });

  group('storage v1 → v2 migration', () {
    Future<void> seedV1(_MemoryStorage storage, Map<String, Object?> payload) {
      final entry = <String, Object?>{
        'kind': 'purchase',
        'id': 'tx-old',
        'aliases': <String>['tx-old'],
        'payload': payload,
        'user_id': null,
        'created_at': DateTime.utc(2026, 8, 20).toIso8601String(),
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
          if (currency != null) 'currency': currency,
          if (value != null) 'value': value,
        };

    test('a v1 purchase that already has a currency stays sendable', () async {
      final storage = _MemoryStorage();
      await seedV1(storage, payloadWith(currency: 'KRW', value: 2500));
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: storage, sink: sink);

      await outbox.flush();
      expect(sink.purchases.single.currency, 'KRW');
      expect(sink.purchases.single.value, 2500);
    });

    test('a v1 purchase without a currency migrates to awaiting, not to a send', () async {
      final storage = _MemoryStorage();
      await seedV1(storage, payloadWith(value: 2500));
      final sink = _RecordingSink();
      final outbox = AnalyticsOutbox(storage: storage, sink: sink);

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
    test('expiry ends in a bounded summary, never in a currency-less send', () async {
      final storage = _MemoryStorage();
      final sink = _RecordingSink();
      var now = DateTime.utc(2026, 8, 24, 12);
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: () => now,
        purchasePendingMaxAge: const Duration(days: 365),
      );

      await enqueue(outbox, serverValue: 1.99);
      now = now.add(const Duration(days: 366));
      await outbox.flush();

      expect(sink.purchases, isEmpty, reason: '만료돼도 통화 없이 보내지 않는다');
      expect(await outbox.pendingCount(), 0);

      final letters = await outbox.deadLetters();
      expect(letters, hasLength(1));
      expect(letters.single.id, 'tx-1');
      expect(letters.single.aliases, contains('op:tx-1'));
      expect(letters.single.reason, isNotEmpty);
      // 영수증/payload 는 dead letter 에 남기지 않는다.
      expect(letters.single.toJson().containsKey('payload'), isFalse);
    });

    test('a delivered purchase never becomes a dead letter', () async {
      final storage = _MemoryStorage();
      final sink = _RecordingSink();
      var now = DateTime.utc(2026, 8, 24, 12);
      final outbox = AnalyticsOutbox(
        storage: storage,
        sink: sink,
        clock: () => now,
      );

      await enqueue(outbox, serverCurrency: 'KRW', serverValue: 2500);
      await outbox.flush();
      now = now.add(const Duration(days: 366));
      await outbox.flush();

      expect(await outbox.deadLetters(), isEmpty);
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
        'created_at': DateTime.utc(2026, 8, 24).toIso8601String(),
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
      final outbox = AnalyticsOutbox(storage: storage, sink: sink);
      await outbox.flush();

      expect(sink.purchases, isEmpty);
      expect(await outbox.awaitingCurrencyCount(), 1);
    });
  });
}
