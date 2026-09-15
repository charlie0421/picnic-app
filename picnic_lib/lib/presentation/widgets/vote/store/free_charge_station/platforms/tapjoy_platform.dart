import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy 미션 플랫폼 구현
class TapjoyPlatform extends AdPlatform {
  /// `setUserID` terminal 이벤트 대기 상한. 안전장치 타이머(30s)보다 짧게 두어
  /// 실패가 애니메이션 강제 중지보다 먼저 사용자에게 드러나게 한다.
  static const Duration _userIdTimeout = Duration(seconds: 10);

  /// 종료되지 않은 `setUserID` 시도가 있는가.
  ///
  /// **static 인 이유**: 플러그인의 성공·실패 리스너는 Dart 쪽 static 단일
  /// 슬롯이고(TapjoyMethodCallHandler:102-110) 콜백에 요청을 식별할 값이 없다.
  /// 그래서 A 가 timeout 된 뒤 B 를 보내면 슬롯이 B 로 바뀌고, **늦게 도착한 A
  /// 의 결과가 B 의 결과로 처리된다.** A 와 B 사이에 계정이 바뀌었다면 SDK 는
  /// A 를 들고 있는데 B 로 오퍼월을 열어 적립이 다른 계정에 귀속된다.
  ///
  /// 인스턴스 필드로는 화면을 다시 만든 경우를 못 막으므로 static 이어야 한다.
  /// terminal 이벤트가 올 때까지 새 요청을 보내지 않는다 — 그동안 오퍼월은
  /// 열리지 않는다(앱 재시작으로 해제). 적립이 엉키는 것보다 낫다.
  static bool _userIdPending = false;

  @visibleForTesting
  static void resetUserIdGuardForTest() => _userIdPending = false;

  Timer? _safetyTimer;
  bool _isInitialized = false;
  TJPlacement? _currentPlacement;

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
      // PICNIC-2682: 사용자 ID 등록이 확정되기 전에는 오퍼를 요청하지 않는다.
      // 확정 전에 요청하면 Tapjoy 가 그 오퍼를 기기 ID 로 귀속시킨다.
      if (!await _setupTapjoyUser()) return;
      if (!context.mounted || isDisposed) return;
      await requestTapjoyPlacement();
    }, isMission: true);
  }

  void _setupSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimer = Timer(const Duration(seconds: 30), () {
      if (context.mounted && !isDisposed) {
        logWarning('안전장치: 애니메이션 중지');
        stopAllAnimations();
      }
    });
  }

  /// `setUserID` 성공 이벤트를 기다린 뒤에만 true 를 돌려준다.
  ///
  /// PICNIC-2682: `Tapjoy.setUserID` 는 리스너만 등록하고 즉시 반환한다
  /// (플러그인 Android 구현이 `result.success(null)` 을 리스너 바깥에서
  /// 호출한다). 따라서 이걸 await 해도 등록 완료를 기다린 것이 아니다.
  ///
  /// 등록 전에 오퍼를 요청하면 Tapjoy 는 "user ID 가 없는 기기" 로 보고
  /// 콜백 `snuid` 에 기기 ID 를 실어 보낸다(자체관리 가상화폐 문서). 그 값은
  /// `user_profiles.id` (uuid) 조회에서 22P02 로 터지고, 어느 사용자의
  /// 적립인지도 알 수 없어 복구가 불가능하다.
  ///
  /// 확정하지 못하면 오퍼월을 열지 않는다. 잘못된 귀속으로 적립을 잃느니
  /// 실패를 보여주는 쪽이 낫다.
  Future<bool> _setupTapjoyUser() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _reportUserSetupFailure('로그인 사용자 없음');
      return false;
    }

    if (_userIdPending) {
      _reportUserSetupFailure('앞선 setUserID 가 아직 종료되지 않음');
      return false;
    }
    _userIdPending = true;

    startPerformanceLog('사용자 설정');
    final settled = Completer<bool>();
    var failureReason = '${_userIdTimeout.inSeconds}s 안에 응답이 오지 않음';

    // terminal 이벤트가 왔다는 것이 소유권 해제 조건이다. timeout 은 해제하지
    // 않는다 — 해제하면 늦은 이벤트가 다음 시도의 결과로 둔갑한다.
    void settle(bool ok, [String? reason]) {
      _userIdPending = false;
      if (reason != null) failureReason = reason;
      if (!settled.isCompleted) settled.complete(ok);
    }

    try {
      await Tapjoy.setUserID(
        userId: userId,
        onSetUserIDSuccess: () {
          logInfo('사용자 ID 설정 성공');
          endPerformanceLog('사용자 설정');
          settle(true);
        },
        onSetUserIDFailure: (error) =>
            settle(false, error?.toString() ?? 'setUserID 실패'),
      );
    } catch (error) {
      // 채널 호출 자체가 실패했다 — 네이티브가 실행되지 않았다고 보고 소유권을
      // 놓는다. 여기서 붙잡으면 올 수 없는 이벤트를 기다리며 영구히 잠긴다.
      settle(false, error.toString());
    }

    final ok = await settled.future.timeout(
      _userIdTimeout,
      onTimeout: () => false,
    );
    if (!ok) _reportUserSetupFailure(failureReason);
    return ok;
  }

  /// 사용자 ID 확정 실패를 한 번만 알린다.
  ///
  /// `logAdLoadFailure` 가 이미 다이얼로그를 띄운다(ad_platform.dart:459,478).
  /// 여기서 `handleAdFailure` 를 또 부르면 같은 실패에 다이얼로그가 두 번
  /// 쌓인다. 애니메이션 정리만 직접 한다.
  void _reportUserSetupFailure(String reason) {
    logAdLoadFailure('Tapjoy', reason, 'mission', reason, StackTrace.current);
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
    }
  }

  /// 오퍼 요청. 테스트가 배선을 고정할 수 있도록 override 가능하게 둔다 —
  /// 이 호출이 `_setupTapjoyUser` 성공 이후에만 일어나는 것이 PICNIC-2682 의 계약이다.
  @visibleForTesting
  Future<void> requestTapjoyPlacement() async {
    startPerformanceLog('플레이스먼트 요청');
    _currentPlacement = await TJPlacement.getPlacement(
      placementName: 'mission',
      onRequestSuccess: (placement) {
        logInfo('플레이스먼트 요청 성공');
      },
      onRequestFailure: (placement, error) {
        logAdLoadFailure(
            'Tapjoy', error, 'mission', error.toString(), StackTrace.current);
        handleAdFailure(error);
      },
      onContentReady: (placement) {
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

    if (_currentPlacement != null) {
      _currentPlacement!.setEntryPoint(TJEntryPoint.entryPointStore);
      await _currentPlacement!.requestContent();
    } else {
      logAdLoadFailure('Tapjoy', '플레이스먼트 생성 실패', 'mission', '플레이스먼트 생성 실패',
          StackTrace.current);
    }
  }

  /// 광고 실패 안내. 테스트가 "실패 한 건에 다이얼로그 한 개" 를 고정할 수
  /// 있도록 override 가능하게 둔다.
  @visibleForTesting
  void handleAdFailure(String? error) {
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
    _currentPlacement = null;
    super.dispose();
  }
}
