import 'dart:async';
import 'dart:convert';

import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// 저장소 키 단위의 **전역** 직렬화기.
///
/// 왜 필요한가: 마커 갱신은 read-modify-write 다. 서로 **다른 키**로 들어온 두
/// 발송(A 거래 · B 거래)은 in-flight 예약으로 서로를 막지 못하므로 둘 다
/// 갱신 구간에 들어온다. 그러면 둘 다 같은 스냅샷을 읽고 각자 자기 항목만
/// 덧붙여 저장해 마지막 쓰기가 이긴다 — 한쪽 마커가 사라지고, 재시작 후 그
/// 거래가 다시 흘러오면 중복 발송된다.
///
/// 락 범위를 인스턴스가 아니라 **저장소 키**로 잡은 이유: 방어 대상 클래스들은
/// 호출부마다 새로 생성되거나(`PurchaseAnalyticsDedup`) 위젯마다 존재한다
/// (`EarnAnalyticsStore` — `AdRewardDialogHost` 가 2개 떠 있을 수 있다).
/// 인스턴스 필드 락은 그 경우 서로를 전혀 막지 못한다.
class AnalyticsMarkerMutex {
  AnalyticsMarkerMutex._();

  /// 키별 직렬화 체인의 꼬리. 항상 **성공으로 수렴**시킨다 — 한 번의 실패가
  /// 이후 모든 마커 갱신을 영구히 막으면 그것이 곧 대량 중복이다.
  static final Map<String, Future<void>> _tails = <String, Future<void>>{};

  static Future<T> runExclusive<T>(
    String lockKey,
    Future<T> Function() action,
  ) {
    final previous = _tails[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _tails[lockKey] = gate.future;
    return previous.then((_) => action()).whenComplete(gate.complete);
  }

  /// 테스트 전용. 프로덕션 코드에서 호출하지 않는다 — 각 저장소 래퍼가
  /// 자기 이름의 `@visibleForTesting` 훅으로 감싸 노출한다.
  static void resetForTest() => _tails.clear();
}

/// "이 발송을 지금부터 내가 책임진다"는 예약.
///
/// [AnalyticsSendMarkerStore.reserve] 가 돌려준다. 호출부는 **sink 가 실제
/// 성공을 반환한 뒤에만** [commit] 하고, 실패/타임아웃에는 [release] 한다.
class AnalyticsSendReservation {
  AnalyticsSendReservation._(this._owner, this.keys);

  final AnalyticsSendMarkerStore _owner;

  /// 이 발송을 가리키는 모든 별칭 키. 비어 있으면 중복 방어가 불가능한
  /// 경로(식별 키가 아예 없음)라 아무것도 기록하지 않는다.
  final List<String> keys;

  bool _settled = false;
  Future<bool>? _commitResult;

  /// 전송이 **실제로 성공한 뒤에만** 호출한다. 영속화 성공 여부를 반환한다.
  ///
  /// 이미 [release] 된 예약에 대한 커밋은 `false` 다 — 예약을 놓은 뒤에 남기는
  /// 마커는 다른 시도가 진행 중일 수 있어 근거가 없다.
  Future<bool> commit() {
    final existing = _commitResult;
    if (existing != null) return existing;
    if (_settled) return Future<bool>.value(false);
    _settled = true;
    return _commitResult = _owner._commit(keys);
  }

  /// 전송이 실패하거나 시간 초과됐을 때 호출한다. 예약만 풀고 마커는 남기지
  /// 않으므로 다음 재전달이 같은 거래를 다시 시도할 수 있다.
  void release() {
    if (_settled) return;
    _settled = true;
    _owner._release(keys);
  }
}

/// "이미 GA4 로 보낸 건"을 영속 기록하는 공통 저장소.
///
/// ## in-flight 예약과 sent 마커의 분리
///
/// 예전 구현은 `markIfFirst` 하나가 "예약"과 "보냈다는 마커 영속화"를 **전송
/// 전에** 함께 끝냈다. 그런데 sink 는 Firebase 미초기화 환경에서 조용히
/// no-op 했고 예외도 삼켰으므로 **실패해도 성공처럼 보였다.** 결합하면:
/// 정산 성공 → 마커 저장 성공 → Firebase 가 없거나 throw 하거나 무한 지연 →
/// 프로세스 종료 → 다음 재전달에서 '이미 보낸 거래'로 차단 → **매출 영구 누락.**
///
/// 그래서 상태를 셋으로 나눈다.
///   - **in-flight** (메모리): 지금 누군가 보내는 중. 같은 프로세스의 동시
///     진입만 막는다. 영속되지 않으므로 프로세스가 죽으면 사라진다 — 죽은
///     시도가 다음 실행을 영구히 막지 못한다는 뜻이고, 이것이 핵심이다.
///   - **sent** (메모리 미러): 이 프로세스에서 전송 성공을 확인했다.
///   - **sent** (영속): 전송 성공을 확인한 뒤에만 기록한다.
///
/// ## 매출 누락 vs 중복 — 어느 쪽을 택했는가
///
/// **중복을 택한다.** 근거:
///   1. GA4 는 `purchase` 를 `transaction_id` 로 중복 제거한다. 같은 거래 ID 로
///      두 번 들어간 구매는 매출을 두 배로 만들지 않는다. 반대로 한 번도
///      보내지 않은 구매는 GA4 안에서 복원할 방법이 없다.
///   2. 누락은 "보냈다고 잘못 기록"으로 **영구**해지지만, 중복은 재전달 창
///      (스토어 큐 · 복구 스윕)이 열려 있는 짧은 구간에서만 생긴다.
///   3. 남는 중복 위험은 딱 하나다 — 전송은 성공했는데 마커 영속화가 실패한
///      경우. 그때도 메모리 sent 마커가 같은 실행 안의 중복은 막고, 재시작
///      후에만 한 번 더 나갈 수 있다. [commit] 이 false 를 돌려주므로 호출부가
///      이 사실을 로그로 드러낸다.
///
/// 이 정책은 purchase legacy 마커에만 적용한다. GA4 중복 제거가 없는
/// `earn_virtual_currency` / `login` / `sign_up`은 `AnalyticsOutbox`에서
/// sink 성공 checkpoint를 cleanup보다 먼저 저장해, 확인된 성공 뒤의 cleanup
/// 실패가 재전송으로 이어지지 않게 한다.
///
/// ## 용량 정책은 **항목(=발송 건) 단위**다
///
/// 저장 포맷은 "한 발송의 별칭 묶음"의 배열이다 (`[["tx1","op:a"],["tx2"]]`).
/// 예전처럼 별칭을 각각 세면 별칭이 2개인 결제에서 실효 추적 폭이 절반으로
/// 줄고, 밀려난 오래된 미완료 거래가 다시 매출로 잡힌다.
class AnalyticsSendMarkerStore {
  AnalyticsSendMarkerStore({
    required this.storageKey,
    required this.maxTrackedEntries,
    LocalStorage? storage,
    this.ioTimeout = const Duration(seconds: 2),
  }) : _storage = storage;

  final String storageKey;
  final int maxTrackedEntries;
  final LocalStorage? _storage;
  final Duration ioTimeout;

  LocalStorage get _s => _storage ?? globalStorage;

  /// 프로세스 전역 상태. 저장소 키로 묶어 **인스턴스가 여럿이어도** 같은
  /// 방어선을 공유한다.
  static final Map<String, Set<String>> _sentInProcess =
      <String, Set<String>>{};
  static final Map<String, Set<String>> _inFlight = <String, Set<String>>{};

  Set<String> get _sent =>
      _sentInProcess.putIfAbsent(storageKey, () => <String>{});

  Set<String> get _pending =>
      _inFlight.putIfAbsent(storageKey, () => <String>{});

  /// 테스트 전용(앱 재시작 흉내). 프로덕션 코드에서 호출하지 않는다.
  static void resetProcessCacheForTest() {
    _sentInProcess.clear();
    _inFlight.clear();
    AnalyticsMarkerMutex.resetForTest();
  }

  /// 보내도 되면 예약을, 보내면 안 되면 `null` 을 돌려준다.
  ///
  /// **동기 구간이 방어의 전부다.** in-flight 등록이 첫 `await` 뒤에 있으면 두
  /// 호출이 같은 "키 없는" 스냅샷을 읽고 둘 다 예약을 얻는다. 진입부터
  /// 등록까지가 통째로 동기 블록이어야 이벤트 루프가 끼어들 틈이 없다.
  Future<AnalyticsSendReservation?> reserve(List<String> keys) {
    if (keys.isEmpty) {
      // 중복 방어가 불가능한 경로. 마커를 남기지 않는 예약을 준다 — 발송은
      // 막지 않되(확실한 누락 < 잠재적 중복) 기록도 하지 않는다.
      return Future<AnalyticsSendReservation?>.value(
        AnalyticsSendReservation._(this, const <String>[]),
      );
    }

    final sent = _sent;
    final pending = _pending;
    for (final key in keys) {
      if (sent.contains(key)) {
        logger.i('analytics 중복 발송 차단(메모리, 전송 확인됨) [$storageKey]: $key');
        return Future<AnalyticsSendReservation?>.value(null);
      }
      if (pending.contains(key)) {
        logger.i('analytics 중복 발송 차단(전송 진행 중) [$storageKey]: $key');
        return Future<AnalyticsSendReservation?>.value(null);
      }
    }
    pending.addAll(keys);

    return _reserveAfterStorageCheck(keys).catchError((Object error) {
      // load/판정 코드가 예상 밖으로 던져도 동기 예약은 반드시 해제한다.
      // 그렇지 않으면 같은 키의 모든 후속 reserve가 프로세스 수명 동안 막힌다.
      pending.removeAll(keys);
      throw error;
    });
  }

  /// 이 키들이 **이미 전송 확인된** 것인지. 진행 중(in-flight)은 포함하지 않는다.
  ///
  /// [reserve] 의 `null` 은 "이미 보냄"과 "다른 시도가 진행 중"을 구분하지
  /// 않는다. 두 경우의 후속 처리는 정반대다 — 전자는 더 할 일이 없고, 후자는
  /// 그 시도가 실패했을 때 복구 재료를 남겨 둬야 한다. 그 구분이 필요한
  /// 호출부만 이 질문을 따로 한다.
  Future<bool> isKnownSent(List<String> keys) async {
    if (keys.isEmpty) return false;
    if (keys.any(_sent.contains)) return true;
    final groups = await _readGroups();
    // 읽기 실패(null)는 "이미 보냈음을 증명할 수 없다"이므로 false 다.
    return groups != null && _containsAny(groups, keys);
  }

  Future<AnalyticsSendReservation?> _reserveAfterStorageCheck(
    List<String> keys,
  ) async {
    final groups = await _readGroups();
    // 읽기 실패(null)는 "이미 보냈음을 증명할 수 없다"이므로 발송한다.
    if (groups != null && _containsAny(groups, keys)) {
      // legacy flat 포맷에서는 tx와 op alias가 별도 "거래"처럼 저장됐다. 현재
      // 호출이 둘의 관계를 알고 있으므로 한 mutex transaction 안에서 합친다.
      // 합치지 않으면 이행 기간의 용량 상한이 alias마다 차감돼 오래된 purchase
      // 마커가 조기에 밀려나고 같은 결제가 중복 전송될 수 있다.
      await AnalyticsMarkerMutex.runExclusive(
        storageKey,
        () => _mergeLegacyAliases(keys),
      );
      _sent.addAll(keys);
      _pending.removeAll(keys);
      logger.i('analytics 중복 발송 차단(저장소) [$storageKey]: ${keys.first}');
      return null;
    }
    return AnalyticsSendReservation._(this, keys);
  }

  Future<bool> _commit(List<String> keys) {
    if (keys.isEmpty) return Future<bool>.value(true);
    // 전송이 확인된 순간 메모리 상태부터 동기적으로 승격한다. 영속화를
    // 기다리는 동안 들어온 재진입도 곧바로 막힌다.
    _sent.addAll(keys);
    _pending.removeAll(keys);
    return AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () => _appendEntry(keys),
    );
  }

  void _release(List<String> keys) {
    if (keys.isEmpty) return;
    _pending.removeAll(keys);
    logger.w(
      'analytics 발송 예약 해제 — 전송 실패로 마커를 남기지 않는다 '
      '[$storageKey]: ${keys.first}',
    );
  }

  /// [AnalyticsMarkerMutex] 안에서만 호출된다. 최신 목록을 다시 읽고 자기
  /// 항목을 덧붙이므로 서로 다른 키의 동시 갱신이 서로를 덮어쓰지 않는다.
  Future<bool> _appendEntry(List<String> keys) async {
    final groups = await _readGroups();
    if (groups == null) {
      // 읽지 못한 목록 위에 덮어쓰면 이전 마커 전체(최대 maxTrackedEntries 건)가
      // 사라진다. 마커 1건을 포기하는 쪽이 훨씬 싸다.
      logger.e(
        'analytics 전송 마커 갱신 포기 — 기존 목록 읽기 실패 [$storageKey]. '
        '덮어쓰면 이전 마커가 통째로 사라져 재시작 후 대량 중복이 난다.',
      );
      return false;
    }
    if (_containsAny(groups, keys)) return true;

    groups.add(List<String>.of(keys));
    final capped = groups.length > maxTrackedEntries
        ? groups.sublist(groups.length - maxTrackedEntries)
        : groups;
    try {
      await _s.saveData(storageKey, jsonEncode(capped)).timeout(ioTimeout);
      return true;
    } catch (e, s) {
      logger.e(
        'analytics 전송 마커 저장 실패 [$storageKey]: $keys',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<bool> _mergeLegacyAliases(List<String> keys) async {
    final groups = await _readGroups();
    if (groups == null) return false;
    final matches = <int>[];
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].any(keys.contains)) matches.add(i);
    }
    if (matches.isEmpty) return true;

    final merged = <String>{...keys};
    for (final index in matches) {
      merged.addAll(groups[index]);
    }
    final alreadyGrouped =
        matches.length == 1 &&
        merged.length == groups[matches.single].toSet().length;
    if (alreadyGrouped) return true;

    final insertionIndex = matches.first;
    for (final index in matches.reversed) {
      groups.removeAt(index);
    }
    groups.insert(insertionIndex, merged.toList());
    final capped = groups.length > maxTrackedEntries
        ? groups.sublist(groups.length - maxTrackedEntries)
        : groups;
    try {
      await _s.saveData(storageKey, jsonEncode(capped)).timeout(ioTimeout);
      logger.i('analytics legacy tx/op 마커를 한 거래 그룹으로 이관: $keys');
      return true;
    } catch (e, s) {
      logger.e(
        'analytics legacy tx/op 마커 이관 실패: $keys',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  static bool _containsAny(List<List<String>> groups, List<String> keys) {
    for (final group in groups) {
      for (final key in keys) {
        if (group.contains(key)) return true;
      }
    }
    return false;
  }

  /// 읽기 실패는 `null` (= 판정 불가), 값이 없거나 깨졌으면 빈 목록.
  ///
  /// 저장 포맷은 "별칭 묶음의 배열"이지만, 예전 포맷(문자열 배열 · 콤마 구분
  /// 문자열)도 각각 1건짜리 묶음으로 읽어 들인다. 마이그레이션 때문에 이미
  /// 기록된 마커가 무효화되면 그 순간이 곧 중복 발송이다.
  Future<List<List<String>>?> _readGroups() async {
    String? raw;
    try {
      raw = await _s.loadData(storageKey, null).timeout(ioTimeout);
    } catch (e, s) {
      logger.e('analytics 전송 마커 로드 실패 [$storageKey]', error: e, stackTrace: s);
      return null;
    }
    if (raw == null || raw.isEmpty) return <List<String>>[];

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      // JSON 이 아니면 예전 콤마 포맷으로 본다.
      return <List<String>>[
        for (final key in raw.split(','))
          if (key.isNotEmpty) <String>[key],
      ];
    }
    if (decoded is! List) {
      logger.w('analytics 전송 마커가 배열이 아니다 — 빈 목록으로 시작한다 [$storageKey]');
      return <List<String>>[];
    }
    final groups = <List<String>>[];
    for (final entry in decoded) {
      if (entry is List) {
        final keys = <String>[
          for (final key in entry)
            if (key is String && key.isNotEmpty) key,
        ];
        if (keys.isNotEmpty) groups.add(keys);
      } else if (entry is String && entry.isNotEmpty) {
        groups.add(<String>[entry]);
      }
    }
    return groups;
  }
}
