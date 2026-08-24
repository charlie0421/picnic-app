import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// GA4 `purchase` 이벤트의 중복 발송을 거래 ID 기준으로 차단한다.
///
/// **왜 필요한가.** 하나의 결제가 이 경로를 여러 번 흐른다:
///   1. `purchaseStream` 재발화 — 스토어가 같은 `PurchaseDetails` 를 다시 흘린다.
///   2. 앱 재시작 시 미완료 트랜잭션 복원 —
///      `PurchaseService.sweepUnfinishedPurchases` 가 스토어 큐에 남아 있는
///      결제를 다시 검증에 태운다.
///   3. 검증 재시도 — `ReceiptVerificationService` 는 응답이 유실되면 같은
///      영수증을 다시 보낸다(서버는 멱등하므로 같은 정산을 되돌려준다).
///
/// **영속 범위: 기기 로컬 저장소**([LocalStorage] → 모바일에서는
/// SharedPreferences). 메모리 플래그만으로는 (2) 를 막지 못한다 — 앱이
/// 재시작하면 플래그가 사라지는데 스토어 큐의 트랜잭션은 그대로 살아 있어서
/// 같은 결제가 실행마다 한 번씩 더 발송된다. 반대로 저장소가 없거나 실패하는
/// 환경(웹/단위 테스트/초기화 실패)에서는 프로세스 수명 동안 유지되는 정적
/// 메모리 집합이 최소한 (1)(3) 을 막는다. 그래서 두 겹을 모두 둔다.
///
/// ## 마커는 전송이 **실제로 성공한 뒤에만** 남는다
///
/// 예전 `markIfFirst` 는 발송 전에 마커를 영속화했다. `Ga4Sink` 가 Firebase
/// 미초기화 환경에서 조용히 no-op 하고 예외도 삼켰으므로 "보내지 않았는데
/// 보냈다고 기록"이 성립했고, 그 거래는 다음 재전달에서 영구히 차단됐다 —
/// 매출 영구 누락. 지금은 [reserve] 가 in-flight 예약만 잡고, 전송 성공을
/// 확인한 호출부(`AnalyticsService.logPurchaseEvent`)가 `commit()` 할 때
/// 비로소 마커가 남는다. 실패·타임아웃이면 `release()` 로 예약이 풀려 다음
/// 재전달이 다시 시도한다. 어느 위험을 택했는지는
/// [AnalyticsSendMarkerStore] 문서의 "매출 누락 vs 중복" 절에 있다.
///
/// 기록은 [maxTrackedTransactions] **건**으로 상한을 둔 FIFO 다. 상한은
/// 거래 단위로 센다 — 한 결제가 남기는 별칭(거래 ID · `op:<operation_id>`)은
/// 한 항목의 부속이지 별도 항목이 아니다. 예전처럼 별칭을 각각 세면 실효
/// 추적 폭이 절반(50건)이 되고, 밀려난 오래된 미완료 거래가 다시 매출로 잡힌다.
class PurchaseAnalyticsDedup {
  PurchaseAnalyticsDedup({LocalStorage? storage})
    : _markers = AnalyticsSendMarkerStore(
        storageKey: storageKey,
        maxTrackedEntries: maxTrackedTransactions,
        storage: storage,
      );

  final AnalyticsSendMarkerStore _markers;

  static const String storageKey = 'analytics_logged_purchase_tx_ids';

  /// 저장소에 남겨 두는 **거래** 개수 상한.
  static const int maxTrackedTransactions = 100;

  /// 프로세스 캐시(in-flight · sent)를 비운다. 테스트에서 앱 재시작을 흉내
  /// 내는 용도다.
  @visibleForTesting
  static void resetProcessCache() =>
      AnalyticsSendMarkerStore.resetProcessCacheForTest();

  /// GA4 `transaction_id` 로 내보낼 거래 키. 중복 판정에 쓰는 키와 **같은 값**이다.
  ///
  /// 두 값이 갈라지면 안 되기 때문에 해석 규칙을 여기 한 곳에만 둔다. 예전에는
  /// dedup 만 `operation_id` 로 폴백하고 GA4 에는 `purchaseID` 를 그대로
  /// 넘겼는데, `purchaseID` 가 비면 T2 레이어가 그것을 문자열 `'undefined'`
  /// 로 치환한다 — 서로 다른 결제 두 건이 GA4 에서 같은 `transaction_id` 를
  /// 갖게 되고, GA4 는 `transaction_id` 로 `purchase` 를 중복 제거하므로
  /// 두 번째 결제의 매출이 사라지거나 집계가 통째로 깨진다.
  ///
  /// `op:` 접두사는 그대로 내보낸다. `purchaseID` 공간과 `operation_id` 공간이
  /// 우연히 겹쳐도 서로 다른 결제로 남으려면 접두사가 필요하고, GA4 쪽에서
  /// 이 값에 요구되는 성질은 "가독성"이 아니라 "결제 1건당 유일"이다.
  static String? resolvePrimaryKey(String? transactionId, String? fallbackKey) {
    final tx = transactionId?.trim();
    if (tx != null && tx.isNotEmpty) return tx;
    final fallback = fallbackKey?.trim();
    if (fallback != null && fallback.isNotEmpty) return 'op:$fallback';
    return null;
  }

  /// 이 결제를 가리킬 수 있는 모든 키. 우선순위 순.
  ///
  /// 판정은 "이 중 **하나라도** 기록돼 있으면 이미 보낸 것", 기록은 "**전부**
  /// 한 항목으로 남긴다". 한 실행에서는 `purchaseID` 로, 다른 실행에서는
  /// `operation_id` 로 해석되는 일이 생겨도(스토어가 재전달에서 거래 ID 를
  /// 빠뜨리는 등) 같은 결제가 두 번 나가지 않는다. 재전달 플래그를 발송
  /// 증거로 쓰지 않게 된 뒤로는 이 dedup 이 단독 게이트이므로, 키 해석이
  /// 갈라지는 것 자체가 매출 중복이다.
  static List<String> candidateKeys(String? transactionId, String? fallback) {
    final keys = <String>[];
    final tx = transactionId?.trim();
    if (tx != null && tx.isNotEmpty) keys.add(tx);
    final op = fallback?.trim();
    if (op != null && op.isNotEmpty) keys.add('op:$op');
    return keys;
  }

  /// 이 거래를 지금 보내도 되면 예약을, 이미 보냈거나 다른 시도가 진행
  /// 중이면 `null` 을 돌려준다.
  ///
  /// [transactionId] 는 스토어의 결제 건 고유 ID(`PurchaseDetails.purchaseID`)
  /// 다. 스토어가 이것을 주지 않는 드문 경로를 위해 [fallbackKey] 로 서버
  /// 정산의 `operation_id` 를 받는다 — 서버가 결제 1건당 하나만 발급하므로
  /// 거래 ID 만큼이나 좋은 멱등 키다.
  ///
  /// 둘 다 없으면 중복인지 판별할 방법이 없다. 그때는 아무것도 기록하지 않는
  /// 예약을 돌려주되 경고를 남긴다: 발송을 막으면 확실한 매출 누락이고,
  /// 발송하면 잠재적 중복이다. (`AnalyticsService` 는 이 경우 애초에 여기까지
  /// 오지 않고 발송을 포기한다 — [resolvePrimaryKey] 문서 참조.)
  Future<AnalyticsSendReservation?> reserve(
    String? transactionId, {
    String? fallbackKey,
  }) {
    final keys = candidateKeys(transactionId, fallbackKey);
    if (keys.isEmpty) {
      logger.w(
        'GA4 purchase 중복 방어 불가 — 거래 ID 와 operation_id 가 모두 없다. '
        '중복 발송 가능성이 있으니 스토어 응답을 확인할 것.',
      );
    }
    return _markers.reserve(keys);
  }

  /// 이 거래가 이미 GA4 로 나갔음이 확인되는가. 진행 중은 제외한다.
  Future<bool> isKnownSent(String? transactionId, {String? fallbackKey}) =>
      _markers.isKnownSent(candidateKeys(transactionId, fallbackKey));
}
