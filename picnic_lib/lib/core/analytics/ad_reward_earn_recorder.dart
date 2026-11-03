import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';

/// 광고 적립 1건의 idempotency key.
///
/// 내부 숏폼 직접 표시 경로(`enqueueLegacyShortformEarnAnalytics`)와 **같은
/// 문자열**이어야 한다. 같은 시청 건이 두 경로로 들어와도 durable outbox 가
/// 하나로 합치는 근거가 이 키뿐이다.
String adRewardEarnKey(AdRewardReference reference) =>
    '${reference.type.wireValue}:${reference.id}';

/// `earn_virtual_currency` (스펙 §2-7) — 앱이 **서버 확정 지급을 관측한 순간**
/// 그 적립을 durable outbox 에 넣는다.
///
/// 팝업 수명과 분리되어 있다는 것이 핵심이다. 예전에는 `AdRewardDialogHost` 가
/// 다이얼로그를 띄우기 직전에만 보냈으므로, host 가 마운트돼 있지 않거나
/// 사용자가 광고 화면을 먼저 떠난 확정 적립은 통계에서 통째로 빠졌다.
///
/// 발송 기준은 SDK 콜백이 아니라 서버가 만든 grant 다:
/// [AdRewardState.granted] 이면서 grant 금액이 양수일 때만 기록하므로
/// DENIED/EXPIRED/ABANDONED/PENDING 은 절대 적립으로 집계되지 않는다.
///
/// outbox 저장에 성공했을 때만 true. 저장 실패와 예외는 로그로 드러내고 false 를
/// 돌려주며, 호출부가 같은 reference 로 다시 시도할 수 있게 한다 (중복 저장은
/// [adRewardEarnKey] 기준으로 outbox 가 막는다).
Future<bool> recordAdRewardEarn({
  required AdRewardStatusModel status,
  EarnAnalyticsStore? store,
}) async {
  final grant = status.grant;
  if (status.state != AdRewardState.granted ||
      grant == null ||
      grant.amount <= BigInt.zero) {
    return false;
  }

  final key = adRewardEarnKey(status.reference);
  try {
    final stored = await (store ?? EarnAnalyticsStore()).enqueueEarn(
      reference: key,
      virtualCurrencyName: FreeChargeGa4.currencyName(grant.currency),
      rewardAmount: grant.amount.toInt(),
      earnMethod: FreeChargeGa4.earnMethodRewardedAd,
      sectionName: FreeChargeGa4.sectionAds,
      adCategory: FreeChargeGa4.adCategoryForReference(status.reference.type),
    );
    if (!stored) {
      logger.e(
        'earn_virtual_currency outbox 저장 실패 — 적립은 완료됐지만 '
        '내구 재전송 항목을 남기지 못함: $key',
      );
    }
    return stored;
  } catch (error, stackTrace) {
    logger.e(
      'earn_virtual_currency outbox 저장 실패: $key',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
