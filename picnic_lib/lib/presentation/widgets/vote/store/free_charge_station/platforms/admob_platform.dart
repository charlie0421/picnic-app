import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:universal_io/io.dart';

/// AdMob 로드→표시 한 사이클의 상태 기계.
///
/// - 로드/표시 각 단계에 워치독을 걸어 SDK 콜백이 하나도 오지 않아도 반드시
///   terminal 콜백 중 정확히 하나로 끝난다 (조사 보고서 §1.3 의 "영구 정지" 차단).
/// - 세대 토큰으로 늦게 도착한 SDK 콜백의 UI 액션을 무시한다. 리소스 정리는
///   늦게 와도 수행한다.
/// - SDK 타입·BuildContext 에 의존하지 않아 fake 로 유닛 테스트가 가능하다
///   (PangleClaimPreflight 와 같은 패턴).
class AdmobShowFlow<T> {
  AdmobShowFlow({
    required this.startLoad,
    required this.attachCallbacksAndShow,
    required this.disposeAd,
    this.loadTimeout = const Duration(seconds: 15),
    this.showTimeout = const Duration(seconds: 10),
  });

  /// RewardedAd.load 호출. 결과는 콜백으로만 판정한다 — load 가 반환하는
  /// Future 는 로드 성공/실패와 무관하므로 신뢰하지 않는다.
  final void Function(
    void Function(T ad) onLoaded,
    void Function(Object error) onFailedToLoad,
  ) startLoad;

  /// fullScreenContentCallback 배선 + SSV 설정 + ad.show 를 한 번에 수행한다.
  /// 인자로 받은 콜백을 SDK 콜백에 그대로 연결해야 한다.
  final void Function(
    T ad, {
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
  }) attachCallbacksAndShow;

  final void Function(T ad) disposeAd;
  final Duration loadTimeout;
  final Duration showTimeout;

  int _generation = 0;
  Timer? _watchdog;
  T? _pendingAd;

  bool _isCurrent(int g) => g == _generation;

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  /// 이 attempt 를 terminal 상태로 만든다. 이후 도착하는 같은 세대의 SDK
  /// 콜백은 UI 액션을 건너뛴다.
  void _finish(int g) {
    if (_isCurrent(g)) {
      _generation++;
      _cancelWatchdog();
    }
  }

  void _disposePending() {
    final ad = _pendingAd;
    _pendingAd = null;
    if (ad != null) disposeAd(ad);
  }

  void run({
    required void Function() onLoadTimeout,
    required void Function(Object error) onLoadFailed,
    required void Function() onShowStarted,
    required void Function() onShowTimeout,
    required void Function(Object error) onShowFailed,
    required void Function() onDismissed,
  }) {
    _generation++; // 새 attempt 시작 = 이전 attempt 전부 무효화
    _disposePending();
    final g = _generation;
    _cancelWatchdog();

    _watchdog = Timer(loadTimeout, () {
      if (!_isCurrent(g)) return;
      _finish(g);
      onLoadTimeout();
    });

    startLoad(
      (ad) {
        if (!_isCurrent(g)) {
          // 타임아웃/재시도 이후 늦게 도착한 onAdLoaded — 조용히 폐기.
          disposeAd(ad);
          return;
        }
        _cancelWatchdog();
        _pendingAd = ad;
        _watchdog = Timer(showTimeout, () {
          if (!_isCurrent(g)) return;
          _finish(g);
          // 광고가 실제로 떠 있는데 콜백만 유실된 경우일 수 있으므로 여기서
          // ad 를 dispose 하지 않는다. 늦은 dismissed/failedToShow 또는
          // 플랫폼 dispose 에서 정리한다.
          onShowTimeout();
        });
        attachCallbacksAndShow(
          ad,
          onShowed: () {
            if (!_isCurrent(g)) return;
            // 표시 성공. 시청 시간은 사용자에 달렸으므로 이후 시한은 두지
            // 않는다 — 스피너는 이 시점에 이미 해제된다.
            _cancelWatchdog();
            onShowStarted();
          },
          onDismissed: () {
            _disposePending(); // 늦게 오더라도 리소스 정리는 항상 수행
            if (!_isCurrent(g)) return;
            _finish(g);
            onDismissed();
          },
          onFailedToShow: (error) {
            _disposePending();
            if (!_isCurrent(g)) return;
            _finish(g);
            onShowFailed(error);
          },
        );
      },
      (error) {
        if (!_isCurrent(g)) return; // 늦은 실패 콜백 — 이미 타임아웃 처리됨
        _finish(g);
        onLoadFailed(error);
      },
    );
  }

  void dispose() {
    _generation++;
    _cancelWatchdog();
    _disposePending();
  }
}

/// AdMob 광고 플랫폼 구현
/// 참고: AdMob SDK 초기화는 MainInitializer._initializeAdMob()에서 앱 시작 시 수행됨
class AdmobPlatform extends AdPlatform {
  String _adUnitId = '';
  late final AdmobShowFlow<RewardedAd> _flow = AdmobShowFlow<RewardedAd>(
    startLoad: _startLoad,
    attachCallbacksAndShow: _attachCallbacksAndShow,
    disposeAd: (ad) => ad.dispose(),
  );

  AdmobPlatform(super.ref, super.context, super.id,
      AnimationController super.animationController);

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

      // SSV userId 는 표시 직전이 아니라 진입 시점에 확인한다 — 로드까지 다
      // 해 놓고 로그인 다이얼로그를 띄우는 낭비와, 표시 단계의 조기 이탈
      // 경로 하나를 없앤다. (표시 직전 재확인은 _attachCallbacksAndShow 에 유지)
      final userId = supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        logger.e('[$id] SSV userId가 없음 - 인증 세션 만료 가능성');
        stopAllAnimations();
        showRequireLoginDialog();
        return;
      }

      if (_adUnitId.isEmpty) {
        await _initAdUnitId();
      }
      startButtonAnimation();
      logger.i('[$id] 광고 로드 시작: $_adUnitId');

      _flow.run(
        onLoadTimeout: () {
          logger.w('[$id] 광고 로드 타임아웃 (${_flow.loadTimeout.inSeconds}s)');
          // '광고 로드 시간 초과' 는 isNonReportableAdError 키워드에 걸려
          // "모든 광고 소진" 안내 + Sentry 미보고로 처리된다. Pangle 로드
          // 타임아웃과 동일한 UX 를 의도한 선택이다.
          logAdLoadFailure(
            'AdMob',
            TimeoutException('admob load timeout', _flow.loadTimeout),
            _adUnitId,
            '광고 로드 시간 초과',
            StackTrace.current,
          );
          stopAllAnimations();
        },
        onLoadFailed: (error) {
          if (error is LoadAdError) {
            logger.e(
              '[$id] AdMob 광고 로드 실패 상세:\n'
              '  code: ${error.code}\n'
              '  message: ${error.message}\n'
              '  domain: ${error.domain}\n'
              '  responseInfo: ${error.responseInfo}\n'
              '  adUnitId: $_adUnitId',
            );
          }
          // 분류 근거로 실제 에러 텍스트를 넘긴다(하드코딩 라벨 금지 —
          // ad_platform.dart isNonReportableAdError doc 참조).
          logAdLoadFailure(
              'AdMob', error, _adUnitId, error.toString(), StackTrace.current);
          stopAllAnimations();
        },
        onShowStarted: () {
          logger.i('[$id] 광고가 전체 화면으로 표시됨');
          stopAllAnimations();
        },
        onShowTimeout: () {
          logger.e('[$id] 광고 표시 타임아웃 (${_flow.showTimeout.inSeconds}s) — '
              'FullScreenContentCallback 미수신');
          logAdShowFailure(
            'AdMob',
            TimeoutException('admob show timeout', _flow.showTimeout),
            _adUnitId,
            'AdMob show callback timeout', // no-fill 키워드에 안 걸리는 문구 → Sentry 보고됨
            StackTrace.current,
          );
          stopAllAnimations();
          if (context.mounted && !isDisposed) {
            showSimpleDialog(
                content: AppLocalizations.of(context).label_ads_show_fail,
                type: DialogType.error);
          }
        },
        onShowFailed: (error) {
          logAdShowFailure('AdMob', error, _adUnitId, error.toString(), null);
          stopAllAnimations();
          if (context.mounted && !isDisposed) {
            showSimpleDialog(
                content: AppLocalizations.of(context).label_ads_show_fail,
                type: DialogType.error);
          }
        },
        onDismissed: () {
          logger.i('[$id] 광고가 닫힘');
          stopAllAnimations();
          commonUtils.refreshUserProfile();
        },
      );
    });
  }

  void _startLoad(
    void Function(RewardedAd ad) onLoaded,
    void Function(Object error) onFailedToLoad,
  ) {
    unawaited(
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: onLoaded,
          onAdFailedToLoad: onFailedToLoad,
        ),
        // RewardedAd.load 가 동기/비동기 예외를 던지는 드문 경로(설정 오류 등)도
        // 같은 실패 콜백으로 합류시킨다 — 세대 가드·단일 다이얼로그가 함께 적용된다.
      ).catchError((Object e) => onFailedToLoad(e)),
    );
  }

  void _attachCallbacksAndShow(
    RewardedAd ad, {
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
  }) {
    logger.i('[$id] 광고 로드 완료');
    if (!context.mounted || isDisposed) {
      ad.dispose();
      return;
    }
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      // showAd 진입 시점 검사를 통과했지만 로드 중 세션이 만료된 경우.
      onFailedToShow(StateError('SSV userId missing at show time'));
      return;
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    logger
        .i('[$id] SSV 설정: userId=$userId, platform=$platform, adUnit=$_adUnitId');
    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: userId,
        customData: 'platform=$platform',
      ),
    );
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, error) {
        logger.e(
          '[$id] AdMob 광고 표시 실패 상세:\n'
          '  code: ${error.code}\n'
          '  message: ${error.message}\n'
          '  domain: ${error.domain}',
        );
        onFailedToShow(error);
      },
      onAdImpression: (_) {
        logger.i('[$id] 광고 노출 기록됨');
        _logGa4Impression(); // Task B-4
      },
    );
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // 보상 적립은 SSV(callback-admob)가 서버에서 독립 수행한다. 클라이언트는
        // 프로필 갱신만 하며, 이는 세대 가드 밖 — 늦게 와도 무해하고 유익하다.
        logger.i('[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, userId=$userId');
        commonUtils.refreshUserProfile();
      },
    );
  }

  void _logGa4Impression() {
    final ga4 = ga4AdContext;
    if (ga4 == null) return; // 구좌 컨텍스트 없이 임의값으로 보내지 않는다.
    unawaited(
      PicnicAnalytics.instance.logAdImpression(
        adPlatform: ga4.adPlatform,
        adSource: ga4.adSource,
        adFormat: ga4.adFormat,
        adUnitName: ga4.adUnitName,
        sectionName: ga4.sectionName,
        adCategory: ga4.adCategory,
        virtualCurrencyName: ga4.virtualCurrencyName,
        rewardAmount: ga4.rewardAmount,
      ),
    );
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    // 기존 그대로 유지 (safelyExecute 의 catch 전용 — _flow 경유 실패는
    // 여기까지 오지 않는다. rethrow 를 하지 않으므로.)
    logger.e('[$id] 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error);
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }
}
