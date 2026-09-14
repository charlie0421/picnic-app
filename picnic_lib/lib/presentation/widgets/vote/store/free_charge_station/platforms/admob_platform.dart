import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

typedef AdmobClaimCreator =
    Future<AdmobClaimModel> Function({
      required String platform,
      required String placementId,
      required String clientRequestId,
    });

class AdmobClaimPreflightResult {
  const AdmobClaimPreflightResult({
    required this.signedToken,
    required this.reference,
  });

  final String signedToken;
  final AdRewardReference reference;
}

/// SDK가 광고를 표시하기 전에 AdMob SSV용 opaque 토큰을 발급받는다.
///
/// 발급 실패를 호출자에게 전파하므로, 호출자는 [RewardedAd.show]에 도달하지 않는다.
///
/// 발급된 클레임 참조는 Pangle 과 같은 계약으로 [persist] 에 넘긴다 — 보상은
/// Google 의 SSV 콜백이 서버에 닿은 뒤에야 GRANTED 가 되므로(클레임 생성 기준
/// p50 19~21초, p90 61~66초), 앱은 그 참조로 상태를 폴링해 적립 영수증을 띄우고
/// ack 해야 한다. 예전에는 참조를 버려서 정상 적립조차 화면에 반영되지 않았고,
/// 광고 닫힘 직후의 프로필 새로고침은 대개 적립보다 먼저 실행됐다.
class AdmobClaimPreflight {
  const AdmobClaimPreflight({required this.createClaim, required this.persist});

  final AdmobClaimCreator createClaim;
  final Future<void> Function(String ownerUserId, AdRewardReference reference)
  persist;

  Future<AdmobClaimPreflightResult> execute({
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
    await persist(ownerUserId, claim.reference);
    return AdmobClaimPreflightResult(
      signedToken: claim.signedToken,
      reference: claim.reference,
    );
  }
}

/// 로드된 광고를 실제로 채운 광고 소스 요약.
///
/// 진단용이다. Google 은 SSV 콜백에 `ad_network` 소스 ID 를 함께 보내는데,
/// 프로덕션 24시간 콜백 21,881건이 전부 AdMob 네트워크(5450213213286189855)
/// 였고 Meta·Pangle·Liftoff 미디에이션 소스는 0건이었다(2026-09-14). 미디에이션
/// 채움이 SSV 없이 끝나 PENDING 으로 남는지는 기기에서만 가릴 수 있으므로,
/// 로드 시점의 소스를 로그와 Sentry breadcrumb 으로 남긴다.
class AdmobAdSourceSummary {
  const AdmobAdSourceSummary({
    required this.adSourceName,
    required this.adSourceId,
    required this.adapterClassName,
    required this.mediationAdapterClassName,
    required this.responseId,
  });

  factory AdmobAdSourceSummary.fromResponseInfo(ResponseInfo? info) {
    final loaded = info?.loadedAdapterResponseInfo;
    return AdmobAdSourceSummary(
      adSourceName: loaded?.adSourceName,
      adSourceId: loaded?.adSourceId,
      adapterClassName: loaded?.adapterClassName,
      mediationAdapterClassName: info?.mediationAdapterClassName,
      responseId: info?.responseId,
    );
  }

  /// Google 의 SSV `ad_network` 파라미터가 AdMob 네트워크일 때 쓰는 소스 ID.
  static const String admobNetworkSourceId = '5450213213286189855';

  final String? adSourceName;
  final String? adSourceId;
  final String? adapterClassName;
  final String? mediationAdapterClassName;
  final String? responseId;

  /// 타사 미디에이션 네트워크가 채웠으면 true, AdMob 네트워크면 false,
  /// 판단할 정보가 없으면 null.
  bool? get isMediated {
    final adapter = adapterClassName ?? mediationAdapterClassName;
    if (adSourceId == admobNetworkSourceId) return false;
    if (adSourceId != null && adSourceId!.isNotEmpty) return true;
    if (adapter == null || adapter.isEmpty) return null;
    return !adapter.toLowerCase().contains('mediation.admob');
  }

  String describe() {
    if (adSourceName == null &&
        adSourceId == null &&
        adapterClassName == null &&
        mediationAdapterClassName == null) {
      return 'ad_source=unknown';
    }
    final source = adSourceName ?? '?';
    final id = adSourceId == null ? '' : '($adSourceId)';
    final adapter = adapterClassName ?? mediationAdapterClassName ?? '?';
    return 'ad_source=$source$id adapter=$adapter '
        'mediated=${isMediated ?? 'unknown'} response=${responseId ?? '-'}';
  }

  Map<String, dynamic> toBreadcrumbData() => {
    'ad_source_name': adSourceName,
    'ad_source_id': adSourceId,
    'adapter': adapterClassName ?? mediationAdapterClassName,
    'mediated': isMediated,
    'response_id': responseId,
  };
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
      await MainInitializer.runAdRequestWhenReady<void>(
        isRequestActive: () => !isDisposed && context.mounted,
        request: () => RewardedAd.load(
          adUnitId: _adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (RewardedAd ad) async {
              if (isDisposed) {
                ad.dispose();
                return;
              }
              // 광고 한 건에 묶인 지역값이다 — 인스턴스 필드에 두면 이중 탭으로
              // 두 광고가 겹칠 때 두 번째 로드가 첫 광고의 earned 진단을 덮어쓴다.
              final adSource = AdmobAdSourceSummary.fromResponseInfo(
                ad.responseInfo,
              );
              logger.i('[$id] 광고 로드 완료 ${adSource.describe()}');
              _breadcrumb('loaded', adSource.toBreadcrumbData());
              _setupAdCallbacks(ad);
              await _showRewardedAd(ad, adSource);
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
        ),
      );
    } on AdsUnavailable catch (e) {
      // 준비 대기 종료·동의 미허용·화면 닫기는 SDK 로드 오류가 아니다.
      logger.i('[$id] 광고 요청 보류: $e');
      stopAllAnimations();
      if (context.mounted && !isDisposed) {
        showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error,
        );
      }
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
        _breadcrumb('showed');
        stopAllAnimations();
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        logger.i('[$id] 광고가 닫힘');
        _breadcrumb('dismissed');
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
        _breadcrumb('show_failed', {
          'code': error.code,
          'domain': error.domain,
          'message': error.message,
        });
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

  Future<void> _showRewardedAd(
    RewardedAd ad,
    AdmobAdSourceSummary adSource,
  ) async {
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
      // Pangle 과 같은 이유로 keepAlive notifier 와 store 를 await 이전에 잡는다:
      // 폴링은 광고가 끝난 뒤 돌아오는데 그 사이 이 화면이 사라지면
      // `AdPlatform.ref` 의 read 가 던져 확정된 적립 확인이 조용히 사라진다.
      final pendingStore = ref.read(pendingAdRewardStoreProvider);
      final adRewardRecovery = ref.read(adRewardRecoveryProvider.notifier);
      final preflight =
          await AdmobClaimPreflight(
            createClaim: AdRewardRepository(supabase).createAdmobClaim,
            persist: pendingStore.add,
          ).execute(
            ownerUserId: userId,
            platform: platform,
            placementId: _adUnitId,
            clientRequestId: const Uuid().v4(),
          );
      final reference = preflight.reference;
      _breadcrumb('claim_issued', {'claim_id': reference.id});

      if (!context.mounted || isDisposed) {
        _disposeCurrentAd();
        stopAllAnimations();
        return;
      }

      logger.i(
        '[$id] AdMob SSV claim 설정: platform=$platform, adUnit=$_adUnitId, '
        'claim=${reference.id}',
      );
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: userId,
          customData: preflight.signedToken,
        ),
      );

      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          logger.i(
            '[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, '
            'userId=$userId, claim=${reference.id} '
            '${adSource.describe()}',
          );
          _breadcrumb('earned', {
            'claim_id': reference.id,
            'amount': reward.amount,
            'type': reward.type,
            ...adSource.toBreadcrumbData(),
          });
          commonUtils.refreshUserProfile();
          // SDK 의 보상 콜백은 "시청 완료" 일 뿐 지급이 아니다. 지급은 Google 의
          // SSV 콜백이 서버에 닿아야 확정되므로 여기서부터 상태 사다리를 돈다.
          // Future.sync: dispose 된 ref.read 처럼 동기로 던지는 경우도 모은다.
          unawaited(
            Future.sync(
              () => adRewardRecovery.poll(
                ownerUserId: userId,
                reference: reference,
              ),
            ).catchError((Object error, StackTrace stackTrace) {
              logger.e(
                '[$id] AdMob reward polling failed: claim=${reference.id}',
                error: error,
                stackTrace: stackTrace,
              );
            }),
          );
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

  /// 광고 한 건의 생애주기를 Sentry breadcrumb 으로 남긴다.
  ///
  /// 앱 로그는 Sentry 로 가지 않아 테스트플라이트에서 "적립 안 됨" 이 로드 실패·
  /// 표시 실패·조기 닫힘·미디에이션 채움 중 무엇인지 원격으로 가릴 수 없었다.
  /// 이후 이벤트가 잡히면 이 빵부스러기가 붙어 나온다.
  void _breadcrumb(String step, [Map<String, dynamic>? data]) {
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'ad.admob',
          message: step,
          level: SentryLevel.info,
          data: {'slot': id, 'ad_unit': _adUnitId, ...?data},
        ),
      ),
    );
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
