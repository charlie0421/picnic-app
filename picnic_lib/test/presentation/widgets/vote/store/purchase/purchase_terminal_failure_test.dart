import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';

/// Terminal-failure popup-noise regression (1.3.0 internal beta).
///
/// A purchase whose server settlement fails is shown an error dialog, but the
/// 90s per-product safety timer armed at launch used to stay alive: removing
/// only the attempt (`_removeAttempt`) leaves `_safetyTimersByProduct` armed,
/// so `onTimeoutUIReset` fires the "구매 처리 지연" popup after the user was
/// already told the purchase failed. The fixed `showMappedError` branch of
/// `_processActivePurchase` tears the product state down through
/// `_resetProductPurchaseState(..., terminal: true)` - mirrored by
/// [failTerminally] below - which stops that timer.
///
/// The genuinely-slow case must not change: an attempt that has seen no
/// terminal error still gets its one safety-timeout popup at 90s.
///
/// The collaborators are wired exactly the way
/// `PurchaseStarCandyState.initState` wires them.
void main() {
  const productId = 'STAR100';
  const attemptId = 'attempt-1';
  const launchSucceeded = <String, dynamic>{
    'success': true,
    'wasCancelled': false,
  };

  late PurchaseCampaignAttemptRegistry registry;
  late PurchaseSafetyManager manager;
  late int timeoutMessages;

  setUp(() {
    timeoutMessages = 0;
    registry = PurchaseCampaignAttemptRegistry();
    manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
    );
    manager.onTimeoutUIReset = () => timeoutMessages++;
    manager.onProductTimeout = (timedOutProduct, timedOutAttempt) {
      if (timedOutAttempt != null) {
        registry.removeIfMatches(timedOutProduct, timedOutAttempt);
      }
    };
  });

  tearDown(() => manager.disposeSafetyTimer());

  /// Runs the production launch sequence up to the point where the store event
  /// has been bound and receipt verification is in flight.
  Future<void> launch(String product, String id) async {
    registry.begin(
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      ),
    );
    manager.recordPurchaseAttempt(productId: product);
    registry.applyLaunchResult(product, id, launchSucceeded);
    await manager.handlePurchaseResult(
      launchSucceeded,
      registry.contains(product),
      (_) async {},
      productId: product,
      attemptId: id,
    );
  }

  /// Mirrors the terminal branch of `_processActivePurchase`'s error handler:
  /// `_resetProductPurchaseState(eventProductId, attemptId: ..., terminal:
  /// true)` for a mapped error that ends the attempt. [eventProductId] is the
  /// store event's casing, which on Android differs from the catalog ID the
  /// timer was armed with.
  void failTerminally(String eventProductId, String id) {
    expect(
      PurchaseProcessor.isTerminalMappedError(
        PurchaseProcessor.mapErrorToType('SERVER'),
      ),
      isTrue,
      reason: 'a server settlement error is the terminal failure under test',
    );
    manager.resetProductState(eventProductId);
    registry.removeIfMatches(eventProductId, id);
  }

  testWidgets('no delay popup fires after a terminal settlement failure', (
    tester,
  ) async {
    await launch(productId, attemptId);

    failTerminally(productId, attemptId);

    await tester.pump(const Duration(seconds: 91));

    expect(
      timeoutMessages,
      0,
      reason:
          'the user was already shown the error dialog; the 90s safety timer '
          'must be cancelled with the attempt or it raises the delay popup '
          'again',
    );
    expect(registry.contains(productId), isFalse);
  });

  testWidgets('the timer armed with the catalog ID is cancelled by the '
      'store-cased failure event', (tester) async {
    await launch(productId, attemptId);

    // Android: the timer started with STAR100, the failing Play event carries
    // star100. The teardown must meet it through the canonical product key.
    failTerminally('star100', attemptId);

    await tester.pump(const Duration(seconds: 91));

    expect(timeoutMessages, 0);
    expect(registry.contains(productId), isFalse);
  });

  testWidgets('a purchase that is merely slow still gets exactly one delay '
      'popup', (tester) async {
    await launch(productId, attemptId);

    // No terminal error arrives - verification is simply still in flight.
    await tester.pump(const Duration(seconds: 91));

    expect(
      timeoutMessages,
      1,
      reason: 'the safety net for a still-alive attempt must keep working',
    );
    expect(
      registry.contains(productId),
      isFalse,
      reason: 'onProductTimeout releases the attempt when the net fires',
    );

    await tester.pump(const Duration(seconds: 91));
    expect(timeoutMessages, 1, reason: 'the net fires once, not repeatedly');
  });

  testWidgets('mapped timeout, network and processing errors are never '
      'terminal', (tester) async {
    // These are the still-pending flavors: the settlement may yet land, so none
    // of them may take the terminal teardown path.
    for (final code in [
      'TIMEOUT',
      'NETWORK',
      PurchaseConstants.errProcessing,
    ]) {
      expect(
        PurchaseProcessor.isTerminalMappedError(
          PurchaseProcessor.mapErrorToType(code),
        ),
        isFalse,
        reason: '$code must not tear the attempt down',
      );
    }

    await launch(productId, attemptId);
    // The widget performs no terminal teardown for these errors...
    await tester.pump(const Duration(seconds: 91));
    // ...so the safety net still resolves the attempt exactly as today.
    expect(timeoutMessages, 1);
    expect(registry.contains(productId), isFalse);
  });

  // =========================================================================
  // C-1: 정산 미확정(PROCESSING) 결과의 UI 정리
  //
  // 실제 사고 시나리오: 서버가 정산 중인데(워커 리스 60초 + cron 재시도)
  // 클라이언트 예산(30초 × 재시도)이 먼저 끝난다. 예전에는 그 결과가
  // GENERIC → purchaseFailed 로 분류돼 "구매 중 오류가 발생했습니다. 나중에
  // 다시 시도해주세요" 가 떴고, 사용자는 그 안내를 따라 같은 소비형 상품을
  // 한 번 더 결제했다.
  //
  // 아래가 고정하는 것: 스피너 해제 · 재구매 쿨다운 · 안내는 정확히 한 번.
  // =========================================================================
  group('C-1 정산 미확정 결과', () {
    /// `_processActivePurchase` 의 정산 미확정 분기를 그대로 재현한다.
    /// 반환값은 "안내를 이미 한 번 보냈는지"(true 면 위젯은 다시 띄우지 않는다).
    bool settlementPending(String eventProductId, String id) {
      expect(
        PurchaseProcessor.isSettlementPending(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errProcessing),
        ),
        isTrue,
        reason: 'PROCESSING 이 이 분기로 들어오는 것이 전제다',
      );
      final alreadyAnnounced = manager.markSettlementPending(eventProductId);
      registry.removeIfMatches(eventProductId, id);
      return alreadyAnnounced;
    }

    testWidgets('스피너가 풀리고 재구매가 쿨다운으로 막힌다', (tester) async {
      await launch(productId, attemptId);
      expect(registry.contains(productId), isTrue, reason: '전제: 타일이 로딩 중');

      final alreadyAnnounced = settlementPending(productId, attemptId);

      expect(alreadyAnnounced, isFalse,
          reason: '안전망이 울리기 전이므로 이 결과가 안내의 주인이다');
      expect(registry.contains(productId), isFalse,
          reason: '스피너를 안 풀면 90초까지 무한 로딩으로 보인다');
      expect(manager.canAttemptPurchaseForProduct(productId), isFalse,
          reason: '재구매가 열려 있으면 사용자가 이중 과금할 수 있다');
      expect(manager.isSettlementPending(productId), isTrue,
          reason: '쿨다운 안내 문구가 "다시 결제하지 마세요" 로 갈려야 한다');
      expect(
        manager.remainingCooldownForProduct(productId)!.inMinutes,
        greaterThanOrEqualTo(4),
        reason: '서버 정산은 cron 재시도까지 수 분이 걸릴 수 있다',
      );
    });

    testWidgets('90초 지연 팝업이 뒤따라 뜨지 않는다', (tester) async {
      await launch(productId, attemptId);

      settlementPending(productId, attemptId);
      await tester.pump(const Duration(seconds: 91));

      expect(timeoutMessages, 0,
          reason: '접수 안내를 이미 띄운 뒤 같은 내용의 지연 팝업이 또 뜨면 '
              '한 실패에 다이얼로그가 두 장 겹친다 (C-4)');
    });

    testWidgets('안전망이 먼저 울렸으면 결과는 안내를 반복하지 않는다', (tester) async {
      // 예산 계산상 이쪽이 정상 순서다: 안전망 90초 < 30초×3 + 백오프.
      await launch(productId, attemptId);

      await tester.pump(const Duration(seconds: 91));
      expect(timeoutMessages, 1, reason: '안전망이 접수 안내를 띄웠다');

      final alreadyAnnounced = settlementPending(productId, attemptId);

      expect(alreadyAnnounced, isTrue,
          reason: '뒤늦게 도착한 정산 결과가 같은 안내를 두 번째로 띄우면 안 된다');
      expect(timeoutMessages, 1, reason: '안내는 정확히 한 번');
      expect(manager.canAttemptPurchaseForProduct(productId), isFalse,
          reason: '안전망이 상품을 활성 목록에서 뺐어도 재구매는 막혀야 한다');
    });

    testWidgets('Android 소문자 이벤트 ID 로도 정리된다', (tester) async {
      // 타이머는 카탈로그 ID(STAR100)로 무장되고 Play 이벤트는 star100 이다.
      await launch(productId, attemptId);

      settlementPending('star100', attemptId);
      await tester.pump(const Duration(seconds: 91));

      expect(timeoutMessages, 0);
      expect(registry.contains(productId), isFalse);
      expect(manager.canAttemptPurchaseForProduct(productId), isFalse);
    });

    testWidgets('다음 시도는 새 안내 사이클을 받는다', (tester) async {
      await launch(productId, attemptId);
      settlementPending(productId, attemptId);

      // 쿨다운이 끝난 뒤의 새 구매.
      manager.clearProductCooldown(productId);
      await launch(productId, 'attempt-2');

      expect(manager.markSettlementPending(productId), isFalse,
          reason: '이전 시도의 "이미 안내함" 표시가 남아 이번 시도의 안내를 '
              '삼키면 사용자는 아무 설명도 못 받는다');
    });
  });
}
