import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

/// Sol 교차 리뷰 MAJOR (2026-08-07) 의 반례들.
///
/// 앞선 구현은 "스토어 큐가 비어 있었다" 하나만으로 등록된 시도를 **전부**
/// 지웠다. 그런데 정산 대상(iOS `purchased`)이 없다는 것과 큐가 비었다는 것은
/// 다르다 - iOS 스윕은 `purchasing`(사용자가 결제 시트 안에 있음)과
/// `deferred`(Ask to Buy 승인 대기)를 정산 대상에서 빼고, Android
/// `queryPastPurchases` 는 진행 중인 빌링 플로를 아예 못 본다. 즉 **지금
/// 결제가 진행 중인 정상 시도가 있어도 큐는 비어 보인다.**
///
/// 그래서 다른 상품 탭이나 지연된 식별자 없는 취소가 스윕을 시작하면, 진행
/// 중인 정상 시도와 그 시도의 이중결제 가드(`contains(productId)` 는 버튼
/// 스피너인 동시에 `_canPurchase` 의 차단 조건이다)까지 지워질 수 있었다.
///
/// 수정은 큐 empty 를 stale 증명으로 쓰지 않는 것이다. 정리는 두 증거의
/// 교차로만 한다:
///
/// 1. [PurchaseCampaignAttemptRegistry.cancellationCandidates] - 시도별
///    양성 증거(런치 반환됨 + 묶인 트랜잭션 없음 + 이 시도가 시작된 뒤에
///    종결 이벤트를 관측함)
/// 2. 스토어 큐 실측 - 정산 대상도 살아 있는 결제도 없음
///    ([PurchaseSweepReport.verifiedEmpty], `liveInFlight == 0` 포함)
///
/// 이 파일은 (1) 을 본다. (2) 는
/// `test/core/services/purchase_sweep_live_in_flight_test.dart`.
void main() {
  PurchaseCampaignAttempt attempt(String productId, String attemptId) =>
      PurchaseCampaignAttempt(
        attemptId: attemptId,
        productId: productId,
        displayedCampaign: null,
      );

  void resolveLaunch(
    PurchaseCampaignAttemptRegistry registry,
    PurchaseCampaignAttempt a,
  ) {
    registry.applyLaunchResult(a.productId, a.attemptId, const {
      'success': true,
      'wasCancelled': false,
    });
  }

  PurchaseDetails transaction(String product, String transactionId) =>
      PurchaseDetails(
        productID: product,
        purchaseID: transactionId,
        transactionDate: DateTime.utc(2027).millisecondsSinceEpoch.toString(),
        status: PurchaseStatus.purchased,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
      );

  group('protects a purchase that is still in progress', () {
    test(
      'an attempt that was already live before the scan survives a sweep '
      'triggered with no observed cancellation at all - an empty queue is not '
      'proof of staleness',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        var scans = 0;
        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          // 사용자가 결제 시트 안에 있는 동안 iOS 스윕이 보고하는 값.
          verifyStoreQueueEmpty: () async {
            scans++;
            return true;
          },
        );

        expect(cleared, isEmpty);
        expect(
          attempts.contains('STAR100'),
          isTrue,
          reason: 'contains() is also the double-charge guard',
        );
        expect(scans, 0, reason: 'no candidate, no store round trip');
      },
    );

    test(
      'an in-progress attempt survives a delayed identity-less cancellation '
      'from an earlier attempt, because the store queue still reports a live '
      'payment',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        // 이전 시도의 취소 이벤트가 늦게 도착했다. 시간 순서만으로는 이
        // 시도와 구분되지 않는다 - 큐 실측이 답해야 하는 지점이다.
        attempts.recordIdentitylessTermination();
        expect(attempts.cancellationCandidates.map((a) => a.attemptId), [
          'live',
        ]);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          // liveInFlight > 0 → verifiedEmpty == false.
          verifyStoreQueueEmpty: () async => false,
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
      },
    );

    test(
      'an attempt launched after the observed cancellation is never a '
      'candidate',
      () async {
        var clock = DateTime.utc(2026, 8, 7, 12);
        final attempts = PurchaseCampaignAttemptRegistry(now: () => clock);

        final cancelled = attempt('STAR100', 'cancelled');
        attempts.begin(cancelled);
        resolveLaunch(attempts, cancelled);

        clock = clock.add(const Duration(seconds: 5));
        attempts.recordIdentitylessTermination();

        clock = clock.add(const Duration(seconds: 5));
        final live = attempt('STAR200', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(
          attempts.contains('STAR200'),
          isTrue,
          reason: 'the cancellation happened before this purchase existed',
        );
      },
    );

    test(
      'an attempt whose launch call has not returned yet is never a candidate '
      '- initiatePurchase is still running, so the payment is live',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        attempts.begin(attempt('STAR100', 'launching'));
        attempts.recordIdentitylessTermination();

        expect(attempts.cancellationCandidates, isEmpty);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
      },
    );

    test(
      'an attempt with a bound store transaction is never a candidate - that '
      'is a real payment being settled, not UI state',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);
        expect(
          attempts.bind(transaction('STAR100', 'txn-1'))?.attemptId,
          'live',
        );

        attempts.recordIdentitylessTermination();
        expect(attempts.cancellationCandidates, isEmpty);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared, isEmpty);
        expect(
          attempts.contains('STAR100'),
          isTrue,
          reason: 'clearing this would drop the receipt and the safety net',
        );
      },
    );

    test(
      'the in-progress attempt survives while a genuinely cancelled sibling '
      'is cleared in the same sweep',
      () async {
        var clock = DateTime.utc(2026, 8, 7, 12);
        final attempts = PurchaseCampaignAttemptRegistry(now: () => clock);

        final cancelled = attempt('STAR100', 'cancelled');
        attempts.begin(cancelled);
        resolveLaunch(attempts, cancelled);
        clock = clock.add(const Duration(seconds: 1));
        attempts.recordIdentitylessTermination();

        // 같은 화면에서 사용자가 곧바로 다른 상품을 눌렀고, 그 런치는 아직
        // 스토어 안에 있다.
        clock = clock.add(const Duration(seconds: 1));
        attempts.begin(attempt('STAR200', 'launching'));

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(attempts.contains('STAR200'), isTrue);
      },
    );

    test(
      'one observed cancellation does not license every future cleanup - it '
      'is consumed by the sweep that verified the queue',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final cancelled = attempt('STAR100', 'a-1');
        attempts.begin(cancelled);
        resolveLaunch(attempts, cancelled);
        attempts.recordIdentitylessTermination();

        await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );
        expect(attempts.hasIdentitylessTermination, isFalse);

        // 사용자가 이제 STAR200 을 산다. 앞선 취소 관측이 남아 있었다면 이
        // 시도가 후보가 되어, 큐가 비어 보이는 순간 지워졌을 것이다.
        final live = attempt('STAR200', 'b-1');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        var scans = 0;
        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async {
            scans++;
            return true;
          },
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR200'), isTrue);
        expect(scans, 0);
      },
    );
  });
}
