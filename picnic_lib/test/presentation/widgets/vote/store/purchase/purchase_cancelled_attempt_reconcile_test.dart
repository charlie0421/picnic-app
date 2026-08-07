import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_timeout_notice.dart';

/// 진행 중인 정상 결제를 지키는 규칙 - 무엇이 정리 **후보**가 되는가.
///
/// 세 라운드에 걸쳐 반례가 나온 지점이고, 그때마다 근거가 한 겹씩 바뀌었다.
///
/// 1라운드는 "스토어 큐가 비어 있었다" 하나로 등록된 시도를 전부 지웠다.
///    정산 대상이 없다는 것과 큐가 비었다는 것은 다르다 - iOS 스윕은
///    `purchasing`(사용자가 결제 시트 안에 있음)과 `deferred`(Ask to Buy
///    승인 대기)를 정산 대상에서 뺀다.
/// 2라운드는 거기에 "식별자 없는 종결 이벤트를 관측했다 + 그 관측보다 뒤에
///    시작된 시도는 제외" 를 더했다. iOS 는 이걸로 닫히지만 **Android 는
///    닫히지 않는다**:
///    - 관측 시각은 이벤트 **도착** 시각이지 발생 시각이 아니다. 지연된
///      이전 종결 이벤트가 현재 런치 뒤에 도착하면 시간 조건을 통과한다.
///    - `queryPastPurchases` 는 사용자가 들어가 있는 Play 결제 Activity 를
///      **어떤 쿼리로도 볼 수 없다**. 그래서 시트 안 사용자에게 큐는 항상
///      empty 로 답한다 (`liveInFlight` 는 iOS 전용 신호다).
///    두 개가 겹치면 지금 결제 중인 정상 시도가 지워졌다.
/// 3라운드(이 파일)는 큐를 더 정교하게 읽는 대신 **다른 증거원**을 쓴다.
///    후보가 되려면 그 시도의 결제 플로가 끝났다는 양성 증거가 필요하다:
///    - (b) 이 런치보다 **뒤에 성공한 런치**가 있다. 스토어는 동시에 하나의
///      결제 플로만 허용하므로, 이건 스토어 자신의 종료 증명이다.
///    - (a) 이 시도의 **결제 시트가 닫혔고**(lifecycle) 그 뒤로 종결 이벤트를
///      관측했다. Android 는 시트가 별도 Activity 라 시트가 떠 있는 동안
///      앱이 resumed 로 복귀하지 못한다 - 큐가 못 보는 것을 정확히 메운다.
///
/// 정리 **동작**(스냅샷, 단일 왕복, 미검증 큐, 화면 소멸)은
/// `purchase_stale_attempt_reconcile_test.dart`, 큐 실측의 `liveInFlight`
/// 판정은 `test/core/services/purchase_sweep_live_in_flight_test.dart`.
void main() {
  /// 사용자가 결제 시트를 닫고 앱으로 돌아와 있다.
  bool sheetClosed(String productId) => true;

  /// 사용자가 아직 그 상품의 Play 결제 시트 안에 있다 (Android: 런치 이후
  /// resumed 없음 + 지금도 비전면).
  bool sheetOpen(String productId) => false;

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

  group('Sol 3차 재검증 - Android 에서는 큐로 진행 중을 증명할 수 없다', () {
    test(
      '#2 사용자가 Play 결제 시트 안에 있는 동안 도착한 지연 종결 이벤트는 '
      '그 시도를 지우지 못한다 - Android 큐는 빈 것으로 답하지만 결제는 살아 '
      '있다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        // Android: buyConsumable 은 결제 시트가 **뜨자마자** true 로 돌아온다.
        // 즉 사용자가 시트 안에 있는 내내 launched == true 다.
        resolveLaunch(attempts, live);

        // 이전 시도의 종결 이벤트가 이제야 도착했다. 앱은 paused 라도 구매
        // 스트림은 계속 배달된다.
        attempts.recordIdentitylessTermination();

        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: sheetOpen),
          isEmpty,
          reason: '시트가 열려 있는 시도는 어떤 관측으로도 후보가 되지 않는다',
        );

        var scans = 0;
        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetOpen,
          // Android queryPastPurchases 의 실제 답: 소유된 구매가 없으므로
          // 비어 있고, liveInFlight 는 0 이다. 이 신호만으로는 진행 중인
          // 결제와 구분되지 않는다.
          verifyStoreQueueEmpty: () async {
            scans++;
            return true;
          },
        );

        expect(cleared, isEmpty);
        expect(
          attempts.contains('STAR100'),
          isTrue,
          reason: 'contains() 는 버튼 스피너이자 이중결제 가드다',
        );
        expect(scans, 0, reason: '후보가 없으면 스토어 왕복도 없다');
      },
    );

    test(
      '#1 지연된 이전 종결 이벤트가 현재 런치 뒤에 도착해도, 시트가 열려 '
      '있으면 시간 조건을 통과하는 것만으로는 지워지지 않는다',
      () async {
        var clock = DateTime.utc(2026, 8, 7, 12);
        final attempts = PurchaseCampaignAttemptRegistry(now: () => clock);

        // 상품 A 를 취소했다. 그 취소 이벤트는 아직 배달되지 않았다.
        final cancelled = attempt('STAR100', 'a-1');
        attempts.begin(cancelled);
        resolveLaunch(attempts, cancelled);

        // 사용자가 곧바로 상품 B 를 런치했고 지금 그 시트 안에 있다.
        clock = clock.add(const Duration(seconds: 5));
        final live = attempt('STAR200', 'b-1');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        // 이제서야 A 의 취소가 도착한다 - **B 의 런치보다 뒤**라서 시간
        // 조건(`!terminalAt.isBefore(launchedAt)`)은 B 도 통과시킨다.
        clock = clock.add(const Duration(seconds: 5));
        attempts.recordIdentitylessTermination();

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          // A 는 시트를 닫고 나왔고, B 는 아직 시트 안이다.
          isPaymentSheetClosed: (productId) => productId == 'STAR100',
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(
          attempts.contains('STAR200'),
          isTrue,
          reason: '진행 중인 B 는 시간 조건을 통과해도 시트가 열려 있어 지켜진다',
        );
      },
    );

    test(
      '#3 스토어 왕복 중에 도착한 새 취소 관측은 소진되지 않는다 - 소진하면 '
      '그 취소가 남긴 시도가 90초 안전망까지 스피너로 남는다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final first = attempt('STAR100', 'a-1');
        attempts.begin(first);
        resolveLaunch(attempts, first);
        attempts.recordIdentitylessTermination();

        final scanStarted = Completer<void>();
        final releaseScan = Completer<void>();

        final pending = reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
          verifyStoreQueueEmpty: () async {
            scanStarted.complete();
            await releaseScan.future;
            return true;
          },
        );

        await scanStarted.future;
        // 왕복이 도는 동안 사용자가 STAR200 을 런치했다가 취소했고, 그
        // 취소가 식별자 없이 도착했다. 이건 이 스윕이 확인한 사실이 아니다.
        final second = attempt('STAR200', 'b-1');
        attempts.begin(second);
        resolveLaunch(attempts, second);
        attempts.recordIdentitylessTermination();
        releaseScan.complete();

        expect((await pending).map((a) => a.productId), ['STAR100']);
        expect(
          attempts.hasIdentitylessTermination,
          isTrue,
          reason: '더 최신 관측은 살아남아 후속 정리를 정당화해야 한다',
        );

        // 후속 스윕이 실제로 STAR200 을 정리할 수 있다.
        final followUp = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
          verifyStoreQueueEmpty: () async => true,
        );
        expect(followUp.map((a) => a.productId), ['STAR200']);
        expect(attempts.isEmpty, isTrue);
      },
    );

    test(
      '왕복 중에 사용자가 시트로 되돌아간 시도는 스냅샷에 있어도 지워지지 '
      '않는다 - 후보 자격은 소진 전에 다시 계산한다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        resolveLaunch(attempts, a);
        attempts.recordIdentitylessTermination();

        var sheetIsClosed = true;
        final scanStarted = Completer<void>();
        final releaseScan = Completer<void>();

        final pending = reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: (_) => sheetIsClosed,
          verifyStoreQueueEmpty: () async {
            scanStarted.complete();
            await releaseScan.future;
            return true;
          },
        );

        await scanStarted.future;
        sheetIsClosed = false;
        releaseScan.complete();

        expect(await pending, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
      },
    );
  });

  /// 4라운드 반례: 시트 닫힘 판정을 **지금 resumed 인가**로 하면, Play 결제
  /// Activity 가 아직 전면에 오지 않은 런치 직후의 창에서 시트가 "닫힘"으로
  /// 오판된다. 거기에 지연된 이전 종결 관측이 겹치면 방금 시트를 띄운 시도가
  /// 후보가 되고, Android 큐는 그 결제를 볼 수 없어 empty 로 답하므로 결제
  /// 시트 안에 있는 사용자의 시도가 지워진다.
  ///
  /// 여기서는 production 배선(tracker → isPurchaseSheetProvenClosed →
  /// cancellationCandidates)을 그대로 조립해 검증한다.
  group('Sol 4차 재검증 - 런치 직후의 resumed 는 시트 닫힘이 아니다', () {
    late PurchaseLaunchLifecycleTracker tracker;
    late AppLifecycleState lifecycle;

    /// `PurchaseStarCandyState._isPaymentSheetClosed` 와 동일한 술어.
    bool provenClosed(String productId) {
      final observation = tracker.observationFor(productId);
      return isPurchaseSheetProvenClosed(
        leftForegroundSincePurchaseLaunch:
            observation.leftForegroundSinceLaunch,
        returnedToForegroundSincePurchaseLaunch:
            observation.returnedToForegroundSinceLaunch,
        currentLifecycleState: lifecycle,
      );
    }

    setUp(() {
      tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      lifecycle = AppLifecycleState.resumed;
    });

    test(
      'Android: 런치가 막 반환됐고 앱이 아직 resumed 인 시도는, 지연된 이전 '
      '종결 관측이 있어도 후보가 되지 않는다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);

        // Android: buyConsumable 은 결제 Activity 가 전면에 오기 **전에**
        // true 로 돌아온다 - 런치 호출이 도는 동안 비전면 전이가 없다.
        final exitsAtLaunchStart = tracker.foregroundExitCount;
        resolveLaunch(attempts, live);
        tracker.recordLaunch(
          'STAR100',
          foregroundExitsAtLaunchStart: exitsAtLaunchStart,
        );
        expect(lifecycle, AppLifecycleState.resumed, reason: '시트는 아직 뜨는 중');

        // 이전 시도의 종결 이벤트가 이제야 도착했다 (도착 시각은 이 런치보다
        // 뒤라 시간 조건을 통과한다).
        attempts.recordIdentitylessTermination();

        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: provenClosed),
          isEmpty,
          reason: '비전면 전이를 본 적이 없다 = 시트는 열리기 전이거나 열려 있다',
        );

        var scans = 0;
        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: provenClosed,
          // Android queryPastPurchases: 진행 중인 결제 Activity 는 안 보인다.
          verifyStoreQueueEmpty: () async {
            scans++;
            return true;
          },
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
        expect(scans, 0, reason: '후보가 없으면 스토어 왕복도 없다');
      },
    );

    test(
      'Android: 시트가 뜬 뒤(비전면)에도 후보가 아니고, 사용자가 닫고 돌아와야 '
      '비로소 정리된다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        final exitsAtLaunchStart = tracker.foregroundExitCount;
        resolveLaunch(attempts, a);
        tracker.recordLaunch(
          'STAR100',
          foregroundExitsAtLaunchStart: exitsAtLaunchStart,
        );
        attempts.recordIdentitylessTermination();

        // 시트가 전면에 왔다: inactive → paused.
        lifecycle = AppLifecycleState.inactive;
        tracker.recordLeftForeground();
        lifecycle = AppLifecycleState.paused;
        tracker.recordLeftForeground();
        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: provenClosed),
          isEmpty,
          reason: '나갔지만 아직 돌아오지 않았다 = 사용자가 시트 안에 있다',
        );

        // 사용자가 취소하고 앱으로 돌아왔다.
        lifecycle = AppLifecycleState.resumed;
        tracker.recordResumed();

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: provenClosed,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(
          cleared.map((a) => a.productId),
          ['STAR100'],
          reason: '원래 고치려던 결함(취소 후 스피너 잔존)은 그대로 고쳐져야 한다',
        );
      },
    );

    test(
      'iOS: 시트 사이클이 런치 호출 안에서 끝나므로 반환 직후에 이미 닫힘으로 '
      '인정된다 - 관찰 창이 런치 **요청** 시점부터라 플랫폼 분기가 필요 없다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);

        final exitsAtLaunchStart = tracker.foregroundExitCount;
        // StoreKit purchase() 가 도는 동안 시트가 떴다 닫힌다. resumed
        // 이벤트는 런치 반환보다 **먼저** 지나간다 (Sol 2차 MEDIUM-1).
        lifecycle = AppLifecycleState.inactive;
        tracker.recordLeftForeground();
        lifecycle = AppLifecycleState.resumed;
        tracker.recordResumed();

        resolveLaunch(attempts, a);
        tracker.recordLaunch(
          'STAR100',
          foregroundExitsAtLaunchStart: exitsAtLaunchStart,
        );
        attempts.recordIdentitylessTermination();

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: provenClosed,
          // iOS 는 사용자가 시트 안에 있으면 liveInFlight 로 false 가 된다.
          // 여기서는 이미 나온 상태라 큐가 비어 있다.
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
      },
    );

    test(
      '한 상품의 시트 전이가 다른 상품의 런치 직후 시도를 닫힘으로 만들지 '
      '않는다 - 전이는 그 시점에 살아 있는 관찰에만 붙는다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        // A: 시트를 열었다 닫고 나온 시도.
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        final exitsBeforeA = tracker.foregroundExitCount;
        resolveLaunch(attempts, a);
        tracker.recordLaunch(
          'STAR100',
          foregroundExitsAtLaunchStart: exitsBeforeA,
        );
        lifecycle = AppLifecycleState.paused;
        tracker.recordLeftForeground();
        lifecycle = AppLifecycleState.resumed;
        tracker.recordResumed();

        // B: 방금 런치했고 시트는 아직 뜨는 중.
        final b = attempt('STAR200', 'b-1');
        attempts.begin(b);
        final exitsBeforeB = tracker.foregroundExitCount;
        resolveLaunch(attempts, b);
        tracker.recordLaunch(
          'STAR200',
          foregroundExitsAtLaunchStart: exitsBeforeB,
        );

        attempts.recordIdentitylessTermination();

        // A 는 증거 (b)(뒤이은 런치)로도, 증거 (a)(시트 닫힘)로도 후보다.
        // B 는 어느 쪽으로도 후보가 아니어야 한다.
        expect(
          attempts
              .cancellationCandidates(isPaymentSheetClosed: provenClosed)
              .map((a) => a.productId),
          ['STAR100'],
        );
        expect(provenClosed('STAR200'), isFalse);
      },
    );
  });

  group('증거 (b) - 뒤이은 런치 성공이 이전 플로의 종료를 증명한다', () {
    test(
      '취소 이벤트가 아예 도착하지 않아도, 다음 상품의 런치가 성공하면 이전 '
      '시도의 스피너가 내려간다 - 스토어는 동시에 하나의 결제 플로만 허용한다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        resolveLaunch(attempts, a);

        // 관측된 종결 이벤트가 하나도 없다 - 증거 (a) 는 성립하지 않는다.
        expect(attempts.hasIdentitylessTermination, isFalse);
        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: sheetClosed),
          isEmpty,
        );

        // 사용자가 상품 B 를 런치했고 스토어가 그 플로를 받아들였다.
        final b = attempt('STAR200', 'b-1');
        attempts.begin(b);
        resolveLaunch(attempts, b);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          // Android: B 의 시트가 떠 있으므로 아무 시트도 닫혀 있지 않다.
          // 증거 (a) 는 여전히 성립하지 않는다 - 순수하게 (b) 만으로 지운다.
          isPaymentSheetClosed: sheetOpen,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(
          attempts.contains('STAR200'),
          isTrue,
          reason: '방금 런치한 시도는 자기 자신이 최신이라 (b) 가 성립하지 않는다',
        );
      },
    );

    test(
      '뒤이은 런치가 있어도 스토어 큐가 비어 있지 않으면 지우지 않는다 - '
      '플로가 끝났다는 것과 돈을 남기지 않았다는 것은 다른 사실이다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        resolveLaunch(attempts, a);
        final b = attempt('STAR200', 'b-1');
        attempts.begin(b);
        resolveLaunch(attempts, b);

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
          // A 가 실제로 결제됐고 이벤트만 늦은 경우: Play 는 그 구매를
          // 소유된 것으로 답하고 StoreKit 은 큐에 들고 있다 → found > 0.
          verifyStoreQueueEmpty: () async => false,
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
      },
    );

    test(
      '런치 순번은 시도당 한 번만 부여된다 - 런치 결과가 두 번 적용돼도 '
      '이전 시도의 종료 증명이 사라지지 않는다',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final a = attempt('STAR100', 'a-1');
        attempts.begin(a);
        resolveLaunch(attempts, a);
        final b = attempt('STAR200', 'b-1');
        attempts.begin(b);
        resolveLaunch(attempts, b);
        // 같은 런치 결과가 다시 적용된다.
        resolveLaunch(attempts, b);

        expect(
          attempts
              .cancellationCandidates(isPaymentSheetClosed: sheetOpen)
              .map((a) => a.productId),
          ['STAR100'],
        );
      },
    );
  });

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
          isPaymentSheetClosed: sheetClosed,
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
      'an in-progress iOS attempt survives a delayed identity-less '
      'cancellation because the store queue still reports a live payment - '
      'iOS keeps the lifecycle-independent half of the proof',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);

        // 이전 시도의 취소 이벤트가 늦게 도착했다. iOS 는 결제 시트가 앱
        // 안에 떠 있어 lifecycle 로는 시트 안/밖을 구분하지 못할 수 있다 -
        // 그래서 `SKPaymentQueue` 의 purchasing/deferred 가 답해야 한다.
        attempts.recordIdentitylessTermination();
        expect(
          attempts
              .cancellationCandidates(isPaymentSheetClosed: sheetClosed)
              .map((a) => a.attemptId),
          ['live'],
        );

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
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
          isPaymentSheetClosed: sheetClosed,
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

        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: sheetClosed),
          isEmpty,
        );

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
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
        var clock = DateTime.utc(2026, 8, 7, 12);
        final attempts = PurchaseCampaignAttemptRegistry(now: () => clock);
        final live = attempt('STAR100', 'live');
        attempts.begin(live);
        resolveLaunch(attempts, live);
        expect(
          attempts.bind(transaction('STAR100', 'txn-1'))?.attemptId,
          'live',
        );

        clock = clock.add(const Duration(seconds: 1));
        attempts.recordIdentitylessTermination();
        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: sheetClosed),
          isEmpty,
        );

        // 뒤이은 런치가 증거 (b) 를 세워도 마찬가지다 - 묶인 트랜잭션은
        // UI 상태가 아니라 정산 중인 실결제다.
        clock = clock.add(const Duration(seconds: 1));
        final b = attempt('STAR200', 'b-1');
        attempts.begin(b);
        resolveLaunch(attempts, b);
        expect(
          attempts.cancellationCandidates(isPaymentSheetClosed: sheetClosed),
          isEmpty,
        );

        final cleared = await reconcileCancelledAttemptsIfQueueEmpty(
          attempts: attempts,
          isPaymentSheetClosed: sheetClosed,
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
          isPaymentSheetClosed: sheetClosed,
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
          isPaymentSheetClosed: sheetClosed,
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
          isPaymentSheetClosed: sheetClosed,
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
