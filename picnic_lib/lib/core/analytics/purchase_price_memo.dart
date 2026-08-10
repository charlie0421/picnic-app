import 'dart:convert';

import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// 결제 시점의 통화·금액을 기록해 두는 저장소.
///
/// ## 왜 필요한가
///
/// `purchase` 이벤트의 `currency`/`value` 는 스토어 카탈로그
/// (`storeProductsProvider`)에서 온다. 정산 확정 시점에 카탈로그 future 를
/// 기다리면 조회 지연이 outbox 저장보다 먼저 일어나 store finish 뒤 매출
/// payload 가 사라지므로, 발송 경로는 **이미 메모리에 로드된** 카탈로그만
/// 동기적으로 읽는다.
///
/// 그래서 앱을 막 켠 직후 복구 스윕이 카탈로그 로드보다 먼저 돌면 금액을
/// 알 수 없고, `purchase` 건수는 남지만 매출이 0 으로 빠진다. 나중에 이
/// 데이터를 보는 사람에게는 **무료 지급으로 오해될 수 있는** 레코드다.
///
/// ## 왜 "캐시"가 아니라 "결제 시점 기록"인가
///
/// 복구 시점에 카탈로그를 다시 읽는 방식이었다면 그 사이의 가격 인상·프로모션
/// 종료·환율·지역 변경으로 **실제 결제 금액과 다른 값**이 들어갈 수 있다.
/// 여기에 남는 값은 사용자가 상점에서 보고 결제한 바로 그 가격이므로,
/// 폴백이 아니라 오히려 더 정확한 출처다.
///
/// 구매를 시작하려면 상점 화면을 거쳐야 하고 그 시점에는 카탈로그가 반드시
/// 메모리에 있으므로, 기록은 항상 남는다. 앱 데이터 삭제나 다른 기기에서
/// 시작된 구매처럼 기록이 없는 경우에는 기존 동작(금액 생략)으로 되돌아간다.
///
/// ## 실패 처리
///
/// 기록·조회 실패는 절대 결제나 analytics 발송을 막지 않는다. 모든 I/O 는
/// [ioTimeout] 으로 묶고 예외는 로그만 남긴 뒤 삼킨다. 조회가 실패하면
/// 금액 없이 발송하는 현재 동작과 같아질 뿐 거래 사실은 그대로 보존된다.
class PurchasePriceMemo {
  PurchasePriceMemo({
    LocalStorage? storage,
    this.ioTimeout = const Duration(seconds: 1),
  }) : _storage = storage;

  final LocalStorage? _storage;

  /// 마커 저장소(2초)보다 짧다. 이 조회는 정산 확정 **이후** 5초 예산 안에서
  /// 일어나므로, 오래 물고 있으면 정작 중요한 outbox 저장이 잘려 매출
  /// payload 를 통째로 잃는다. 금액은 있으면 좋은 값이고 거래 기록은
  /// 반드시 남아야 하는 값이라, 둘이 부딪히면 거래 기록이 이긴다.
  final Duration ioTimeout;

  LocalStorage get _s => _storage ?? globalStorage;

  static const String storageKey = 'analytics_purchase_price_memo_v1';

  /// 최근 결제 [maxEntries] 건만 유지한다. 복구는 보통 며칠 안에 끝나므로
  /// 넉넉하고, 저장 크기는 한 건당 수십 바이트다.
  static const int maxEntries = 50;

  /// 이 기간이 지난 기록은 조회에서 무시하고 정리한다. 스토어 가격이 그
  /// 사이 바뀌었을 수 있어 오래된 값을 매출로 올리는 것은 누락보다 나쁘다.
  static const Duration maxAge = Duration(days: 90);

  /// 결제 직전에 호출한다. 카탈로그가 메모리에 있는 시점이라 값이 확실하다.
  ///
  /// 호출부는 **await 하지 않는다** — 결제 시트가 뜨기 전에 로컬 I/O 를
  /// 기다리게 만들면 안 된다. 기록이 실제로 필요해지는 것은 이 구매가
  /// 한 번에 끝나지 않고 다음 실행에서 복구될 때뿐이고, 그 사이에는
  /// 인증·결제로 충분한 시간이 있다.
  Future<void> record({
    required String storeProductId,
    required String? currency,
    required num? value,
  }) async {
    if (storeProductId.isEmpty) return;
    // 둘 중 하나라도 없으면 기록할 이유가 없다. 어차피 발송 시점에 생략된다.
    if (currency == null || currency.isEmpty || value == null) return;

    try {
      final entries = await _load();
      entries.removeWhere((e) => e.storeProductId == storeProductId);
      entries.add(
        _PriceEntry(
          storeProductId: storeProductId,
          currency: currency,
          value: value,
          recordedAt: DateTime.now(),
        ),
      );
      await _save(entries);
    } catch (e, s) {
      logger.e('결제 가격 기록 실패 — 복구 구매의 매출이 비게 될 수 있다',
          error: e, stackTrace: s);
    }
  }

  /// 카탈로그가 메모리에 없을 때만 호출한다. 기록이 없거나 만료됐으면 null.
  Future<PurchasePriceRecord?> lookup(String storeProductId) async {
    if (storeProductId.isEmpty) return null;

    try {
      final entries = await _load();
      for (final e in entries) {
        if (e.storeProductId != storeProductId) continue;
        if (DateTime.now().difference(e.recordedAt) > maxAge) {
          logger.w('결제 가격 기록 만료 — 금액 없이 발송: $storeProductId');
          return null;
        }
        return PurchasePriceRecord(currency: e.currency, value: e.value);
      }
      return null;
    } catch (e, s) {
      logger.e('결제 가격 기록 조회 실패 — 금액 없이 발송', error: e, stackTrace: s);
      return null;
    }
  }

  /// 테스트 전용.
  Future<void> clearForTest() => _save(<_PriceEntry>[]);

  /// 저장 내용을 읽는다.
  ///
  /// **I/O 실패는 그대로 던진다.** 저장소를 읽지 못한 것을 "비어 있음"으로
  /// 축약하면 뒤이은 저장이 멀쩡한 기록을 통째로 덮어쓴다.
  ///
  /// 반면 **내용 손상은 빈 상태로 축약한다.** 파싱되지 않는 값은 이미 쓸 수
  /// 없으므로 덮어써도 잃을 것이 없고, 축약하지 않으면 손상된 blob 하나가
  /// 이후 모든 기록을 영구히 막는다.
  Future<List<_PriceEntry>> _load() async {
    final raw = await _s.loadData(storageKey, null).timeout(ioTimeout);
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
    for (final item in list) {
      final parsed = _PriceEntry.tryParse(item);
      // 손상된 항목 하나가 나머지 기록을 통째로 버리게 하지 않는다.
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  Future<void> _save(List<_PriceEntry> entries) async {
    final now = DateTime.now();
    final fresh = entries
        .where((e) => now.difference(e.recordedAt) <= maxAge)
        .toList(growable: true);

    // 오래된 것부터 밀어낸다. 밀려난 건은 금액 없이 발송되므로 로그로 남긴다.
    if (fresh.length > maxEntries) {
      final dropped = fresh.length - maxEntries;
      logger.w('결제 가격 기록 용량 초과 — 오래된 $dropped건 제거');
      fresh.removeRange(0, dropped);
    }

    final payload = jsonEncode(<String, dynamic>{
      'version': 1,
      'entries': fresh.map((e) => e.toJson()).toList(),
    });
    await _s.saveData(storageKey, payload).timeout(ioTimeout);
  }
}

/// [PurchasePriceMemo.lookup] 결과.
class PurchasePriceRecord {
  const PurchasePriceRecord({required this.currency, required this.value});

  final String currency;
  final num value;
}

class _PriceEntry {
  _PriceEntry({
    required this.storeProductId,
    required this.currency,
    required this.value,
    required this.recordedAt,
  });

  final String storeProductId;
  final String currency;
  final num value;
  final DateTime recordedAt;

  static _PriceEntry? tryParse(Object? item) {
    if (item is! Map) return null;
    final id = item['id'];
    final currency = item['currency'];
    final value = item['value'];
    final at = item['at'];
    if (id is! String || id.isEmpty) return null;
    if (currency is! String || currency.isEmpty) return null;
    if (value is! num) return null;
    if (at is! int) return null;
    return _PriceEntry(
      storeProductId: id,
      currency: currency,
      value: value,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': storeProductId,
        'currency': currency,
        'value': value,
        'at': recordedAt.millisecondsSinceEpoch,
      };
}
