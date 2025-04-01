import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';

/// AdMob 광고 플랫폼 구현
class AdmobPlatform extends AdPlatform {
  static bool _isInitialized = false;
  String _adUnitId = '';

  AdmobPlatform(super.ref, super.context, super.id,
      AnimationController super.animationController);

  @override
  Future<void> initialize() async {
    // AdMob 초기화가 이미 완료된 경우 스킵
    if (_isInitialized) return;

    try {
      logger.i('AdMob 초기화 시작');
      // AdMob 초기화
      await MobileAds.instance.initialize();
      // 광고 ID 초기화
      await _initAdUnitId();
      _isInitialized = true;
      logger.i('AdMob 초기화 완료');
    } catch (e, s) {
      logger.e('AdMob 초기화 실패', error: e, stackTrace: s);
      // 초기화 실패 시에도 플래그 설정 (재시도 방지)
      _isInitialized = true;
    }
  }

  Future<void> _initAdUnitId() async {
    if (Environment.admobIosRewardedVideoId == null ||
        Environment.admobAndroidRewardedVideoId == null) {
      return;
    }

    try {
      // ConfigService를 사용할 수 없는 경우 테스트 ID를 사용
      _adUnitId = isIOS()
          ? Environment.admobIosRewardedVideoId!
          : Environment.admobAndroidRewardedVideoId!;

      logger.i('AdMob ID 초기화: $_adUnitId');
    } catch (e, s) {
      logger.e('AdMob ID 초기화 실패', error: e, stackTrace: s);
    }
  }

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted) return;

      // 애니메이션 시작
      startButtonAnimation();

      // 광고 로드
      try {
        await _loadRewardedAd();
      } catch (e) {
        logger.e('AdMob 광고 로드 실패', error: e);
        stopButtonAnimation();
      }
    });
  }

  Future<void> _loadRewardedAd() async {
    if (_adUnitId.isEmpty) {
      await _initAdUnitId();
    }

    logger.i('AdMob 광고 로드 시작: $_adUnitId');

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            logger.i('AdMob 광고 로드 완료');
            _setupAdCallbacks(ad);
            _showRewardedAd(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            logger.e('AdMob 광고 로드 실패', error: error);
            stopAllAnimations();
            if (context.mounted) {
              commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
                  error: error.toString());
            }
          },
        ),
      );
    } catch (e, s) {
      logger.e('AdMob 광고 로드 중 예외 발생', error: e, stackTrace: s);
      stopAllAnimations();
      if (context.mounted) {
        commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
            error: e);
      }
      rethrow;
    }
  }

  void _setupAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        logger.i('AdMob 광고가 전체 화면으로 표시됨');
        stopAllAnimations();
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        logger.i('AdMob 광고가 닫힘');
        stopAllAnimations();
        commonUtils.refreshUserProfile();
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        logger.e('AdMob 광고 표시 실패', error: error);
        stopAllAnimations();
        ad.dispose();
        if (context.mounted) {
          commonUtils.showErrorDialog(S.of(context).label_ads_show_fail,
              error: error.toString());
        }
      },
      onAdImpression: (RewardedAd ad) {
        logger.i('AdMob 광고 노출 기록됨');
      },
    );
  }

  void _showRewardedAd(RewardedAd ad) {
    if (!context.mounted) return;

    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: supabase.auth.currentUser?.id ?? '',
      ),
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        logger.i('AdMob 보상 지급: ${reward.amount} ${reward.type}');
        commonUtils.refreshUserProfile();
      },
    );
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('Error in AdMob ads', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted) {
      commonUtils.showErrorDialog(S.of(context).label_ads_load_fail,
          error: error);
    }
  }
}
