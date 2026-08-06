import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_timeout_notice.dart';

/// 90초 안전망 타임아웃 문구 분기 (Android 결제창 방치 케이스).
///
/// 실제 스토어 플러그인 채널·Play 결제 시트까지 위젯 테스트로 재현하기는
/// 어렵다는 것이 기존 핸드오프의 결론이므로, 여기서는
/// (1) 문구를 고르는 순수 함수 [resolvePurchaseTimeoutNotice] 의 전 조합,
/// (2) production 이 쓰는 [PurchaseLaunchLifecycleTracker] 의 상품별 관찰,
/// (3) PurchaseSafetyManager 의 상품별 타이머 → onTimeoutUIReset(productId)
///     → tracker 조회로 이어지는 배선에서, 서로 다른 상품의 시도가 공존할 때
///     각 시도가 자기 관찰값으로 문구를 고르는지 (다중 시도 귀속 회귀)
/// 를 검증한다.
void main() {
  group('resolvePurchaseTimeoutNotice', () {
    test('Android: 런치 후 resumed 이벤트가 없고 앱이 전면도 아니면 미확정 문구', () {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.detached,
        null,
      ]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: false,
            resumedSincePurchaseLaunch: false,
            currentLifecycleState: state,
          ),
          PurchaseTimeoutNotice.paymentUnconfirmed,
          reason: 'lifecycleState=$state 는 결제 시트 안일 수 있다',
        );
      }
    });

    test('Android: resumed 이벤트가 한 번이라도 있었으면 기존 접수 문구 유지', () {
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.paused,
        null,
      ]) {
        expect(
          resolvePurchaseTimeoutNotice(
            isIOS: false,
            resumedSincePurchaseLaunch: true,
            currentLifecycleState: state,
          ),
          PurchaseTimeoutNotice.paymentAccepted,
          reason: '시트를 닫고 나온 사용자는 정산 대기 안내를 받아야 한다',
        );
      }
    });

    test('Android: resumed 이벤트를 놓쳤어도 지금 전면이면 기존 접수 문구 유지', () {
      expect(
        resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: false,
          currentLifecycleState: AppLifecycleState.resumed,
        ),
        PurchaseTimeoutNotice.paymentAccepted,
      );
    });

    test('iOS: 어떤 조합에서도 기존 접수 문구를 유지한다 (회귀 금지)', () {
      for (final resumed in [true, false]) {
        for (final state in [
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
          AppLifecycleState.paused,
          null,
        ]) {
          expect(
            resolvePurchaseTimeoutNotice(
              isIOS: true,
              resumedSincePurchaseLaunch: resumed,
              currentLifecycleState: state,
            ),
            PurchaseTimeoutNotice.paymentAccepted,
            reason: 'iOS 는 SK2 블로킹 반환이라 이 분기가 동작하면 안 된다 '
                '(resumed=$resumed, state=$state)',
          );
        }
      }
    });
  });

  group('PurchaseLaunchLifecycleTracker', () {
    test('런치 기록이 없는 상품과 null(전역 타이머)은 접수 문구 쪽으로 판정된다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      expect(tracker.resumedSinceLaunch(null), isTrue);
      expect(tracker.resumedSinceLaunch('UNKNOWN'), isTrue);
    });

    test('런치 → resumed 순서를 상품별로 기록한다', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('STAR100'), isFalse);

      tracker.recordResumed();
      expect(tracker.resumedSinceLaunch('STAR100'), isTrue);

      // 같은 상품의 새 런치는 관찰을 다시 시작한다.
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('STAR100'), isFalse);
    });

    test('다른 상품의 런치가 이전 시도의 이력을 덮지 않는다 (Sol 리뷰 회귀)', () {
      final tracker = PurchaseLaunchLifecycleTracker();
      // A 런치 → 사용자가 A 시트를 닫고 나옴 (resumed).
      tracker.recordLaunch('STAR100');
      tracker.recordResumed();
      // A 의 시도·타이머가 남은 상태에서 B 런치 → B 시트 방치.
      tracker.recordLaunch('STAR200');

      expect(tracker.resumedSinceLaunch('STAR100'), isTrue,
          reason: 'A 는 시트를 닫고 나왔으므로 접수 문구를 받아야 한다');
      expect(tracker.resumedSinceLaunch('STAR200'), isFalse,
          reason: 'B 는 아직 시트 안일 수 있으므로 미확정 문구를 받아야 한다');
    });

    test('안전망 타이머와 같은 canonical 상품 키를 쓸 수 있다 (STAR100 vs star100)', () {
      final tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      tracker.recordLaunch('STAR100');
      expect(tracker.resumedSinceLaunch('star100'), isFalse);
      tracker.recordResumed();
      expect(tracker.resumedSinceLaunch('star100'), isTrue);
      tracker.clear('star100');
      expect(tracker.resumedSinceLaunch('STAR100'), isTrue);
    });
  });

  group('PurchaseSafetyManager onTimeoutUIReset(productId) 배선', () {
    late PurchaseSafetyManager manager;
    late PurchaseLaunchLifecycleTracker tracker;
    late Map<String, String> shownMessageKeyByProduct;

    setUp(() {
      tracker = PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
      shownMessageKeyByProduct = {};
      manager = PurchaseSafetyManager(
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        resetPurchaseState: () {},
      );
      // purchase_star_candy_state.dart 의 onTimeoutUIReset 콜백과 동일한
      // 분기 구조: 타이머가 알려 준 productId → tracker 조회 → resolver.
      manager.onTimeoutUIReset = (productId) {
        final notice = resolvePurchaseTimeoutNotice(
          isIOS: false,
          resumedSincePurchaseLaunch: tracker.resumedSinceLaunch(productId),
          // 방치 시나리오: 앱은 Play 시트 뒤에서 paused 상태다.
          currentLifecycleState: AppLifecycleState.paused,
        );
        tracker.clear(productId);
        shownMessageKeyByProduct[productId ?? '<global>'] =
            notice == PurchaseTimeoutNotice.paymentUnconfirmed
                ? 'purchase_payment_unconfirmed_message'
                : 'purchase_payment_accepted_message';
      };
    });

    tearDown(() {
      manager.disposeSafetyTimer();
    });

    testWidgets('런치 후 resumed 없이 90초 경과 시 미확정 문구를 고른다', (tester) async {
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_unconfirmed_message',
      );
      expect(manager.isSafetyTimeoutTriggered, isTrue);
    });

    testWidgets('resumed 를 받은 시도는 90초 경과 시 기존 접수 문구를 고른다', (tester) async {
      tracker.recordLaunch('STAR100');
      tracker.recordResumed();
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
      );
    });

    testWidgets('타이머 공존 시 각 시도가 자기 관찰값으로 문구를 고른다 (Sol 리뷰 회귀)',
        (tester) async {
      // A 런치 → A 시트 닫고 나옴(resumed) → A 타이머는 식별자 없는
      // 취소로 정리되지 못하고 잔존 → B 런치 → B 시트 방치.
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-a');
      tracker.recordResumed();
      tracker.recordLaunch('STAR200');
      manager.startSafetyTimer(productId: 'STAR200', attemptId: 'attempt-b');

      await tester.pump(const Duration(seconds: 91));

      expect(
        shownMessageKeyByProduct['STAR100'],
        'purchase_payment_accepted_message',
        reason: 'A 는 시트를 닫고 나왔다 - B 의 런치가 A 의 이력을 덮으면 안 된다',
      );
      expect(
        shownMessageKeyByProduct['STAR200'],
        'purchase_payment_unconfirmed_message',
        reason: 'B 는 방치 상태다',
      );
    });

    testWidgets('타이머가 정상 중지되면 어떤 문구도 뜨지 않는다', (tester) async {
      tracker.recordLaunch('STAR100');
      manager.startSafetyTimer(productId: 'STAR100', attemptId: 'attempt-1');
      manager.stopSafetyTimer(productId: 'STAR100');
      await tester.pump(const Duration(seconds: 91));

      expect(shownMessageKeyByProduct, isEmpty);
    });
  });
}
