import 'dart:async';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:tapjoy_offerwall/tapjoy_offerwall.dart';

/// Tapjoy 미션 플랫폼 구현
class TapjoyPlatform extends AdPlatform {
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
      await _setupTapjoyUser();
      await _requestTapjoyPlacement();
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

  Future<void> _setupTapjoyUser() async {
    startPerformanceLog('사용자 설정');
    await Tapjoy.setUserID(
      userId: supabase.auth.currentUser!.id,
      onSetUserIDSuccess: () {
        logInfo('사용자 ID 설정 성공: ${supabase.auth.currentUser!.id}');
        endPerformanceLog('사용자 설정');
      },
      onSetUserIDFailure: (error) {
        logAdLoadFailure('Tapjoy', error, 'mission', error.toString(), StackTrace.current);
        if (!isDisposed) {
          stopAllAnimations();
        }
      },
    );
  }

  Future<void> _requestTapjoyPlacement() async {
    startPerformanceLog('플레이스먼트 요청');
    _currentPlacement = await TJPlacement.getPlacement(
      placementName: 'mission',
      onRequestSuccess: (placement) {
        logInfo('플레이스먼트 요청 성공');
      },
      onRequestFailure: (placement, error) {
        logAdLoadFailure('Tapjoy', error, 'mission', error.toString(), StackTrace.current);
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
      logAdLoadFailure(
          'Tapjoy', '플레이스먼트 생성 실패', 'mission', '플레이스먼트 생성 실패', StackTrace.current);
    }
  }

  void _handleAdFailure(String? error) {
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(content: t('label_ads_load_fail'), type: DialogType.error);
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logError('오류 발생', error: error, stackTrace: stackTrace);
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      showSimpleDialog(content: t('label_ads_load_fail'), type: DialogType.error);
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
