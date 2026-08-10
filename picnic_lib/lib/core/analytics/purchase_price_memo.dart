import 'dart:convert';

import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// 결제 시도 시점의 통화·금액을 **그 시도에 결합해** 기록해 두는 저장소.
///
/// ## 왜 필요한가
///
/// `purchase` 의 `currency`/`value` 는 스토어 카탈로그에서 온다. 발송 경로는
/// 카탈로그 future 를 기다리지 않고 이미 메모리에 로드된 값만 동기적으로
/// 읽는다 — 기다리다 지연되면 outbox 저장보다 store finish 가 먼저 일어나
/// 매출 payload 가 통째로 사라지기 때문이다.
///
/// 그래서 앱 재시작 직후 복구 스윕이 카탈로그보다 먼저 돌면 금액을 알 수
/// 없다. `purchase` 건수는 있는데 매출이 0 인 레코드는 나중에 보는 사람에게
/// **무료 지급으로 오해될 수 있어** 단순 누락보다 나쁘다.
///
/// ## 왜 카탈로그 재조회가 아니라 결제 시점 기록인가
///
/// 정산이 며칠 뒤에 일어나면 그 사이 가격 인상·프로모션 종료·환율·지역
/// 변경으로 카탈로그 값이 **실제 결제 금액과 달라진다.** 여기 남는 값은
/// 사용자가 상점에서 보고 결제한 바로 그 가격이다.
///
/// ## 무엇에 결합하는가 — 상품 ID 만으로는 안 된다
///
/// 기록은 결제 **시도**마다 남고 취소된 시도도 남는다. 상품 ID 만 키로 쓰면
/// 취소된 시도의 잔재, 다른 사용자, 다른 스토어 계정의 값이 서로 덮어써
/// **틀린 매출**이 들어간다. 틀린 매출은 누락보다 나쁘다.
///
/// 그래서 항목마다 `userId` 와 기록 시각을 함께 남기고, 조회는
/// 정산 대상 사용자 + 거래 시각으로 **단일 시도를 지목**한다. 지목이
/// 모호하면 금액을 생략한다 — 추측한 숫자를 매출로 올리지 않는다.
///
/// 지목된 항목은 **소비(삭제)** 한다. 남겨 두면 기록 없이 복구된 다른 거래
/// (예: 다른 기기에서 시작된 구매)가 그 값을 잘못 집어갈 수 있다.
///
/// ## 실패 처리
///
/// 기록·조회 실패는 절대 결제나 analytics 발송을 막지 않는다. 실패하면 금액
/// 없이 발송하는 기존 동작으로 돌아갈 뿐 거래 사실은 그대로 보존된다.
class PurchasePriceMemo {
  PurchasePriceMemo({
    LocalStorage? storage,
    this.ioTimeout = const Duration(seconds: 1),
  }) : _storage = storage;

  final LocalStorage? _storage;

  /// 마커 저장소(2초)보다 짧다. 이 조회는 정산 확정 **이후** 예산 안에서
  /// 일어나므로, 오래 물고 있으면 정작 중요한 outbox 저장이 잘려 매출
  /// payload 를 통째로 잃는다. 금액은 있으면 좋은 값이고 거래 기록은 반드시
  /// 남아야 하는 값이라, 둘이 부딪히면 거래 기록이 이긴다.
  final Duration ioTimeout;

  LocalStorage get _s => _storage ?? globalStorage;

  static const String storageKey = 'analytics_purchase_price_memo_v2';

  /// 최근 시도 [maxEntries] 건만 유지한다. 한 건당 수십 바이트다.
  static const int maxEntries = 100;

  /// 이 기간이 지난 기록은 쓰지 않는다. 오래된 값을 매출로 올리는 것은
  /// 누락보다 나쁘다.
  static const Duration maxAge = Duration(days: 90);

  /// 기기 시계와 스토어 거래 시각의 차이를 흡수한다. 기록은 언제나 스토어
  /// 거래보다 **앞서므로**, 이 여유 안에서만 "거래 이전"으로 인정한다.
  static const Duration clockSkew = Duration(minutes: 10);

  /// `DateTime.fromMillisecondsSinceEpoch` 이 받는 범위. 벗어난 값은
  /// `RangeError` 를 던지므로 파싱 전에 걸러야 한다 — 손상된 항목 하나가
  /// 전체 기록을 영구히 막는 poison blob 이 되면 안 된다.
  static const int _maxEpochMillis = 8640000000000000;

  /// 결제 직전에 호출한다. 카탈로그가 메모리에 있는 시점이라 값이 확실하다.
  ///
  /// 호출부는 **await 하지 않는다** — 결제 시트가 뜨기 전에 로컬 I/O 를
  /// 기다리게 만들면 안 된다.
  Future<void> record({
    required String storeProductId,
    required String? userId,
    required String? currency,
    required num? value,
  }) async {
    // userId 가 없으면 나중에 어느 시도인지 지목할 수 없다. 지목 못 할 값을
    // 남기면 다른 거래가 잘못 집어갈 뿐이다.
    if (storeProductId.isEmpty) return;
    if (userId == null || userId.isEmpty) return;
    if (!_isValidCurrency(currency)) return;
    if (!_isValidValue(value)) return;

    try {
      // **mutex 대기까지 포함해** 시간을 묶는다. 직렬화는 저장 정확성을
      // 보장하지만, 앞선 작업이 물리면 뒤의 모두가 영원히 대기한다.
      // analytics 는 어떤 경우에도 호출자를 붙잡으면 안 된다.
      await AnalyticsMarkerMutex.runExclusive(storageKey, () async {
        final entries = await _load();
        entries.add(
          _PriceEntry(
            storeProductId: storeProductId,
            userId: userId,
            currency: currency!,
            value: value!,
            recordedAt: DateTime.now(),
          ),
        );
        await _save(entries);
      }).timeout(ioTimeout * 2);
    } catch (e, s) {
      logger.e('결제 가격 기록 실패 — 복구 구매의 매출이 비게 될 수 있다',
          error: e, stackTrace: s);
    }
  }

  /// 이 거래에 해당하는 기록을 **지목해서 가져오고 소비**한다.
  ///
  /// [transactionAt] 은 스토어가 알려준 거래 시각이다. 기록은 언제나 거래보다
  /// 앞서므로, 그 이전(+[clockSkew])에 남은 것 중 **가장 가까운** 하나를
  /// 고른다. 거래 시각을 모르면 후보가 정확히 하나일 때만 인정한다.
  ///
  /// [budget] 이 주어지면 남은 예산과 [ioTimeout] 중 짧은 쪽을 쓴다. 예산이
  /// 이미 없으면 즉시 포기한다 — 금액을 얻자고 outbox 저장을 굶기지 않는다.
  Future<PurchasePriceRecord?> takeFor({
    required String storeProductId,
    required String? userId,
    required DateTime? transactionAt,
    Duration? budget,
  }) async {
    if (storeProductId.isEmpty) return null;
    if (userId == null || userId.isEmpty) return null;
    if (budget != null && budget <= Duration.zero) {
      logger.w('결제 가격 조회 예산 소진 — 금액 없이 발송: $storeProductId');
      return null;
    }

    final overall = budget ?? (ioTimeout * 2);
    try {
      // mutex 대기까지 포함해 묶는다 — 위 [record] 와 같은 이유다.
      return await AnalyticsMarkerMutex.runExclusive(storageKey, () async {
        final entries = await _load(budget: budget);
        final now = DateTime.now();

        final candidates = <_PriceEntry>[];
        for (final e in entries) {
          if (e.storeProductId != storeProductId) continue;
          if (e.userId != userId) continue;
          if (now.difference(e.recordedAt) > maxAge) continue;
          if (transactionAt != null &&
              e.recordedAt.isAfter(transactionAt.add(clockSkew))) {
            // 거래 이후에 남은 기록은 이 거래의 것이 아니다.
            continue;
          }
          candidates.add(e);
        }

        if (candidates.isEmpty) return null;

        _PriceEntry chosen;
        if (transactionAt != null) {
          // 거래 직전에 남은 것이 이 거래의 시도다.
          candidates.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          chosen = candidates.last;
        } else if (candidates.length == 1) {
          chosen = candidates.first;
        } else {
          // 어느 시도인지 지목할 수 없다. 추측한 숫자를 매출로 올리지 않는다.
          logger.w(
            '결제 가격 기록이 모호함(${candidates.length}건, 거래 시각 없음) — '
            '금액 없이 발송: $storeProductId',
          );
          return null;
        }

        entries.remove(chosen);
        await _save(entries, budget: budget);

        return PurchasePriceRecord(
          currency: chosen.currency,
          value: chosen.value,
        );
      }).timeout(overall);
    } catch (e, s) {
      logger.e('결제 가격 기록 조회 실패 — 금액 없이 발송', error: e, stackTrace: s);
      return null;
    }
  }

  /// 테스트 전용.
  Future<void> clearForTest() =>
      AnalyticsMarkerMutex.runExclusive(storageKey, () => _save(<_PriceEntry>[]));

  /// 테스트 전용(앱 재시작 흉내).
  static void resetProcessStateForTest() => AnalyticsMarkerMutex.resetForTest();

  Duration _bounded(Duration? budget) {
    if (budget == null) return ioTimeout;
    return budget < ioTimeout ? budget : ioTimeout;
  }

  /// 저장 내용을 읽는다.
  ///
  /// **I/O 실패는 그대로 던진다.** 저장소를 읽지 못한 것을 "비어 있음"으로
  /// 축약하면 뒤이은 저장이 멀쩡한 기록을 통째로 덮어쓴다.
  ///
  /// 반면 **내용 손상은 항목 단위로 버린다.** 파싱되지 않는 항목은 이미 쓸 수
  /// 없고, 하나 때문에 전체를 버리거나 예외를 퍼뜨리면 손상된 blob 하나가
  /// 이후 모든 기록을 영구히 막는다.
  Future<List<_PriceEntry>> _load({Duration? budget}) async {
    final raw = await _s.loadData(storageKey, null).timeout(_bounded(budget));
    if (raw == null || raw.isEmpty) return <_PriceEntry>[];

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      logger.w('결제 가격 기록이 손상됨 — 빈 상태에서 다시 시작한다: $e');
      return <_PriceEntry>[];
    }

    if (decoded is! Map<String, dynamic>) return <_PriceEntry>[];
    final list = decoded['entries'];
    if (list is! List) return <_PriceEntry>[];

    final out = <_PriceEntry>[];
    var dropped = 0;
    for (final item in list) {
      final parsed = _PriceEntry.tryParse(item);
      if (parsed == null) {
        dropped++;
        continue;
      }
      out.add(parsed);
    }
    if (dropped > 0) {
      logger.w('결제 가격 기록 손상 항목 $dropped건 버림 — 나머지는 유지');
    }
    return out;
  }

  Future<void> _save(List<_PriceEntry> entries, {Duration? budget}) async {
    final now = DateTime.now();
    final fresh = entries
        .where((e) => now.difference(e.recordedAt) <= maxAge)
        .toList(growable: true);

    fresh.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (fresh.length > maxEntries) {
      final dropped = fresh.length - maxEntries;
      logger.w('결제 가격 기록 용량 초과 — 오래된 $dropped건 제거');
      fresh.removeRange(0, dropped);
    }

    final payload = jsonEncode(<String, dynamic>{
      'version': 2,
      'entries': fresh.map((e) => e.toJson()).toList(),
    });
    await _s.saveData(storageKey, payload).timeout(_bounded(budget));
  }

  static bool _isValidCurrency(String? currency) {
    if (currency == null) return false;
    // GA4 는 ISO 4217 이 아니면 그 purchase 의 매출을 통째로 무시한다.
    // 형식이 어긋난 값을 기록해 두면 나중에 그 매출이 사라진다.
    return RegExp(r'^[A-Za-z]{3}$').hasMatch(currency);
  }

  static bool _isValidValue(num? value) {
    if (value == null) return false;
    if (value is double && !value.isFinite) return false;
    return value >= 0;
  }
}

/// [PurchasePriceMemo.takeFor] 결과.
class PurchasePriceRecord {
  const PurchasePriceRecord({required this.currency, required this.value});

  final String currency;
  final num value;
}

class _PriceEntry {
  _PriceEntry({
    required this.storeProductId,
    required this.userId,
    required this.currency,
    required this.value,
    required this.recordedAt,
  });

  final String storeProductId;
  final String userId;
  final String currency;
  final num value;
  final DateTime recordedAt;

  /// 손상된 항목은 **예외 없이** null 로 돌려준다. 특히 `at` 은
  /// `DateTime.fromMillisecondsSinceEpoch` 의 유효 범위를 벗어나면
  /// `RangeError` 를 던지므로 변환 전에 범위를 확인한다.
  static _PriceEntry? tryParse(Object? item) {
    try {
      if (item is! Map) return null;

      final id = item['id'];
      final userId = item['user'];
      final currency = item['currency'];
      final value = item['value'];
      final at = item['at'];

      if (id is! String || id.isEmpty) return null;
      if (userId is! String || userId.isEmpty) return null;
      if (!PurchasePriceMemo._isValidCurrency(
        currency is String ? currency : null,
      )) {
        return null;
      }
      if (value is! num || !PurchasePriceMemo._isValidValue(value)) return null;

      if (at is! int) return null;
      if (at.abs() > PurchasePriceMemo._maxEpochMillis) return null;

      final recordedAt = DateTime.fromMillisecondsSinceEpoch(at);
      // 미래에 기록됐다는 값은 시계 조작이나 손상이다. 신선한 매출로
      // 받아들이면 만료 방어를 그대로 통과한다.
      if (recordedAt.isAfter(
        DateTime.now().add(PurchasePriceMemo.clockSkew),
      )) {
        return null;
      }

      return _PriceEntry(
        storeProductId: id,
        userId: userId,
        currency: currency as String,
        value: value,
        recordedAt: recordedAt,
      );
    } catch (_) {
      // 어떤 손상도 한 항목의 문제로 가둔다.
      return null;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': storeProductId,
        'user': userId,
        'currency': currency,
        'value': value,
        'at': recordedAt.millisecondsSinceEpoch,
      };
}
