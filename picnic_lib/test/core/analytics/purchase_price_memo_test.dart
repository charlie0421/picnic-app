import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/purchase_price_memo.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

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

const userA = 'user-a';
const userB = 'user-b';

void main() {
  late _FakeStorage storage;
  late PurchasePriceMemo memo;

  setUp(() {
    PurchasePriceMemo.resetProcessStateForTest();
    storage = _FakeStorage();
    memo = PurchasePriceMemo(storage: storage);
  });

  List<dynamic> storedEntries() {
    final raw = storage.data[PurchasePriceMemo.storageKey];
    if (raw == null) return const [];
    return (jsonDecode(raw) as Map<String, dynamic>)['entries'] as List;
  }

  void seed(List<Map<String, Object>> entries) {
    storage.data[PurchasePriceMemo.storageKey] =
        jsonEncode({'version': 2, 'entries': entries});
  }

  Map<String, Object> entry({
    String id = 'star100',
    String user = userA,
    String currency = 'USD',
    num value = 0.99,
    required DateTime at,
  }) =>
      {
        'id': id,
        'user': user,
        'currency': currency,
        'value': value,
        'at': at.millisecondsSinceEpoch,
      };

  group('기본 동작', () {
    test('결제 시점 기록을 거래 시각으로 지목해 가져온다', () async {
      await memo.record(
        storeProductId: 'star100',
        userId: userA,
        currency: 'USD',
        value: 0.99,
      );

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: DateTime.now(),
      );

      expect(found!.currency, 'USD');
      expect(found.value, 0.99);
    });

    test('가져간 기록은 소비된다 — 다른 거래가 다시 집어가지 못한다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);

      await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: DateTime.now(),
      );

      expect(
        await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ),
        isNull,
      );
      expect(storedEntries(), isEmpty);
    });
  });

  group('틀린 금액이 들어가지 않는다', () {
    test('다른 사용자의 기록은 집어가지 않는다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userB,
        transactionAt: DateTime.now(),
      );

      expect(found, isNull, reason: 'A 의 USD 0.99 가 B 의 매출이 되면 안 된다');
    });

    test('취소된 시도의 잔재보다 거래 직전 시도를 고른다', () async {
      final now = DateTime.now();
      seed([
        // 어제 취소된 시도 (당시 가격)
        entry(at: now.subtract(const Duration(days: 1)), value: 0.99),
        // 오늘 실제 결제한 시도 (인상된 가격)
        entry(at: now.subtract(const Duration(seconds: 5)), value: 1.99),
      ]);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: now,
      );

      expect(found!.value, 1.99);
    });

    test('거래 이후에 남은 기록은 이 거래의 것이 아니다', () async {
      final txAt = DateTime.now().subtract(const Duration(days: 2));
      seed([entry(at: DateTime.now(), value: 5.99)]);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: txAt,
      );

      expect(found, isNull);
    });

    test('거래 시각을 모르고 후보가 여럿이면 금액을 생략한다', () async {
      final now = DateTime.now();
      seed([
        entry(at: now.subtract(const Duration(hours: 2)), value: 0.99),
        entry(at: now.subtract(const Duration(hours: 1)), value: 1.99),
      ]);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: null,
      );

      expect(found, isNull, reason: '추측한 숫자를 매출로 올리지 않는다');
    });

    test('거래 시각을 몰라도 후보가 하나면 인정한다', () async {
      seed([entry(at: DateTime.now().subtract(const Duration(hours: 1)))]);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: null,
      );

      expect(found!.value, 0.99);
    });

    test('다른 상품의 기록은 집어가지 않는다', () async {
      await memo.record(
          storeProductId: 'star600',
          userId: userA,
          currency: 'USD',
          value: 5.99);

      expect(
        await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ),
        isNull,
      );
    });

    test('만료된 기록은 쓰지 않는다 — 그 사이 가격이 바뀌었을 수 있다', () async {
      final stale = DateTime.now()
          .subtract(PurchasePriceMemo.maxAge + const Duration(days: 1));
      seed([entry(at: stale)]);

      expect(
        await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ),
        isNull,
      );
    });
  });

  group('기록하지 않는 입력', () {
    test('userId 가 없으면 기록하지 않는다 — 나중에 지목할 수 없다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: null,
          currency: 'USD',
          value: 0.99);
      expect(storage.saveCount, 0);
    });

    test('ISO 4217 형식이 아닌 통화는 기록하지 않는다', () async {
      for (final bad in ['US', 'USDD', '', 'US1']) {
        await memo.record(
            storeProductId: 'star100',
            userId: userA,
            currency: bad,
            value: 0.99);
      }
      expect(storage.saveCount, 0,
          reason: 'GA4 는 ISO 4217 이 아니면 그 매출을 통째로 무시한다');
    });

    test('음수·무한대 금액은 기록하지 않는다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: -1);
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: double.infinity);
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: double.nan);
      expect(storage.saveCount, 0);
    });
  });

  group('손상 내성', () {
    test('epoch 범위를 벗어난 at 은 그 항목만 버린다 — poison blob 이 되면 안 된다',
        () async {
      seed([
        {
          'id': 'star100',
          'user': userA,
          'currency': 'USD',
          'value': 0.99,
          'at': 9223372036854775807,
        },
        entry(id: 'star600', value: 5.99, at: DateTime.now()),
      ]);

      // 손상 항목이 전체 조회를 막지 않는다.
      final found = await memo.takeFor(
        storeProductId: 'star600',
        userId: userA,
        transactionAt: DateTime.now(),
      );
      expect(found!.value, 5.99);

      // 이후 기록도 정상 동작한다.
      await memo.record(
          storeProductId: 'star200',
          userId: userA,
          currency: 'USD',
          value: 1.99);
      expect(
        (await memo.takeFor(
          storeProductId: 'star200',
          userId: userA,
          transactionAt: DateTime.now(),
        ))!
            .value,
        1.99,
      );
    });

    test('미래에 기록됐다는 항목은 버린다 — 만료 방어를 통과하면 안 된다', () async {
      seed([entry(at: DateTime.now().add(const Duration(days: 2)))]);

      expect(
        await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ),
        isNull,
      );
    });

    test('손상 항목이 섞여도 멀쩡한 항목은 살아남는다', () async {
      seed([
        {'id': 'broken'},
        entry(at: DateTime.now()),
      ]);

      expect(
        (await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ))!
            .value,
        0.99,
      );
    });

    test('JSON 이 아니면 빈 상태로 시작하고 이후 기록은 정상 동작한다', () async {
      storage.data[PurchasePriceMemo.storageKey] = 'garbage';

      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);

      expect(
        (await memo.takeFor(
          storeProductId: 'star100',
          userId: userA,
          transactionAt: DateTime.now(),
        ))!
            .value,
        0.99,
      );
    });

    test('읽기 실패는 빈 상태로 축약하지 않는다 — 멀쩡한 기록을 덮어쓰면 안 된다',
        () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);
      final before = storage.data[PurchasePriceMemo.storageKey];

      storage.failLoad = true;
      await memo.record(
          storeProductId: 'star600',
          userId: userA,
          currency: 'USD',
          value: 5.99);

      expect(storage.data[PurchasePriceMemo.storageKey], before,
          reason: '읽기 실패 뒤 저장이 기존 기록을 덮어쓰면 안 된다');
    });
  });

  group('동시성', () {
    test('서로 다른 상품을 동시에 기록해도 서로를 지우지 않는다', () async {
      await Future.wait([
        memo.record(
            storeProductId: 'star100',
            userId: userA,
            currency: 'USD',
            value: 0.99),
        memo.record(
            storeProductId: 'star600',
            userId: userA,
            currency: 'USD',
            value: 5.99),
        memo.record(
            storeProductId: 'star200',
            userId: userA,
            currency: 'USD',
            value: 1.99),
      ]);

      expect(storedEntries().length, 3,
          reason: 'mutex 없이 read-modify-write 하면 마지막 저장만 남는다');
    });

    test('같은 기록을 동시에 가져가면 정확히 하나만 성공한다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);

      final results = await Future.wait([
        memo.takeFor(
            storeProductId: 'star100',
            userId: userA,
            transactionAt: DateTime.now()),
        memo.takeFor(
            storeProductId: 'star100',
            userId: userA,
            transactionAt: DateTime.now()),
      ]);

      expect(results.where((r) => r != null).length, 1);
    });
  });

  group('예산·실패가 발송을 막지 않는다', () {
    test('예산이 이미 없으면 즉시 포기한다', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);

      final found = await memo.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: DateTime.now(),
        budget: Duration.zero,
      );

      expect(found, isNull);
    });

    test('예산이 ioTimeout 보다 짧으면 예산이 이긴다', () async {
      final slow = _FakeStorage()..hangFor = const Duration(seconds: 5);
      final bounded = PurchasePriceMemo(
        storage: slow,
        ioTimeout: const Duration(seconds: 3),
      );

      final sw = Stopwatch()..start();
      final found = await bounded.takeFor(
        storeProductId: 'star100',
        userId: userA,
        transactionAt: DateTime.now(),
        budget: const Duration(milliseconds: 50),
      );
      sw.stop();

      expect(found, isNull);
      expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('저장 실패는 throw 하지 않는다', () async {
      storage.failSave = true;
      await expectLater(
        memo.record(
            storeProductId: 'star100',
            userId: userA,
            currency: 'USD',
            value: 0.99),
        completes,
      );
    });

    test('조회 실패는 null 을 돌려준다 — 금액 없이 발송하는 동작', () async {
      await memo.record(
          storeProductId: 'star100',
          userId: userA,
          currency: 'USD',
          value: 0.99);
      storage.failLoad = true;

      expect(
        await memo.takeFor(
            storeProductId: 'star100',
            userId: userA,
            transactionAt: DateTime.now()),
        isNull,
      );
    });
  });

  group('용량', () {
    test('maxEntries 를 넘으면 오래된 것부터 밀어낸다', () async {
      final now = DateTime.now();
      seed([
        for (var i = 0; i <= PurchasePriceMemo.maxEntries; i++)
          entry(
            id: 'product_$i',
            value: i.toDouble(),
            at: now.subtract(Duration(minutes: 1000 - i)),
          ),
      ]);

      // 저장을 한 번 유발한다.
      await memo.record(
          storeProductId: 'trigger',
          userId: userA,
          currency: 'USD',
          value: 1);

      expect(storedEntries().length, PurchasePriceMemo.maxEntries);
      expect(
        await memo.takeFor(
            storeProductId: 'product_0',
            userId: userA,
            transactionAt: now),
        isNull,
      );
    });
  });
}
