import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

typedef AdmobClaimCreator =
    Future<AdmobClaimModel> Function({
      required String platform,
      required String placementId,
      required String clientRequestId,
    });

/// SDK가 광고를 표시하기 전에 AdMob SSV용 opaque 토큰을 발급받는다.
///
/// 발급 실패를 호출자에게 전파하므로, 호출자는 [RewardedAd.show]에 도달하지 않는다.
class AdmobClaimPreflight {
  const AdmobClaimPreflight({required this.createClaim});

  final AdmobClaimCreator createClaim;

  Future<String> execute({
    required String ownerUserId,
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) async {
    if (ownerUserId.isEmpty) {
      throw StateError('Authenticated user required for AdMob claim');
    }
    final claim = await createClaim(
      platform: platform,
      placementId: placementId,
      clientRequestId: clientRequestId,
    );
    if (claim.signedToken.isEmpty) {
      throw const FormatException('AdMob claim is missing a signed token');
    }
    return claim.signedToken;
  }
}

/// AdMob 광고 플랫폼 구현
/// 참고: AdMob SDK 초기화는 MainInitializer._initializeAdMob()에서 앱 시작 시 수행됨
class AdmobPlatform extends AdPlatform {
  String _adUnitId = '';
  RewardedAd? _currentAd;

  AdmobPlatform(
    super.ref,
    super.context,
    super.id,
    AnimationController super.animationController,
  );

  @override
  Future<void> initialize() async {
    if (isDisposed) return;

    // 광고 ID만 초기화 (SDK 초기화는 앱 시작 시 완료됨)
    await _initAdUnitId();
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
          onAdLoaded: (RewardedAd ad) async {
            if (isDisposed) {
              ad.dispose();
              return;
            }
            logger.i('[$id] 광고 로드 완료');
            _setupAdCallbacks(ad);
            await _showRewardedAd(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            logger.e(
              '[$id] AdMob 광고 로드 실패 상세:\n'
              '  code: ${error.code}\n'
              '  message: ${error.message}\n'
              '  domain: ${error.domain}\n'
              '  responseInfo: ${error.responseInfo}\n'
              '  adUnitId: $_adUnitId',
            );
            logAdLoadFailure(
              'AdMob',
              error,
              _adUnitId,
              error.toString(),
              StackTrace.current,
            );
            stopAllAnimations();
            // No Fill 감지와 다이얼로그 표시는 logAdLoadFailure에서 공통 처리됨
          },
        ),
      );
    } catch (e, s) {
      // 분류 근거로 실제 예외 텍스트를 넘긴다 — 일반 라벨을 넘기면 '광고 로드
      // 실패' 키워드에 걸려 모든 예외가 no-fill 로 삼켜진다(pangle 과 동일 함정).
      //
      // logAdLoadFailure 가 이미 사용자에게 안내한다(no-fill 이면 "소진",
      // 그 외에는 label_ads_load_fail). 여기서 같은 문구를 또 띄우고 rethrow 까지
      // 하면 safelyExecute → handleError 가 세 번째로 띄운다. 한 번의 실패에
      // 다이얼로그를 세 번 닫게 만들지 않는다 — 안내는 logAdLoadFailure 에 맡기고
      // 여기서는 애니메이션만 정리한다.
      logAdLoadFailure('AdMob', e, _adUnitId, e.toString(), s);
      stopAllAnimations();
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
        logger.e(
          '[$id] AdMob 광고 표시 실패 상세:\n'
          '  code: ${error.code}\n'
          '  message: ${error.message}\n'
          '  domain: ${error.domain}',
        );
        logAdShowFailure('AdMob', error, _adUnitId, error.toString(), null);
        stopAllAnimations();
        _disposeCurrentAd();
        if (context.mounted && !isDisposed) {
          showSimpleDialog(
            content: AppLocalizations.of(context).label_ads_show_fail,
            type: DialogType.error,
          );
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

  Future<void> _showRewardedAd(RewardedAd ad) async {
    if (!context.mounted || isDisposed) {
      _disposeCurrentAd();
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    final platform = Platform.isIOS ? 'ios' : 'android';

    if (userId == null || userId.isEmpty) {
      logger.e('[$id] SSV userId가 없음 - 인증 세션 만료 가능성');
      _disposeCurrentAd();
      stopAllAnimations();
      showRequireLoginDialog();
      return;
    }

    try {
      final signedToken =
          await AdmobClaimPreflight(
            createClaim: AdRewardRepository(supabase).createAdmobClaim,
          ).execute(
            ownerUserId: userId,
            platform: platform,
            placementId: _adUnitId,
            clientRequestId: const Uuid().v4(),
          );

      if (!context.mounted || isDisposed) {
        _disposeCurrentAd();
        stopAllAnimations();
        return;
      }

      logger.i(
        '[$id] AdMob SSV claim 설정: platform=$platform, adUnit=$_adUnitId',
      );
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(userId: userId, customData: signedToken),
      );

      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          logger.i(
            '[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, userId=$userId',
          );
          commonUtils.refreshUserProfile();
        },
      );
    } catch (e, s) {
      logger.e(
        '[$id] AdMob SSV claim 발급 실패 - 광고를 표시하지 않음',
        error: e,
        stackTrace: s,
      );
      _disposeCurrentAd();
      stopAllAnimations();
      if (context.mounted && !isDisposed) {
        showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error,
        );
      }
    }
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('[$id] 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      showSimpleDialog(
        content: AppLocalizations.of(context).label_ads_load_fail,
        type: DialogType.error,
      );
    }
  }

  @override
  void dispose() {
    _disposeCurrentAd();
    super.dispose();
  }
}
