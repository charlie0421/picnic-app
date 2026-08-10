import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

class _InMemoryLocalStorage implements LocalStorage {
  _InMemoryLocalStorage();

  final Map<String, String> data = <String, String>{};
  bool failLoad = false;
  bool failSave = false;
  Duration? latency;

  @override
  Future<void> clearStorage() async => data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    final wait = latency;
    if (wait != null) await Future<void>.delayed(wait);
    if (failLoad) throw StateError('load down');
    return data[key] ?? defaultValue;
  }

  @override
  Future<void> removeData(String key) async => data.remove(key);

  @override
  Future<void> saveData(String key, String value) async {
    final wait = latency;
    if (wait != null) await Future<void>.delayed(wait);
    if (failSave) throw StateError('save down');
    data[key] = value;
  }
}

List<String> _storedKeys(String? raw) => <String>[
      for (final entry in jsonDecode(raw!) as List<dynamic>)
        ...<String>[for (final key in entry as List<dynamic>) key as String],
    ];

void main() {
  late _InMemoryLocalStorage storage;
  late EarnAnalyticsStore store;

  setUp(() {
    EarnAnalyticsStore.resetProcessCacheForTest();
    storage = _InMemoryLocalStorage();
    store = EarnAnalyticsStore(storage: storage);
  });
  tearDown(EarnAnalyticsStore.resetProcessCacheForTest);

  Future<bool> send(EarnAnalyticsStore target, String key,
      {bool delivered = true}) async {
    final reservation = await target.reserve(key);
    if (reservation == null) return false;
    if (delivered) {
      await reservation.commit();
    } else {
      reservation.release();
    }
    return true;
  }

  test('같은 키는 처음 한 번만 예약된다', () async {
    expect(await send(store, 'u1:pangle_claim:r1'), isTrue);
    expect(await send(store, 'u1:pangle_claim:r1'), isFalse);
    expect(await send(store, 'u1:pangle_claim:r1'), isFalse);
  });

  test('다른 키는 서로 막지 않는다', () async {
    expect(await send(store, 'u1:pangle_claim:r1'), isTrue);
    expect(await send(store, 'u1:pangle_claim:r2'), isTrue);
    expect(await send(store, 'u2:pangle_claim:r1'), isTrue);
  });

  test('저장소를 공유하는 새 인스턴스도 마커를 본다 (앱 재시작 시나리오)', () async {
    expect(await send(store, 'u1:internal_impression:r1'), isTrue);

    // 앱 재시작 = 새 위젯/새 스토어 인스턴스 + 빈 메모리, 같은 영속 저장소.
    EarnAnalyticsStore.resetProcessCacheForTest();
    final afterRestart = EarnAnalyticsStore(storage: storage);
    expect(await send(afterRestart, 'u1:internal_impression:r1'), isFalse);
  });

  test('전송에 실패하면(release) 다음 시도에서 다시 보낸다 — 영구 누락이 없다', () async {
    expect(await send(store, 'u1:pangle_claim:r1', delivered: false), isTrue);
    expect(storage.data[EarnAnalyticsStore.loggedKeysKey], isNull,
        reason: '보내지 않았으면 마커도 없어야 한다');

    // 프로세스가 죽고 다음 실행에서 같은 reference 가 재큐잉된다.
    EarnAnalyticsStore.resetProcessCacheForTest();
    expect(
      await send(EarnAnalyticsStore(storage: storage), 'u1:pangle_claim:r1'),
      isTrue,
    );
  });

  test('Host 인스턴스가 둘이어도 같은 적립을 한 번만 보낸다', () async {
    // 위젯 재삽입/중첩 네비게이터로 AdRewardDialogHost 가 두 개 살아 있을 수
    // 있다. 방어선이 인스턴스 필드면 서로를 전혀 막지 못한다.
    storage.latency = const Duration(milliseconds: 20);
    final hostA = EarnAnalyticsStore(storage: storage);
    final hostB = EarnAnalyticsStore(storage: storage);

    final results = await Future.wait<Object?>(<Future<Object?>>[
      hostA.reserve('u1:pangle_claim:r1'),
      hostB.reserve('u1:pangle_claim:r1'),
    ]);

    expect(results.whereType<Object>(), hasLength(1));
  });

  test('Host 두 개가 서로 다른 적립을 동시에 커밋해도 마커가 둘 다 남는다', () async {
    storage.latency = const Duration(milliseconds: 20);
    final hostA = EarnAnalyticsStore(storage: storage);
    final hostB = EarnAnalyticsStore(storage: storage);

    final a = await hostA.reserve('u1:pangle_claim:r1');
    final b = await hostB.reserve('u1:pangle_claim:r2');
    await Future.wait<bool>(<Future<bool>>[a!.commit(), b!.commit()]);

    expect(
      _storedKeys(storage.data[EarnAnalyticsStore.loggedKeysKey]).toSet(),
      <String>{'u1:pangle_claim:r1', 'u1:pangle_claim:r2'},
    );
  });

  test('구분자가 들어간 reference id 도 안전하게 구분된다', () async {
    expect(await send(store, 'u1:pangle_claim:a,b'), isTrue);
    expect(await send(store, 'u1:pangle_claim:a'), isTrue);
    expect(await send(store, 'u1:pangle_claim:a,b'), isFalse);
    expect(await send(store, 'u1:pangle_claim:a'), isFalse);
  });

  test('상한을 넘으면 오래된 것부터 버린다', () async {
    for (var i = 0; i < EarnAnalyticsStore.maxTrackedKeys + 5; i++) {
      expect(await send(store, 'k$i'), isTrue);
    }

    final stored = _storedKeys(storage.data[EarnAnalyticsStore.loggedKeysKey]);
    expect(stored.length, EarnAnalyticsStore.maxTrackedKeys);
    expect(stored.last, 'k${EarnAnalyticsStore.maxTrackedKeys + 4}');
  });

  test('읽기가 실패하면 발송을 막지 않는다 (누락 < 중복)', () async {
    storage.failLoad = true;

    expect(await send(store, 'u1:pangle_claim:r1'), isTrue);
  });

  test('쓰기가 실패해도 이번 발송은 진행되고 commit 이 실패를 알린다', () async {
    storage.failSave = true;

    final reservation = await store.reserve('u1:pangle_claim:r1');
    expect(reservation, isNotNull);
    expect(await reservation!.commit(), isFalse);
  });

  test('저장값이 깨져 있어도 던지지 않는다', () async {
    storage.data[EarnAnalyticsStore.loggedKeysKey] = 'not json {{{';

    expect(await send(store, 'u1:pangle_claim:r1'), isTrue);
    expect(await send(store, 'u1:pangle_claim:r1'), isFalse);
  });

  test('JSON 이지만 배열이 아니면 빈 목록으로 취급한다', () async {
    storage.data[EarnAnalyticsStore.loggedKeysKey] = '{"a":1}';

    expect(await send(store, 'u1:pangle_claim:r1'), isTrue);
    expect(await send(store, 'u1:pangle_claim:r1'), isFalse);
  });
}
