import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/analytics/analytics.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_analytics_dedup.dart';

/// 스토어 상품 ID 를 스펙의 정규 상품 식별자로 되돌린다.
///
/// 같은 상품이 플랫폼마다 다른 ID 를 갖는다
/// (`PaymentProductIdPolicy.effectiveProductId`):
///   - iOS  : `<앱접두사>STAR100` (현행 설정에서는 접두사가 빈 문자열)
///   - Android: `star100` — Play SKU 는 소문자가 강제된다
///   - dev/local Android: `staging.star100` 처럼 네임스페이스가 붙는다
/// 이 값을 그대로 `item_id` 로 보내면 GA4 에서 같은 SKU 가 플랫폼·환경별로
/// 갈라져 상품별 매출을 합칠 수 없다. 마지막 점(.) 뒤 구간을 취해
/// 네임스페이스/앱 접두사를 떼고 대문자로 통일한다.
///
/// 스펙 예시값은 `item_id: star100`, `item_name: STAR100` 이므로 정규 ID 를
/// 소문자로 내린 것이 `item_id`, 그대로가 `item_name` 이다.
String canonicalStoreProductId(String storeProductId) {
  final separator = storeProductId.lastIndexOf('.');
  final tail = separator >= 0
      ? storeProductId.substring(separator + 1)
      : storeProductId;
  return tail.toUpperCase();
}

class AnalyticsService {
  AnalyticsService({PurchaseAnalyticsDedup? dedup, AnalyticsOutbox? outbox})
    : _dedup = dedup ?? PurchaseAnalyticsDedup(),
      // Production uses outbox and consults the legacy marker only for rollout
      // migration. Explicit dedup injection keeps the pre-outbox focused tests
      // on the old direct-send seam.
      _outbox = outbox ?? (dedup == null ? AnalyticsOutbox.instance : null);

  final PurchaseAnalyticsDedup _dedup;
  final AnalyticsOutbox? _outbox;

  /// GA4 `purchase` (스펙 §2-9) — 결제 검증이 끝나 적립이 확정된 시점.
  ///
  /// **호출 조건은 호출부가 지킨다**: `PurchaseService._logPurchaseAnalytics`
  /// 는 서버 영수증 검증이 성공한 뒤에만 이 메서드를 부른다. 스토어 구매
  /// 콜백만으로는 부르지 않는다.
  ///
  /// 신규 payload의 중복 판정과 재전송은 [AnalyticsOutbox]가 맡고,
  /// [PurchaseAnalyticsDedup]은 이전 release의 marker 이관에만 참여한다.
  /// 정산의 재전달 플래그(`replayed`)는 여기서도 호출부에서도 쓰지
  /// 않는다: "서버가 같은 정산을 다시 돌려줬다"와 "우리가 이미 GA4 로
  /// 보냈다"는 서로 다른 사실이고, 전자를 후자의 증거로 쓰면 최초 실행이
  /// 발송 전에 죽은 결제가 영원히 GA4 에서 빠진다.
  ///
  /// **"보냈다"의 정의는 sink 가 성공을 반환한 것 하나뿐이다.** 그 전에는
  /// 완성된 정산 payload가 outbox에 남는다. 스토어가 finish/consume된 뒤에도
  /// outbox가 독립적으로 재시도하므로 Firebase 실패가 매출 영구 누락이 되지 않는다.
  ///
  /// [sendTimeout] 은 **전송 자체**의 상한이다. 상한을 여기 두는 이유:
  /// `Future.timeout` 은 하위 future 를 취소하지 못하므로, 호출부가 바깥에서만
  /// 시간을 재면 타임아웃 후에도 예약이 누구의 것도 아닌 채 남는다. 예약의
  /// 생사는 예약을 만든 이 메서드가 `finally` 급으로 책임진다.
  ///
  /// [baseAmount] / [bonusAmount] 는 새로 계산하지 않는다. 서버 정산
  /// (`PurchaseSettlementResultModel`)이 알려준 실제 적립 수량을 호출부가
  /// 그대로 넘긴다.
  Future<void> logPurchaseEvent(
    ProductDetails product, {
    String? transactionId,
    String? idempotencyFallbackKey,
    num? baseAmount,
    num? bonusAmount,
    Duration sendTimeout = defaultSendTimeout,
  }) {
    return logPurchasePayload(
      storeProductId: product.id,
      currency: _extractCurrency(product),
      value: _extractPrice(product),
      transactionId: transactionId,
      idempotencyFallbackKey: idempotencyFallbackKey,
      baseAmount: baseAmount,
      bonusAmount: bonusAmount,
      sendTimeout: sendTimeout,
    );
  }

  /// 카탈로그 조회가 실패/지연돼도 정산 사실 자체는 durable하게 남기는 경로.
  /// currency/value를 얻지 못하면 숫자를 지어내지 않고 생략하되, 거래 ID와
  /// 서버 확정 적립량은 그대로 보존한다.
  Future<void> logPurchasePayload({
    required String storeProductId,
    required String? currency,
    required num? value,
    String? transactionId,
    String? idempotencyFallbackKey,
    num? baseAmount,
    num? bonusAmount,
    Duration sendTimeout = defaultSendTimeout,
  }) async {
    // GA4 로 나가는 `transaction_id` 와 중복 판정 키는 **같은 값**이어야 한다.
    // 한 곳에서만 해석해 두 값이 갈라질 여지를 없앤다.
    final resolvedTransactionId = PurchaseAnalyticsDedup.resolvePrimaryKey(
      transactionId,
      idempotencyFallbackKey,
    );
    if (resolvedTransactionId == null) {
      // 거래 ID 도 operation_id 도 없다. 이대로 보내면 T2 레이어가 빈 값을
      // 문자열 `'undefined'` 로 치환하고(빈 문자열은 Firebase 가 파라미터째
      // 버리므로), 키 없는 결제가 둘 이상 생기는 순간 서로 다른 결제가 GA4
      // 에서 같은 거래로 뭉개진다. GA4 는 `transaction_id` 로 `purchase` 를
      // 중복 제거하므로 결과는 "한 건이 빠진다"가 아니라 "그 거래의 매출
      // 집계가 무너진다"다.
      //
      // 그래서 매출 1건을 포기한다. 비대칭이 명확하다: 빠진 1건은 서버
      // 정산 기록으로 복원할 수 있지만, 오염된 집계는 GA4 안에서 되돌릴
      // 방법이 없다. 이 경로는 실제로 발생하면 안 되는 것이라 error 로 남긴다.
      logger.e(
        'GA4 purchase 발송 포기 — 거래 ID 와 operation_id 가 모두 없다. '
        "'undefined' 로 보내면 서로 다른 결제가 같은 거래로 집계된다: "
        '$storeProductId',
      );
      return;
    }

    final canonicalId = canonicalStoreProductId(storeProductId);
    final aliases = PurchaseAnalyticsDedup.candidateKeys(
      transactionId,
      idempotencyFallbackKey,
    );

    final outbox = _outbox;
    if (outbox != null) {
      final legacyReservation = await _dedup.reserve(
        transactionId,
        fallbackKey: idempotencyFallbackKey,
      );
      if (legacyReservation == null) return;
      try {
        final persisted = await outbox.enqueue(
          AnalyticsOutboxEntry.purchase(
            id: resolvedTransactionId,
            aliases: aliases,
            transactionId: resolvedTransactionId,
            currency: currency,
            value: value,
            items: <Ga4PurchaseItem>[
              Ga4PurchaseItem(
                itemId: canonicalId.toLowerCase(),
                itemName: canonicalId,
                virtualCurrencyName: Ga4CurrencyNames.starCandy,
                baseAmount: baseAmount,
                bonusAmount: bonusAmount,
              ),
            ],
          ),
        );
        if (!persisted) {
          logger.e(
            'GA4 purchase outbox 저장 실패 — 스토어 거래는 정산되었지만 '
            '내구 재전송 항목을 남기지 못함: $resolvedTransactionId',
          );
          return;
        }
        // Outbox enqueue까지만 purchase 경로가 기다린다. Firebase 전송/재시도는
        // 스토어 finish/consume 및 사용자 UX와 독립적으로 진행된다.
        unawaited(outbox.flush());
        return;
      } finally {
        // durable gate를 outbox가 이어받았거나 enqueue가 실패했다. 어느 쪽이든
        // legacy 메모리 예약을 남겨 같은 키 후속 호출을 영구 대기시키지 않는다.
        legacyReservation.release();
      }
    }

    // Explicit legacy dependency is test-only. Production is the outbox branch
    // above, where payload persistence precedes store transaction finalization.
    final reservation = await _dedup.reserve(
      transactionId,
      fallbackKey: idempotencyFallbackKey,
    );
    if (reservation == null) return;

    logger.i('Purchase success: $storeProductId');

    var delivered = false;
    try {
      delivered = await PicnicAnalytics.instance
          .logPurchase(
            transactionId: resolvedTransactionId,
            currency: currency,
            value: value,
            items: <Ga4PurchaseItem>[
              Ga4PurchaseItem(
                itemId: canonicalId.toLowerCase(),
                itemName: canonicalId,
                // 구매로 지급되는 재화는 스타캔디 계열 하나다. 이름은 절대
                // 하드코딩하지 않는다 — 광고·투표와 같은 디멘션 값을 써야
                // GA4 에서 재화별 집계가 갈라지지 않는다.
                virtualCurrencyName: Ga4CurrencyNames.starCandy,
                baseAmount: baseAmount,
                bonusAmount: bonusAmount,
              ),
            ],
          )
          .timeout(sendTimeout);
    } on TimeoutException {
      // 포기한 future 는 계속 살아 있고 나중에 성공할 수도 있다. 그래도 예약은
      // 푼다: 매달아 두면 그 거래는 다시 시도조차 되지 않아 확실한 누락이고,
      // 풀면 최악이 중복 1건인데 GA4 는 같은 transaction_id 를 중복 제거한다.
      logger.e(
        'GA4 purchase 전송 시간 초과(${sendTimeout.inSeconds}s) — 예약을 해제해 '
        '다음 재전달에서 다시 시도한다: $resolvedTransactionId',
      );
    } catch (e, s) {
      // PicnicAnalytics 가 이미 삼키지만, 계약이 바뀌어도 예약이 새지 않게 한다.
      logger.e(
        'GA4 purchase 전송 실패: $resolvedTransactionId',
        error: e,
        stackTrace: s,
      );
    }

    if (!delivered) {
      reservation.release();
      return;
    }

    if (!await reservation.commit()) {
      // 보내기는 했는데 마커를 영속화하지 못했다. 같은 실행 안의 중복은
      // 메모리 마커가 막지만, 재시작 후 같은 거래가 다시 흘러오면 한 번 더
      // 나갈 수 있다. GA4 가 transaction_id 로 purchase 를 중복 제거하므로
      // 매출이 두 배가 되지는 않는다 — 그래서 이 방향을 택했다
      // (AnalyticsSendMarkerStore 의 "매출 누락 vs 중복" 참조).
      logger.e(
        'GA4 purchase 전송은 성공했으나 중복 마커 영속화 실패 — 재시작 후 '
        '같은 거래가 한 번 더 나갈 수 있다: $resolvedTransactionId',
      );
    }
  }

  /// 전송 자체에 허용하는 시간. 호출부가 더 짧게 잡을 수 있다.
  static const Duration defaultSendTimeout = Duration(seconds: 5);

  /// 스펙 외 커스텀 이벤트. 택소노미에 없는 자체 계측이라 그대로 둔다.
  Future<void> logPurchaseCancelEvent(String productId) async {
    try {
      logger.i('Purchase canceled: $productId');
      await FirebaseAnalytics.instance.logEvent(
        name: 'purchase_cancel',
        parameters: {'product_id': productId},
      );
    } catch (e, s) {
      logger.e('Error logging purchase cancel event', error: e, stackTrace: s);
    }
  }

  /// 스펙 외 커스텀 이벤트. 택소노미에 없는 자체 계측이라 그대로 둔다.
  Future<void> logPurchaseErrorEvent({
    required String productId,
    required String errorCode,
    required String errorMessage,
  }) async {
    try {
      logger.i(
        'Purchase error: $productId, code: $errorCode, message: $errorMessage',
      );
      await FirebaseAnalytics.instance.logEvent(
        name: 'purchase_error',
        parameters: {
          'product_id': productId,
          'error_code': errorCode,
          'error_message': errorMessage,
        },
      );
    } catch (e, s) {
      logger.e('Error logging purchase error event', error: e, stackTrace: s);
    }
  }

  String? _extractCurrency(ProductDetails product) {
    try {
      return product.currencyCode;
    } catch (_) {
      return null;
    }
  }

  num? _extractPrice(ProductDetails product) {
    try {
      return product.rawPrice;
    } catch (_) {
      return null;
    }
  }
}
