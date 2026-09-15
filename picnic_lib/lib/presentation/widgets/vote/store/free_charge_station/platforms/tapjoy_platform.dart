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

  Timer? _safetyTimer;
  bool _isInitialized = false;
  bool _userIdInFlight = false;
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
      logAdLoadFailure('Tapjoy', '로그인 사용자 없음', 'mission', '로그인 사용자 없음',
          StackTrace.current);
      _handleAdFailure('no authenticated user');
      return false;
    }

    // 플러그인의 성공·실패 리스너는 static 단일 슬롯이라(tapjoy 14.6.0) 요청이
    // 겹치면 앞선 시도의 Completer 가 영원히 완료되지 않는다. 연타를 막는다.
    if (_userIdInFlight) {
      logWarning('사용자 ID 설정이 이미 진행 중 — 중복 요청 무시');
      return false;
    }
    _userIdInFlight = true;

    startPerformanceLog('사용자 설정');
    final settled = Completer<bool>();
    void settle(bool ok) {
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
        onSetUserIDFailure: (error) {
          logAdLoadFailure(
              'Tapjoy', error, 'mission', error.toString(), StackTrace.current);
          settle(false);
        },
      );
    } catch (error, stackTrace) {
      logAdLoadFailure(
          'Tapjoy', error, 'mission', error.toString(), stackTrace);
      settle(false);
    }

    final ok = await settled.future.timeout(
      _userIdTimeout,
      onTimeout: () {
        logAdLoadFailure('Tapjoy', '사용자 ID 설정 응답 없음', 'mission',
            '${_userIdTimeout.inSeconds}s 안에 terminal 이벤트가 오지 않음',
            StackTrace.current);
        return false;
      },
    );
    _userIdInFlight = false;

    if (!ok) _handleAdFailure('set user id failed');
    return ok;
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
        _handleAdFailure(error);
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
    _currentPlacement = null;
    super.dispose();
  }
}
