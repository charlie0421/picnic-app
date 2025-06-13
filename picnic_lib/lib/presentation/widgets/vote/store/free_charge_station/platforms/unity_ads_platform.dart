// unity_ads_platform.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// Unity Ads 플랫폼 구현
class UnityAdsPlatform extends AdPlatform {
  static bool _isInitialized = false;
  static String? gameId;
  static String? placementId;
  Timer? _safetyTimer;

  UnityAdsPlatform(super.ref, super.context, super.id,
      [super.animationController]);

  @override
  Future<void> initialize() async {
    if (_isInitialized || isDisposed) return;

    try {
      logger.i('[$id] Unity Ads 초기화 시작');
      await UnityAds.init(
        gameId: isIOS()
            ? Environment.unityAppleGameId!
            : Environment.unityAndroidGameId!,
        testMode: kDebugMode,
      );
      _isInitialized = true;
      logger.i('[$id] Unity Ads 초기화 완료');
    } catch (e, s) {
      logger.e('[$id] Unity Ads 초기화 실패', error: e, stackTrace: s);
      logInitFailure('Unity', e, s);
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      await _showUnityAd();
    });
  }

  Future<void> _showUnityAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    final placementId = isIOS()
        ? Environment.unityIosPlacementId
        : Environment.unityAndroidPlacementId;

    if (placementId == null) {
      logger.e('[$id] placementId가 설정되지 않음');
      stopAllAnimations();
      if (context.mounted && !isDisposed) {
        commonUtils.showErrorDialog(t('label_ads_load_fail'),
            error: 'placementId가 설정되지 않음');
      }
      return;
    }

    logger.i('[$id] Unity 광고 로드 시작: $placementId');

    try {
      await UnityAds.load(
        placementId: placementId,
        onComplete: (placementId) async {
          logger.i('[$id] 광고 로드 완료');
          await _showLoadedAd(placementId);
        },
        onFailed: (placementId, error, message) {
          logAdLoadFailure('Unity', error, placementId, message, null);
          stopAllAnimations();
          // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
        },
      );
    } catch (e, s) {
      logAdLoadFailure('Unity', e, placementId, 'Unity 광고 로드 실패', s);
      stopAllAnimations();
      // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
      rethrow;
    }
  }

  Future<void> _showLoadedAd(String placementId) async {
    logger.i('[$id] Unity 광고 표시 시작: $placementId');

    try {
      await UnityAds.showVideoAd(
        placementId: placementId,
        serverId: supabase.auth.currentUser!.id,
        onStart: (placementId) {
          logger.i('[$id] 광고 시작');
          stopAllAnimations();
        },
        onSkipped: (placementId) {
          logger.i('[$id] 광고 스킵됨');
        },
        onComplete: (placementId) {
          logger.i('[$id] 광고 완료');
          commonUtils.refreshUserProfile();
        },
        onFailed: (placementId, error, message) {
          logAdShowFailure('Unity', error, placementId, message, null);
          stopAllAnimations();
          if (context.mounted && !isDisposed) {
            commonUtils.showErrorDialog(t('label_ads_show_fail'),
                error: message);
          }
        },
      );
    } catch (e, s) {
      logAdShowFailure('Unity', e, placementId, 'Unity 광고 표시 실패', s);
      stopAllAnimations();
      if (context.mounted && !isDisposed) {
        commonUtils.showErrorDialog(t('label_ads_show_fail'),
            error: e.toString());
      }
      rethrow;
    }
  }



  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('[$id] Unity 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      commonUtils.showErrorDialog(t('label_ads_load_fail'),
          error: error.toString());
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    super.dispose();
  }
}
