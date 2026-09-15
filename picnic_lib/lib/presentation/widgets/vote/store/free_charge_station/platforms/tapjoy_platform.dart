import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/core/utils/tapjoy_session.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy 미션 플랫폼 구현
///
/// PICNIC-2682: 오퍼월을 요청하기 전에 SDK 가 Picnic UUID 를 사용자 ID 로 확인할
/// 때까지 기다린다. `Tapjoy.setUserID` 의 MethodChannel Future 는 네이티브 요청이
/// 나갔다는 뜻일 뿐이라(TapjoyOfferwallPlugin.kt:170), 그 상태에서 오퍼월을 열면
/// SDK 가 아직 들고 있는 기본 기기 ID 로 오퍼가 만들어지고 서버 콜백의 `snuid` 가
/// UUID 가 아니게 된다.
class TapjoyPlatform extends AdPlatform {
  Timer? _safetyTimer;
  bool _isInitialized = false;

  /// 늦게 도착한 placement 콜백이 지난 시도의 화면을 열지 못하게 막는다.
  final TapjoyAttemptGuard _attemptGuard = TapjoyAttemptGuard();

  TapjoyPlatform(super.ref, super.context, super.id,
      [super.animationController]);

  @override
  Future<void> initialize() async {
    if (_isInitialized || isDisposed) return;
    _isInitialized = true;
    logInfo('초기화 완료');
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      _setupSafetyTimer();

      await runTapjoyOfferwall();
    }, isMission: true);
  }

  /// 오퍼월 본체 — [showAd] 의 로그인/로딩 래퍼 안에서만 실행된다.
  ///
  /// 세션이 connect 준비 → `setUserID` 성공 이벤트 → 계정 재확인까지 마친
  /// 뒤에만 placement 를 요청한다. 실패는 그대로 던져 `safelyExecute` 가
  /// 사용자에게 실패를 알리게 한다 — 여기서 삼키면 기기 ID 로 오퍼가 생성된다.
  ///
  /// 별도 메서드인 이유는 테스트 seam 이다. 이게 없으면 배선을 검증하려고
  /// 실제 Tapjoy SDK placement 를 세워야 하고, 결국 [TapjoySession] 만 단위
  /// 테스트하게 된다 — 그러면 `showAd()` 가 세션을 **거치지 않도록** 바뀌어도
  /// 테스트가 통과한다.
  @visibleForTesting
  Future<void> runTapjoyOfferwall() =>
      TapjoySession.instance.runOfferwall(requestPlacement);

  void _setupSafetyTimer() {
    _safetyTimer?.cancel();
    // 애니메이션만 멈추는 표시용 타이머다. 인증 성공으로 간주하지 않는다.
    _safetyTimer = Timer(const Duration(seconds: 30), () {
      if (context.mounted && !isDisposed) {
        logWarning('안전장치: 애니메이션 중지');
        stopAllAnimations();
      }
    });
  }

  @visibleForTesting
  Future<void> requestPlacement(String userId) async {
    startPerformanceLog('플레이스먼트 요청');
    final attempt = _attemptGuard.begin();

    /// 이 콜백이 아직 이번 시도·이번 계정의 것인가.
    bool isLive() =>
        _attemptGuard.isCurrent(attempt) &&
        !isDisposed &&
        context.mounted &&
        TapjoySession.instance.currentUserId == userId;

    final placement = await TJPlacement.getPlacement(
      placementName: 'mission',
      onRequestSuccess: (placement) {
        logInfo('플레이스먼트 요청 성공');
      },
      onRequestFailure: (placement, error) {
        if (!isLive()) return;
        logAdLoadFailure(
            'Tapjoy', error, 'mission', error.toString(), StackTrace.current);
        _handleAdFailure(error);
      },
      onContentReady: (placement) {
        if (!isLive()) {
          logWarning('지난 시도의 콘텐츠 준비 콜백 — 표시하지 않음');
          return;
        }
        logInfo('콘텐츠 준비 완료');
        placement.showContent();
        stopAllAnimations();
      },
      onContentShow: (placement) {
        logInfo('콘텐츠 표시 시작');
      },
      onContentDismiss: (placement) {
        logInfo('콘텐츠 닫힘');
        if (context.mounted && !isDisposed) {
          stopAllAnimations();
          commonUtils.refreshUserProfile();
        }
        endPerformanceLog('플레이스먼트 요청');
      },
    );

    if (!isLive()) {
      logWarning('플레이스먼트 생성 사이에 시도가 무효화됨 — 요청하지 않음');
      return;
    }

    placement.setEntryPoint(TJEntryPoint.entryPointStore);
    await placement.requestContent();
  }

  void _handleAdFailure(String? error) {
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error);
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logError('오류 발생', error: error, stackTrace: stackTrace);
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error);
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    // 늦게 도착할 SDK 콜백이 이 화면을 되살리지 못하게 한다.
    _attemptGuard.cancel();
    super.dispose();
  }
}
