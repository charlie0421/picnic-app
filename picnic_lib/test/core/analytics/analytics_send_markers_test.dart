import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({Map<String, String>? seed})
    : data = <String, String>{...?seed};

  final Map<String, String> data;

  int writes = 0;
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
    writes++;
    if (failSave) throw StateError('save down');
    data[key] = value;
  }
}

const String _key = 'test_send_markers';

AnalyticsSendMarkerStore _store(LocalStorage storage, {int max = 100}) =>
    AnalyticsSendMarkerStore(
      storageKey: _key,
      maxTrackedEntries: max,
      storage: storage,
    );

List<List<String>> _decode(String? raw) => <List<String>>[
  for (final entry in jsonDecode(raw!) as List<dynamic>)
    <String>[for (final key in entry as List<dynamic>) key as String],
];

void main() {
  setUp(AnalyticsSendMarkerStore.resetProcessCacheForTest);
  tearDown(AnalyticsSendMarkerStore.resetProcessCacheForTest);

  group('예약과 마커의 분리', () {
    test('전송 성공을 commit 하기 전에는 영속 마커가 남지 않는다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage);

      final reservation = await store.reserve(<String>['tx-1']);

      expect(reservation, isNotNull);
      expect(storage.data[_key], isNull, reason: '보내기 전에 마커를 남기면 안 된다');

      expect(await reservation!.commit(), isTrue);
      expect(_decode(storage.data[_key]), <List<String>>[
        <String>['tx-1'],
      ]);
    });

    test('release 하면 같은 키가 다시 예약된다 — 전송 실패가 영구 차단이 되면 안 된다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage);

      final first = await store.reserve(<String>['tx-1']);
      expect(first, isNotNull);
      first!.release();

      final retry = await store.reserve(<String>['tx-1']);
      expect(retry, isNotNull, reason: '전송하지 않았으므로 다시 시도할 수 있어야 한다');
      expect(storage.data[_key], isNull);
    });

    test('release 뒤 프로세스가 죽어도 다음 실행이 다시 보낸다', () async {
      final storage = _FakeLocalStorage();

      final reservation = await _store(storage).reserve(<String>['tx-1']);
      reservation!.release();

      // 프로세스 재시작: 메모리 상태는 사라지고 저장소만 남는다.
      AnalyticsSendMarkerStore.resetProcessCacheForTest();

      expect(await _store(storage).reserve(<String>['tx-1']), isNotNull);
    });

    test('commit 뒤에는 인스턴스가 달라도, 재시작해도 막힌다', () async {
      final storage = _FakeLocalStorage();

      final reservation = await _store(storage).reserve(<String>['tx-1']);
      await reservation!.commit();

      expect(await _store(storage).reserve(<String>['tx-1']), isNull);

      AnalyticsSendMarkerStore.resetProcessCacheForTest();
      expect(await _store(storage).reserve(<String>['tx-1']), isNull);
    });

    test('예약이 진행 중인 동안에는 같은 키의 두 번째 예약이 거부된다', () async {
      final storage = _FakeLocalStorage()
        ..latency = const Duration(milliseconds: 30);
      final store = _store(storage);

      final first = store.reserve(<String>['tx-1']);
      final second = store.reserve(<String>['tx-1']);

      expect(await first, isNotNull);
      expect(await second, isNull);
    });

    test('키가 없으면 마커를 남기지 않는 예약을 준다 (확실한 누락 < 잠재적 중복)', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage);

      final a = await store.reserve(const <String>[]);
      expect(a, isNotNull);
      expect(await a!.commit(), isTrue);
      expect(storage.data[_key], isNull);

      expect(await store.reserve(const <String>[]), isNotNull);
    });
  });

  group('저장 실패를 삼키지 않는다', () {
    test('마커 저장이 실패하면 commit 이 false 를 돌려준다', () async {
      final storage = _FakeLocalStorage()..failSave = true;
      final store = _store(storage);

      final reservation = await store.reserve(<String>['tx-1']);

      expect(await reservation!.commit(), isFalse);
    });

    test('마커 저장 실패는 같은 실행 안의 중복까지 풀지는 않는다', () async {
      // 이미 보냈다는 사실은 참이다. 메모리 마커는 유지해야 곧바로 두 번째가
      // 나가지 않는다. 재시작 후에만 한 번 더 나갈 수 있다.
      final storage = _FakeLocalStorage()..failSave = true;
      final store = _store(storage);

      final reservation = await store.reserve(<String>['tx-1']);
      await reservation!.commit();

      expect(await store.reserve(<String>['tx-1']), isNull);
    });

    test('기존 목록을 읽지 못하면 덮어쓰지 않는다 — 마커 전체가 날아가면 대량 중복이다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage);

      await (await store.reserve(<String>['tx-old']))!.commit();
      final before = storage.data[_key];

      storage.failLoad = true;
      final reservation = await store.reserve(<String>['tx-new']);
      expect(await reservation!.commit(), isFalse);

      expect(storage.data[_key], before, reason: 'tx-old 마커가 사라지면 안 된다');
    });

    test('읽기가 실패하면 발송을 막지 않는다', () async {
      final storage = _FakeLocalStorage()..failLoad = true;

      expect(await _store(storage).reserve(<String>['tx-1']), isNotNull);
    });
  });

  group('서로 다른 키의 동시 갱신 (lost update)', () {
    test('두 거래가 동시에 commit 해도 마커가 둘 다 남는다', () async {
      // A 와 B 는 서로 다른 키라 in-flight 예약으로 서로를 막지 못한다.
      // 직렬화가 없으면 둘 다 같은 스냅샷을 읽고 각자 자기 것만 덧붙여 저장해
      // 마지막 쓰기가 이긴다 — 진 쪽의 마커가 사라지고 재시작 후 중복이 난다.
      final storage = _FakeLocalStorage()
        ..latency = const Duration(milliseconds: 20);
      final store = _store(storage);

      final a = await store.reserve(<String>['tx-a']);
      final b = await store.reserve(<String>['tx-b']);

      await Future.wait<bool>(<Future<bool>>[a!.commit(), b!.commit()]);

      final stored = _decode(storage.data[_key]).expand((g) => g).toSet();
      expect(stored, <String>{'tx-a', 'tx-b'});
    });

    test('여러 인스턴스에서 동시에 commit 해도 마커가 모두 남는다', () async {
      // EarnAnalyticsStore 는 AdRewardDialogHost 마다, PurchaseAnalyticsDedup 은
      // 호출부마다 새로 생긴다. 락이 인스턴스 필드면 서로를 전혀 막지 못한다.
      final storage = _FakeLocalStorage()
        ..latency = const Duration(milliseconds: 10);
      final keys = <String>['k1', 'k2', 'k3', 'k4', 'k5'];

      final reservations = <AnalyticsSendReservation>[];
      for (final key in keys) {
        final reservation = await _store(storage).reserve(<String>[key]);
        reservations.add(reservation!);
      }
      await Future.wait<bool>(reservations.map((r) => r.commit()));

      final stored = _decode(storage.data[_key]).expand((g) => g).toSet();
      expect(stored, keys.toSet());
    });

    test('재시작 후에도 동시 commit 한 두 거래가 모두 차단된다', () async {
      final storage = _FakeLocalStorage()
        ..latency = const Duration(milliseconds: 20);
      final store = _store(storage);

      final a = await store.reserve(<String>['tx-a']);
      final b = await store.reserve(<String>['tx-b']);
      await Future.wait<bool>(<Future<bool>>[a!.commit(), b!.commit()]);

      AnalyticsSendMarkerStore.resetProcessCacheForTest();

      expect(await _store(storage).reserve(<String>['tx-a']), isNull);
      expect(await _store(storage).reserve(<String>['tx-b']), isNull);
    });
  });

  group('용량 정책', () {
    test('상한은 별칭이 아니라 항목(거래) 단위로 센다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage, max: 4);

      // 별칭 2개짜리 항목만 넣는다. 별칭을 각각 세면 실효 추적 폭이 절반이 된다.
      for (var i = 0; i < 4; i++) {
        final reservation = await store.reserve(<String>['tx-$i', 'op:op-$i']);
        await reservation!.commit();
      }

      final groups = _decode(storage.data[_key]);
      expect(groups, hasLength(4), reason: '항목 4건이 그대로 남아야 한다');

      AnalyticsSendMarkerStore.resetProcessCacheForTest();
      for (var i = 0; i < 4; i++) {
        expect(
          await _store(storage, max: 4).reserve(<String>['tx-$i']),
          isNull,
        );
      }
    });

    test('상한을 넘으면 오래된 항목부터 밀려난다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage, max: 3);

      for (var i = 0; i < 5; i++) {
        final reservation = await store.reserve(<String>['tx-$i']);
        await reservation!.commit();
      }

      expect(_decode(storage.data[_key]), <List<String>>[
        <String>['tx-2'],
        <String>['tx-3'],
        <String>['tx-4'],
      ]);
    });
  });

  group('저장 포맷 호환', () {
    test('예전 문자열 배열 포맷의 마커도 계속 막는다', () async {
      final storage = _FakeLocalStorage(
        seed: <String, String>{
          _key: jsonEncode(<String>['tx-old']),
        },
      );

      expect(await _store(storage).reserve(<String>['tx-old']), isNull);
    });

    test('legacy tx/op alias를 한 거래 그룹으로 원자적 이관한다', () async {
      final storage = _FakeLocalStorage(
        seed: <String, String>{
          _key: jsonEncode(<String>['tx-old', 'op:op-old']),
        },
      );

      expect(
        await _store(storage).reserve(<String>['tx-old', 'op:op-old']),
        isNull,
      );

      expect(_decode(storage.data[_key]), <List<String>>[
        <String>['tx-old', 'op:op-old'],
      ]);
    });

    test('예전 콤마 문자열 포맷의 마커도 계속 막는다', () async {
      final storage = _FakeLocalStorage(
        seed: <String, String>{_key: 'tx-old,tx-older'},
      );

      expect(await _store(storage).reserve(<String>['tx-old']), isNull);
      expect(await _store(storage).reserve(<String>['tx-older']), isNull);
      expect(await _store(storage).reserve(<String>['tx-new']), isNotNull);
    });

    test('별칭 중 하나만 기록돼 있어도 막는다', () async {
      final storage = _FakeLocalStorage();
      final store = _store(storage);

      await (await store.reserve(<String>['tx-1', 'op:op-1']))!.commit();
      AnalyticsSendMarkerStore.resetProcessCacheForTest();

      expect(await _store(storage).reserve(<String>['op:op-1']), isNull);
    });

    test('깨진 값은 빈 목록으로 시작한다', () async {
      final storage = _FakeLocalStorage(
        seed: <String, String>{_key: '{"a":1}'},
      );
      final store = _store(storage);

      final reservation = await store.reserve(<String>['tx-1']);
      expect(reservation, isNotNull);
      await reservation!.commit();

      AnalyticsSendMarkerStore.resetProcessCacheForTest();
      expect(await _store(storage).reserve(<String>['tx-1']), isNull);
    });
  });
}
