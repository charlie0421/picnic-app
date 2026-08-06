import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

// PurchaseSafetyManager 타입 선언 (순환 import 방지)
abstract class PurchaseSafetyManagerInterface {
  bool canAttemptPurchase();
}

/// 🧹 복원 구매 전용 핸들러 - 예방적 정리 및 차단 기능
class RestorePurchaseHandler {
  final PurchaseService _purchaseService;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey;
  final BuildContext _context;

  // 🎯 활성 구매 확인을 위한 안전망 참조
  PurchaseSafetyManagerInterface? _safetyManager;

  bool _isProactiveCleanupMode = false;
  bool _isProactiveCleanupCompleted = false;
  Timer? _pulseLoadingTimer;

  RestorePurchaseHandler({
    required PurchaseService purchaseService,
    required GlobalKey<LoadingOverlayWithIconState> loadingKey,
    required BuildContext context,
  })  : _purchaseService = purchaseService,
        _loadingKey = loadingKey,
        _context = context;

  /// 🎯 안전망 매니저 설정 (순환 의존성 방지)
  void setSafetyManager(PurchaseSafetyManagerInterface safetyManager) {
    _safetyManager = safetyManager;
  }

  /// 페이지 진입 시 예방적 미완료 구매 정리 실행
  ///
  /// 예전에는 [InAppPurchaseService.restorePurchases]를 호출하고 완료
  /// 신호가 없는 그 API 특성상 700ms~10초를 "조용해질 때까지" 추측하며
  /// 기다렸다 - 소비성 상품(별사탕)은 애초에 스토어의 restore 대상도
  /// 아니라 이 호출 자체가 목적에 안 맞았다. 지금은 [GlobalPurchaseListener]
  /// 의 콜드스타트/재개 스윕과 같은 경로([PurchaseService.sweepUnfinishedPurchases])
  /// 로 큐를 직접 읽는다 - 완료 신호가 진짜로 있어서 기다릴 이유가 없으면
  /// 즉시 끝난다.
  Future<void> performProactiveCleanup() async {
    final platform = Theme.of(_context).platform;
    final startTime = DateTime.now();

    try {
      logger.i('🧹 예방적 미완료 구매 정리 시작 (${platform.name})');

      _showPulseLoading();
      _isProactiveCleanupMode = true;

      final verified = await _sweepUntilResolved();

      // 정리가 100ms 안에 끝났으면(이제 흔한 경우) 아직 안 보인 스피너를
      // 마저 띄우는 지연 타이머를 취소한다 - 안 그러면 화면이 이미 숨긴
      // 뒤에 스피너가 다시 튀어나와 걸린 채로 남는다.
      _pulseLoadingTimer?.cancel();
      _pulseLoadingTimer = null;

      _isProactiveCleanupMode = false;
      // 큐를 실제로 확인해서 비어 있었을 때만 구매를 허용한다. 확인하지
      // 못한 채(failed/notSignedIn/unsupported/throttled/경합 끝 포기)
      // 이 플래그를 세우면, 그 값을 그대로 신뢰하는 _processPurchase 의
      // 가드(isProactiveCleanupCompleted)가 "확인 못 했다"를 "확인해보니
      // 안전했다"로 오인해 미검증 상태에서 구매를 열어준다. 로딩 화면
      // 자체는 이 함수가 반환하는 순간 어차피 풀리므로(_isInitializing 은
      // 이 Future 완료만 본다), 여기서 실패를 그대로 두어도 무한 스피너가
      // 되지는 않는다 - 다만 재시도하려면 화면을 나갔다 다시 들어와야
      // 한다(새 RestorePurchaseHandler 로 다시 시도).
      _isProactiveCleanupCompleted = verified;

      final duration = DateTime.now().difference(startTime);
      logger.i(
        '🧹 예방적 정리 ${verified ? '완료' : '미검증 종료'} - ${duration.inMilliseconds}ms',
      );
    } catch (e) {
      logger.e('🧹 예방적 정리 오류: $e');
      _cleanupState();
    }
  }

  /// 앱의 콜드스타트/재개 스윕이 아직 돌고 있으면 [PurchaseSweepOutcome.concurrent]
  /// 로 즉시 돌아온다. 이 화면은 attachSurface() 로 진입 시점에 이미
  /// surface 로 등록되는데, 등록된 surface 는 진행 중이던 전역 스윕을
  /// abort 시킨다([GlobalPurchaseListener.sweepOnColdStart]/`sweepOnResume`
  /// 의 shouldAbort). 즉 "잠깐 기다렸다 포기"하면 전역 스윕은 abort 로
  /// 끝나고 이 화면의 재시도도 concurrent 만 반복하다 포기해, 어느 쪽도
  /// 큐를 실제로 확인하지 못한 채 구매가 열릴 수 있다. 고정 시간을 재시도
  /// 간격으로 추측하는 대신, 경합 중인 스윕이 실제로 끝나는 신호
  /// ([PurchaseService.waitForInFlightSweep])를 기다린 뒤 우리 스윕을
  /// 다시 시도한다.
  ///
  /// `true` 를 반환하는 건 "큐를 실제로 확인했고 비어 있었다" 뿐이다.
  /// 그 외(failed/notSignedIn/unsupported/throttled/경합 끝 포기)는
  /// 전부 `false` - 호출자가 이 결과를 "구매해도 안전하다"는 뜻으로
  /// 오인하지 않도록, 여기서 outcome 을 감추지 않고 그대로 반환한다.
  Future<bool> _sweepUntilResolved() async {
    final report = await resolveStoreQueueSweep();
    if (report == null) return false;
    // completed 는 "큐를 확인했고 비어 있었다"만 의미해야 한다.
    // scanError 가 같이 와 있다면(정상적으로는 PurchaseService 가 그런
    // 경우 failed 를 돌려주지만, 방어적으로 다시 확인한다) "확인 못
    // 했다"를 "확인해보니 없었다"로 오인한 것이니 검증된 것으로 치지
    // 않는다. preserved > 0 도 마찬가지다 - abort 되지 않아 outcome 은
    // completed 라도, 검증에 실패했거나 지급 미확인이라 큐에 그대로
    // 남겨둔 항목이 있다는 뜻이라 "비어 있었다"가 아니다
    // (_reconcileUnfinishedPurchases 의 catch 분기 참고).
    if (report.outcome == PurchaseSweepOutcome.completed &&
        report.scanError == null &&
        report.preserved == 0) {
      return true;
    }
    logger.w('🧹 미완료 구매 확인 실패(${report.outcome.name}) - 검증되지 않음');
    return false;
  }

  /// 스토어 큐 스윕을 경합이 풀릴 때까지 재시도해 **결과 리포트**를 돌려준다.
  ///
  /// 경합이 끝내 풀리지 않으면 null - 호출자는 이것을 "확인 실패"로 다뤄야
  /// 한다. [verifyStoreQueueClean] 의 boolean 은 이 리포트의 요약인데, 90초
  /// 안전망의 "사실상 취소" 팝업 생략 판정처럼 **큐가 애초에 비어
  /// 있었는지(found==0)** 와 **방금 뭔가를 정산했는지(settled>0)** 를
  /// 구분해야 하는 호출자는 리포트를 직접 봐야 한다 - 스윕이 발견 즉시
  /// 정산에 성공하면 boolean 요약은 true 가 되어 "비어 있었다"와 "방금
  /// 실결제를 처리했다"가 구분되지 않는다 (Sol 머지 게이트 리뷰, PR #137).
  Future<PurchaseSweepReport?> resolveStoreQueueSweep() async {
    const maxAttempts = 3;
    const inFlightWaitTimeout = Duration(seconds: 8);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final report = await _purchaseService.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );
      if (report.outcome != PurchaseSweepOutcome.concurrent) {
        return report;
      }
      await _purchaseService
          .waitForInFlightSweep()
          .timeout(inFlightWaitTimeout, onTimeout: () {});
    }
    logger.w('🧹 미완료 구매 스윕이 계속 다른 스윕과 경합 - 검증 없이 재시도 포기');
    return null;
  }

  /// 큐를 실제로 다시 확인해 비어 있는지 검증한다.
  ///
  /// [performProactiveCleanup]과 같은 신호([_sweepUntilResolved])를
  /// 재사용한다 - 예를 들어 거래ID 없는 취소/실패 이벤트 때문에 90초
  /// 안전망까지 레지스트리에 남아있는 시도가, 재구매를 다시 시도하는
  /// 시점에 실제로도 스토어에 걸려있는지 확인할 때 쓴다.
  Future<bool> verifyStoreQueueClean() => _sweepUntilResolved();

  /// 펄스 로딩 표시
  void _showPulseLoading() {
    final platform = Theme.of(_context).platform;
    final platformEmoji = platform == TargetPlatform.iOS ? '📱' : '🤖';

    logger.i('🔄 펄스 로딩 시작: $platformEmoji 복원 구매 정리 중');

    _loadingKey.currentState?.hide();
    // 짧게 끝나는 정리에는 스피너를 아예 안 보여주는 디바운스다 - 100ms
    // 안에 정리가 끝나면 [performProactiveCleanup] 이 이 타이머를
    // 취소한다. 예전엔 정리 자체가 항상 700ms+ 걸려서 취소할 일이 없었는데
    // (그래서 참조를 안 남겨도 티가 안 났다), 이제는 대부분 이 창 안에
    // 끝나므로 참조를 안 남기면 이미 화면이 숨긴 뒤에 스피너가 다시
    // 튀어나와 걸린 채로 남는다.
    _pulseLoadingTimer = Timer(Duration(milliseconds: 100), () {
      _loadingKey.currentState?.show();
    });
  }

  /// 복원 구매 처리 여부 확인 - 🍎 iOS/🤖 Android 플랫폼별 처리
  bool shouldProcessRestored(PurchaseDetails purchaseDetails) {
    final platform = Platform.isIOS ? 'iOS' : 'Android';

    // 📱 iOS와 🤖 Android 완전 분리 처리
    if (Platform.isIOS) {
      return _shouldProcessRestoredIOS(purchaseDetails, platform);
    } else {
      return _shouldProcessRestoredAndroid(purchaseDetails, platform);
    }
  }

  /// 🍎 iOS 전용 복원 처리 판별 - 정상 구매 보호
  bool _shouldProcessRestoredIOS(
      PurchaseDetails purchaseDetails, String platform) {
    // 🎯 연속 구매 보호: 현재 구매 진행 중이면 복원 신호도 정상 구매 가능성!
    final isActivePurchasing = _safetyManager?.canAttemptPurchase() ==
        false; // canAttemptPurchase() == false는 구매 진행 중을 의미

    // 🍎 1단계: 정리 완료 후 순수 복원 신호는 차단 (단, 활성 구매 중이면 허용!)
    if (_isProactiveCleanupCompleted &&
        purchaseDetails.status == PurchaseStatus.restored) {
      // 🎯 활성 구매 진행 중이면 복원 신호라도 정상 구매로 처리!
      if (isActivePurchasing) {
        logger.i('[iOS] 🎯 연속 구매 보호: 활성 구매 중인 restored 신호 → 정상 구매로 처리');
        return false; // false = 복원 처리 안함, 활성 구매 검증으로 넘어감
      }

      // 활성 구매가 아닌 순수 복원 신호는 차단
      logger.w('[iOS] 🛡️ 정리 완료 후 순수 복원 신호 무시: ${purchaseDetails.productID}');
      return false;
    }

    // 🍎 2단계: iOS 특성 - restored 상태도 정상 구매일 수 있음!
    if (purchaseDetails.status == PurchaseStatus.restored) {
      // 🍎 iOS는 restored도 정상 구매 가능성 있으므로 다음 단계로 넘김
      // shouldProcessActivePurchase에서 실제 구매 여부 검증하도록 함
      logger.i('[iOS] 🍎 iOS 특성: restored 상태지만 정상 구매 가능성 - 다음 단계로 위임');
      return false; // false = 복원 처리 안함, 다음 단계(활성 구매 검증)로 넘어감
    }

    return false;
  }

  /// 🤖 Android 전용 복원 처리 판별 - 엄격한 차단
  bool _shouldProcessRestoredAndroid(
      PurchaseDetails purchaseDetails, String platform) {
    // 🤖 1단계: 정리 완료 후 복원 신호는 무조건 차단
    if (_isProactiveCleanupCompleted &&
        purchaseDetails.status == PurchaseStatus.restored) {
      logger.w('[Android] 🛡️ 정리 완료 후 복원 신호 무시: ${purchaseDetails.productID}');
      return false;
    }

    // 🤖 2단계: Android는 restored 상태를 엄격하게 차단
    if (purchaseDetails.status == PurchaseStatus.restored) {
      logger.w('[Android] 🚫 복원 구매 엄격 차단: ${purchaseDetails.productID}');
      return false; // Android는 restored를 정상 구매로 보지 않음
    }

    return false;
  }

  /// 복원 구매 조용히 처리 (시스템 무결성만 유지)
  Future<void> processRestoredPurchase(PurchaseDetails purchaseDetails) async {
    final platform = Theme.of(_context).platform;

    if (_isProactiveCleanupMode) {
      logger.i('🧹 예방적 정리 중 도착한 복원 신호 조용히 완료 처리');

      if (purchaseDetails.pendingCompletePurchase) {
        await _purchaseService.inAppPurchaseService
            .completePurchase(purchaseDetails);
      }
      return;
    }

    logger.w('🚫 복원 구매 처리 차단 (${platform.name}): ${purchaseDetails.productID}');

    if (purchaseDetails.pendingCompletePurchase) {
      await _purchaseService.inAppPurchaseService
          .completePurchase(purchaseDetails);
    }
  }

  /// 정리 작업
  void _cleanupState() {
    _isProactiveCleanupMode = false;
    _pulseLoadingTimer?.cancel();
    _pulseLoadingTimer = null;
  }

  /// 🧹 모든 타이머 정리 (정상 구매 완료 시)
  void cleanupTimersOnPurchaseSuccess() {
    _pulseLoadingTimer?.cancel();
    _pulseLoadingTimer = null;

    logger.i('🧹 ✅ RestoreHandler 타이머 정리 완료 (정상 구매 성공 시)');
  }

  void dispose() {
    _pulseLoadingTimer?.cancel();
    _cleanupState();
  }

  // Getters
  bool get isProactiveCleanupMode => _isProactiveCleanupMode;
  bool get isProactiveCleanupCompleted => _isProactiveCleanupCompleted;
  bool get canPurchase => _isProactiveCleanupCompleted;
}
