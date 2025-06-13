import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';

/// AdMob 광고 플랫폼 구현
class AdmobPlatform extends AdPlatform {
  static bool _isInitialized = false;
  String _adUnitId = '';
  RewardedAd? _currentAd;

  AdmobPlatform(super.ref, super.context, super.id,
      AnimationController super.animationController);

  @override
  Future<void> initialize() async {
    if (_isInitialized || isDisposed) return;

    try {
      logger.i('[$id] AdMob 초기화 시작');
      await MobileAds.instance.initialize();
      await _initAdUnitId();
      _isInitialized = true;
      logger.i('[$id] AdMob 초기화 완료');
    } catch (e, s) {
      logger.e('[$id] AdMob 초기화 실패', error: e, stackTrace: s);
    }
  }

  Future<void> _initAdUnitId() async {
    if (Environment.admobIosRewardedVideoId == null ||
        Environment.admobAndroidRewardedVideoId == null) {
      logger.w('[$id] 광고 ID가 설정되지 않음');
      return;
    }

    try {
      _adUnitId = isIOS()
          ? Environment.admobIosRewardedVideoId!
          : Environment.admobAndroidRewardedVideoId!;

      logger.i('[$id] 광고 ID 초기화: $_adUnitId');
    } catch (e, s) {
      logger.e('[$id] 광고 ID 초기화 실패', error: e, stackTrace: s);
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      startButtonAnimation();
      await _loadRewardedAd();
    });
  }

  Future<void> _loadRewardedAd() async {
    if (_adUnitId.isEmpty) {
      await _initAdUnitId();
    }

    logger.i('[$id] 광고 로드 시작: $_adUnitId');

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (isDisposed) {
              ad.dispose();
              return;
            }
            logger.i('[$id] 광고 로드 완료');
            _setupAdCallbacks(ad);
            _showRewardedAd(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            logAdLoadFailure('AdMob', error, _adUnitId, error.toString(), null);
            stopAllAnimations();
            // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
          },
        ),
      );
    } catch (e, s) {
      logAdLoadFailure('AdMob', e, _adUnitId, 'AdMob 광고 로드 실패', s);
      stopAllAnimations();
      if (context.mounted && !isDisposed) {
        commonUtils.showErrorDialog(t('label_ads_load_fail'),
            error: e.toString());
      }
      rethrow;
    }
  }

  void _setupAdCallbacks(RewardedAd ad) {
    _currentAd = ad;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        logger.i('[$id] 광고가 전체 화면으로 표시됨');
        stopAllAnimations();
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        logger.i('[$id] 광고가 닫힘');
        stopAllAnimations();
        commonUtils.refreshUserProfile();
        _disposeCurrentAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        logAdShowFailure('AdMob', error, _adUnitId, error.toString(), null);
        stopAllAnimations();
        _disposeCurrentAd();
        if (context.mounted && !isDisposed) {
          commonUtils.showErrorDialog(t('label_ads_show_fail'),
              error: error.toString());
        }
      },
      onAdImpression: (RewardedAd ad) {
        logger.i('[$id] 광고 노출 기록됨');
      },
    );
  }

  void _disposeCurrentAd() {
    _currentAd?.dispose();
    _currentAd = null;
    logger.d('[$id] 현재 광고 정리됨');
  }

  void _showRewardedAd(RewardedAd ad) {
    if (!context.mounted || isDisposed) {
      _disposeCurrentAd();
      return;
    }

    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: supabase.auth.currentUser?.id ?? '',
      ),
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        logger.i('[$id] 보상 지급: ${reward.amount} ${reward.type}');
        commonUtils.refreshUserProfile();
      },
    );
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('[$id] 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      commonUtils.showErrorDialog(t('label_ads_load_fail'),
          error: error.toString());
    }
  }

  @override
  void dispose() {
    _disposeCurrentAd();
    super.dispose();
  }
}
