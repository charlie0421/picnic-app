import 'dart:async';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/pincruxOfferwallPlugin.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:universal_io/io.dart';

/// Pincrux 미션 플랫폼 구현
class PincruxPlatform extends AdPlatform {
  Timer? _safetyTimer;
  bool _isInitialized = false;

  PincruxPlatform(super.ref, super.context, super.id,
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
      await _showPincruxOfferwall();
      stopAllAnimations();
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

  Future<void> _showPincruxOfferwall() async {
    try {
      startPerformanceLog('오퍼월 표시');
      logInfo('오퍼월 시작');

      String userId = supabase.auth.currentUser!.id;
      String? appKey = Platform.isIOS
          ? Environment.pincruxIosAppKey
          : Environment.pincruxAndroidAppKey;

      if (appKey == null || appKey.isEmpty) {
        logAdLoadFailure(
            'Pincrux', '앱 키가 설정되지 않음', 'offerwall', '앱 키가 설정되지 않음', null);
        throw Exception('Pincrux app key not available');
      }

      PincruxOfferwallPlugin.init(appKey, userId);
      PincruxOfferwallPlugin.setOfferwallType(1);
      PincruxOfferwallPlugin.startPincruxOfferwall();

      if (!isDisposed) {
        logInfo('사용자 프로필 새로고침');
        commonUtils.refreshUserProfile();
      }
      endPerformanceLog('오퍼월 표시');
    } catch (e, s) {
      logAdLoadFailure('Pincrux', e, 'offerwall', 'Pincrux 오퍼월 표시 실패', s);
      rethrow;
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logError('오류 발생', error: error, stackTrace: stackTrace);
    if (context.mounted && !isDisposed) {
      stopAllAnimations();
      commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
          error: error);
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    super.dispose();
  }
}
