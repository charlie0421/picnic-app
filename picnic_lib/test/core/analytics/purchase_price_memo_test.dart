import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/purchase_price_memo.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// 메모리 저장소. 실패·지연을 주입해 결제/발송이 막히지 않는지 확인한다.
class _FakeStorage implements LocalStorage {
  final Map<String, String> data = <String, String>{};

  bool failLoad = false;
  bool failSave = false;
  Duration? hangFor;
  int saveCount = 0;

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    if (hangFor != null) await Future<void>.delayed(hangFor!);
    if (failLoad) throw StateError('load failed');
    return data[key] ?? defaultValue;
  }

  @override
  Future<void> saveData(String key, String value) async {
    if (hangFor != null) await Future<void>.delayed(hangFor!);
    if (failSave) throw StateError('save failed');
    saveCount++;
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStorage storage;
  late PurchasePriceMemo memo;

  setUp(() {
    storage = _FakeStorage();
    memo = PurchasePriceMemo(storage: storage);
  });

  group('record → lookup', () {
    test('결제 시점에 기록한 통화·금액을 그대로 돌려준다', () async {
      await memo.record(
        storeProductId: 'star100',
        currency: 'USD',
        value: 0.99,
      );

      final found = await memo.lookup('star100');

      expect(found, isNotNull);
      expect(found!.currency, 'USD');
      expect(found.value, 0.99);
    });

    test('기록이 없는 상품은 null 이다 — 금액 없이 발송되는 현재 동작', () async {
      expect(await memo.lookup('star999'), isNull);
    });

    test('같은 상품을 다시 결제하면 최신 가격으로 갱신된다', () async {
      await memo.record(
          storeProductId: 'star100', currency: 'USD', value: 0.99);
      await memo.record(
          storeProductId: 'star100', currency: 'KRW', value: 1500);

      final found = await memo.lookup('star100');

      expect(found!.currency, 'KRW');
      expect(found.value, 1500);

      // 갱신이지 누적이 아니다.
      final entries =
          (jsonDecode(storage.data[PurchasePriceMemo.storageKey]!)
              as Map<String, dynamic>)['entries'] as List;
      expect(entries.length, 1);
    });

    test('여러 상품을 독립적으로 기록한다', () async {
      await memo.record(
          storeProductId: 'star100', currency: 'USD', value: 0.99);
      await memo.record(
          storeProductId: 'star600', currency: 'USD', value: 5.99);

      expect((await memo.lookup('star100'))!.value, 0.99);
      expect((await memo.lookup('star600'))!.value, 5.99);
    });
  });

  group('기록하지 않는 경우', () {
    test('통화나 금액이 없으면 기록하지 않는다 — 어차피 발송 시 생략된다', () async {
      await memo.record(
          storeProductId: 'star100', currency: null, value: 0.99);
      await memo.record(storeProductId: 'star100', currency: 'USD', value: null);
      await memo.record(storeProductId: 'star100', currency: '', value: 0.99);

      expect(storage.saveCount, 0);
      expect(await memo.lookup('star100'), isNull);
    });

    test('상품 ID 가 비면 기록하지 않는다', () async {
      await memo.record(storeProductId: '', currency: 'USD', value: 0.99);
      expect(storage.saveCount, 0);
    });
  });

  group('만료', () {
    test('maxAge 를 넘긴 기록은 무시한다 — 그 사이 가격이 바뀌었을 수 있다', () async {
      final stale = DateTime.now().subtract(
        PurchasePriceMemo.maxAge + const Duration(days: 1),
      );
      storage.data[PurchasePriceMemo.storageKey] = jsonEncode({
        'version': 1,
        'entries': [
          {
            'id': 'star100',
            'currency': 'USD',
            'value': 0.99,
            'at': stale.millisecondsSinceEpoch,
          }
        ],
      });

      expect(await memo.lookup('star100'), isNull);
    });

    test('maxAge 이내면 유효하다', () async {
      final recent = DateTime.now().subtract(const Duration(days: 3));
      storage.data[PurchasePriceMemo.storageKey] = jsonEncode({
        'version': 1,
        'entries': [
          {
            'id': 'star100',
            'currency': 'USD',
            'value': 0.99,
            'at': recent.millisecondsSinceEpoch,
          }
        ],
      });

      expect((await memo.lookup('star100'))!.value, 0.99);
    });
  });

  group('용량', () {
    test('maxEntries 를 넘으면 오래된 것부터 밀어낸다', () async {
      for (var i = 0; i <= PurchasePriceMemo.maxEntries; i++) {
        await memo.record(
          storeProductId: 'product_$i',
          currency: 'USD',
          value: i.toDouble(),
        );
      }

      // 가장 먼저 넣은 것이 밀려나고, 마지막 것은 남는다.
      expect(await memo.lookup('product_0'), isNull);
      expect(
        (await memo.lookup('product_${PurchasePriceMemo.maxEntries}'))!.value,
        PurchasePriceMemo.maxEntries.toDouble(),
      );
    });
  });

  group('실패해도 결제·발송을 막지 않는다', () {
    test('저장 실패는 throw 하지 않는다', () async {
      storage.failSave = true;

      await expectLater(
        memo.record(storeProductId: 'star100', currency: 'USD', value: 0.99),
        completes,
      );
    });

    test('조회 실패는 null 을 돌려준다 — 금액 없이 발송하는 현재 동작', () async {
      await memo.record(
          storeProductId: 'star100', currency: 'USD', value: 0.99);
      storage.failLoad = true;

      expect(await memo.lookup('star100'), isNull);
    });

    test('I/O 가 늘어져도 ioTimeout 안에 풀린다 — 정산 예산을 잡아먹지 않는다',
        () async {
      final slow = _FakeStorage()..hangFor = const Duration(seconds: 5);
      final bounded = PurchasePriceMemo(
        storage: slow,
        ioTimeout: const Duration(milliseconds: 50),
      );

      final sw = Stopwatch()..start();
      final found = await bounded.lookup('star100');
      sw.stop();

      expect(found, isNull);
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('손상된 저장 내용이 있어도 나머지 기록을 잃지 않는다', () async {
      storage.data[PurchasePriceMemo.storageKey] = jsonEncode({
        'version': 1,
        'entries': [
          {'id': 'broken'},
          'not-a-map',
          {
            'id': 'star100',
            'currency': 'USD',
            'value': 0.99,
            'at': DateTime.now().millisecondsSinceEpoch,
          },
        ],
      });

      expect((await memo.lookup('star100'))!.value, 0.99);
    });

    test('저장 내용이 JSON 이 아니면 빈 상태로 시작한다', () async {
      storage.data[PurchasePriceMemo.storageKey] = 'garbage';
      expect(await memo.lookup('star100'), isNull);

      // 이후 기록은 정상 동작해야 한다.
      await memo.record(
          storeProductId: 'star100', currency: 'USD', value: 0.99);
      expect((await memo.lookup('star100'))!.value, 0.99);
    });
  });
}
