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
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:universal_io/io.dart';

/// AdMob 로드→표시 한 사이클의 상태 기계.
///
/// - 로드/표시 각 단계에 워치독을 걸어 SDK 콜백이 하나도 오지 않아도 반드시
///   UI terminal 콜백 중 정확히 하나로 끝난다 (조사 보고서 §1.3 의 "영구 정지"
///   차단). **UI terminal** = `onLoadTimeout` / `onLoadFailed` /
///   `onShowTimeout` / `onShowFailed` / `onShowStarted` 중 하나 — 표시 성공
///   (`onShowStarted`) 도 terminal 이다. 스피너는 이미 그때 풀리고, 시청 시간은
///   사용자에 달렸으므로 더 지킬 워치독이 없기 때문이다.
/// - 세대 토큰(`_generation`)으로 늦게 도착한 SDK 콜백의 UI 액션을 무시한다.
///   **리소스 정리(`disposeAd`)만큼은 세대와 무관하게 항상** 콜백이 캡처한
///   ad 가 여전히 `_pendingAd` 일 때만(=아직 아무도 정리하지 않았을 때만)
///   수행한다(`_releaseIfPending`) — 이래야 늦게 도착한 구세대 콜백이 이미
///   시작된 신세대 attempt 의 광고를 잘못 폐기하지 않는다. `onDismissed` 는
///   추가로 — onShowed 가 실제로 이 attempt 를 끝낸 경우에만 UI 액션을
///   전달한다. showTimeout/showFailed 로 이미 실패 다이얼로그가 뜬 뒤 늦게
///   도착한 dismissed 는 리소스만 정리하고 조용히 끝난다.
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

  /// 이 attempt 를 UI terminal 상태로 만든다 — 로드 실패/타임아웃, 표시
  /// 실패/타임아웃, 그리고 **표시 성공(onShowed)** 이 각 attempt 의 UI
  /// terminal 이다. 표시 성공 이후엔 스피너가 이미 풀렸고 시청 시간은
  /// 사용자에 달렸으므로 더 지킬 워치독이 없다 — 그래서 onShowed 자체가
  /// terminal 이다. 이후 도착하는 같은 세대의 SDK 콜백은 UI 액션을
  /// 건너뛴다. `dismissed`/`onFailedToShow` 는 이 UI terminal *이후에도*
  /// 도착할 수 있는 광고 리소스 lifecycle 이벤트이며, `_generation` 이 아니라
  /// `_pendingAd` 소유권(`_releaseIfPending`)으로 독립적으로 관리한다.
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

  /// 콜백이 캡처한 [ad] 가 여전히 `_pendingAd` 일 때만(=아직 아무도 정리하지
  /// 않았을 때만) 정리하고 `true` 를 반환한다. 새 attempt 가 이미 시작돼
  /// `_pendingAd` 가 다른 광고(또는 null)를 가리키면 이 ad 는 이미 다른
  /// 경로(다음 `run()` 의 `_disposePending()`)로 정리됐다는 뜻이므로 아무
  /// 것도 건드리지 않고(중복 dispose 방지) `false` 를 반환한다 — 늦게 도착한
  /// 콜백이 **현재** 세대의 광고를 폐기하는 사고를 막는다.
  bool _releaseIfPending(T ad) {
    if (!identical(_pendingAd, ad)) return false;
    _pendingAd = null;
    disposeAd(ad);
    return true;
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

    void handleLoadFailed(Object error) {
      if (!_isCurrent(g)) return; // 늦은 실패 콜백 — 이미 타임아웃 처리됨
      _finish(g);
      onLoadFailed(error);
    }

    try {
      startLoad(
        (ad) {
          if (!_isCurrent(g)) {
            // 타임아웃/재시도 이후 늦게 도착한 onAdLoaded — 조용히 폐기.
            disposeAd(ad);
            return;
          }
          _cancelWatchdog();
          _pendingAd = ad;
          // 이 attempt 가 onShowed 로 끝났는지 — dismissed 는 onShowed 뒤에만
          // "정상적인 후속 이벤트"로 UI 액션을 전달한다. showTimeout/showFailed
          // 처럼 onShowed 없이 이미 실패 다이얼로그가 뜬 뒤에 늦게 도착한
          // dismissed 는 리소스만 정리하고 UI 액션은 억제한다.
          var showedFired = false;
          _watchdog = Timer(showTimeout, () {
            if (!_isCurrent(g)) return;
            _finish(g);
            // 광고가 실제로 떠 있는데 콜백만 유실된 경우일 수 있으므로 여기서
            // ad 를 dispose 하지 않는다. 늦은 dismissed/failedToShow 또는
            // 플랫폼 dispose 에서 정리한다.
            onShowTimeout();
          });

          void handleShowFailed(Object error) {
            _releaseIfPending(ad); // 늦게 오더라도 리소스 정리는 항상 수행
            if (!_isCurrent(g)) return; // 이미 다른 경로로 이 attempt 가 끝남
            _finish(g);
            onShowFailed(error);
          }

          try {
            attachCallbacksAndShow(
              ad,
              onShowed: () {
                if (!_isCurrent(g)) return;
                // 표시 성공 = 이 attempt 의 UI terminal.
                showedFired = true;
                _finish(g);
                onShowStarted();
              },
              onDismissed: () {
                // 리소스 정리는 이 ad 가 여전히 pending 일 때만(=아직 아무도
                // 정리하지 않았을 때만) 수행한다 — 세대가 이미 넘어간 늦은
                // dismissed 가 **다음** attempt 의 pendingAd 를 건드리는
                // 사고(BLOCKER-1)를 막는다. UI 액션(onDismissed 콜백)은
                // onShowed 가 실제로 이 attempt 를 끝냈을 때만 전달한다 —
                // 그러지 않으면 이미 실패 다이얼로그를 띄운 attempt 에
                // 뒤늦게 "닫힘" 이벤트가 겹쳐 뜬다.
                final wasPending = _releaseIfPending(ad);
                if (!wasPending || !showedFired) return;
                _finish(g);
                onDismissed();
              },
              onFailedToShow: handleShowFailed,
            );
          } catch (e) {
            // delegate 가 콜백 배선 중 동기 throw 하면 표시 실패 단일
            // 경로로 합류시킨다 — 그러지 않으면 표시 워치독이 그대로
            // 남아 있다가 나중에 또 발화해 다이얼로그가 두 번 뜬다.
            handleShowFailed(e);
          }
        },
        handleLoadFailed,
      );
    } catch (e) {
      // delegate 가 동기 throw 하면(예: RewardedAd.load 설정 오류) 로드
      // 실패 단일 경로로 합류시킨다 — 로드 워치독이 그대로 남아 있다가
      // 나중에 또 발화해 다이얼로그가 두 번 뜨는 것을 막는다.
      handleLoadFailed(e);
    }
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

  /// 현재 attempt 의 "프로필 1회 갱신" 클로저 — [beginProfileRefreshAttempt] 가
  /// attempt 마다 새로 만들어 심는다.
  ///
  /// MINOR-1: 예전엔 인스턴스 필드 하나(`_profileRefreshedForAttempt`)를 모든
  /// attempt 가 공유했다. B 의 `showAd()` 가 그 필드를 리셋한 뒤 A 의 늦은
  /// reward 콜백이 같은 필드를 true 로 만들면, B 자신의 dismissed/reward 가
  /// "이미 갱신함"으로 오판돼 스킵됐다 — dedup 은 attempt 를 구분하지 못했다.
  /// 지금은 `onDismissed`(showAd() 안에서 직접 캡처)와 `onUserEarnedReward`
  /// (`_attachCallbacksAndShow` 가 배선 시점에 [captureProfileRefreshOnce] 로
  /// 로컬에 캡처) 양쪽 다 이 필드가 아니라 attempt 전용 클로저를 쓴다. 다음
  /// attempt 가 이 필드를 덮어써도 이미 배선된 콜백에는 영향이 없다.
  void Function() _currentProfileRefreshOnce = () {};

  /// 새 attempt 를 시작하며 attempt 전용 dedup 클로저를 만들어 필드에 심고
  /// 그대로 반환한다. `showAd()` 는 반환값을 `onDismissed` 클로저에 직접
  /// 캡처해 쓴다 — 필드를 다시 읽지 않으므로 다음 attempt 의 리셋에 영향받지
  /// 않는다.
  @visibleForTesting
  void Function() beginProfileRefreshAttempt() {
    var refreshed = false;
    void refreshOnce() {
      if (refreshed) return;
      refreshed = true;
      commonUtils.refreshUserProfile();
    }

    _currentProfileRefreshOnce = refreshOnce;
    return refreshOnce;
  }

  /// `_attachCallbacksAndShow` 가 콜백 배선 시점에 현재 attempt 의 dedup
  /// 클로저를 로컬로 캡처할 때 쓴다 — 늦게 오는 `onUserEarnedReward` 가 그
  /// 사이 시작된 다음 attempt 의 dedup 상태를 잘못 건드리지 않도록.
  @visibleForTesting
  void Function() captureProfileRefreshOnce() => _currentProfileRefreshOnce;

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
      final refreshUserProfileOnce = beginProfileRefreshAttempt();

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
        onLoadFailed: handleLoadFailedForFlow,
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
          // MINOR-1: attempt 전용 클로저를 직접 캡처해 쓴다 — 필드를 다시
          // 읽지 않으므로 다음 attempt 의 beginProfileRefreshAttempt() 리셋에
          // 영향받지 않는다.
          refreshUserProfileOnce();
        },
      );
    });
  }

  /// `onLoadFailed` 배선 로직 — 필드/컨텍스트에 의존하지 않는 부분은 없지만
  /// `_flow.run()` 호출문 안의 인라인 클로저로 남겨두면 유닛 테스트가 SDK
  /// 배선 없이는 이 경로를 exercise 할 수 없다. 그래서 이름 있는 메서드로
  /// 뽑아 `@visibleForTesting` 로 노출한다.
  ///
  /// MAJOR-3: `logAdLoadFailure` 의 message 인자는 반드시 **실제 에러
  /// 텍스트**([error.toString()])여야 한다 — 하드코딩 라벨을 넘기면
  /// isNonReportableAdError 의 '광고 로드 실패' 키워드에 걸려 모든 예외가
  /// "모든 광고 소진"으로 뭉개지고 Sentry 보고도 막힌다(PICNIC-2377 에서
  /// Pangle·AdMob 양쪽에서 고친 결함). 이 배선을 직접 exercise 하는 테스트가
  /// 없으면 조용히 되돌아갈 수 있다.
  @visibleForTesting
  void handleLoadFailedForFlow(Object error) {
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
      // ad.dispose() 를 직접 부르고 return 하면 flow 의 _pendingAd 가 이미
      // dispose 된 이 ad 를 계속 가리켜, 다음 attempt 시작 시 이중 dispose
      // 위험이 생긴다(BLOCKER-2 와 같은 종류의 "terminal 누락"). onFailedToShow
      // 를 통해 flow 의 단일 정리 경로로 합류시킨다.
      onFailedToShow(StateError('context unmounted before show'));
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
    // MAJOR-2: 콜백 배선 시점에 GA4 컨텍스트를 스냅샷한다 — onAdImpression 이
    // 늦게 도착했을 때 그 사이 새 attempt 가 ga4AdContext 를 덮어써도 이번
    // attempt(=이번 구좌) 로 정확히 귀속된다(Pangle 의 _listenForImpressionOnce
    // 와 같은 패턴).
    final logGa4Impression = captureGa4ImpressionLogger();
    // MINOR-1: 이 attempt 의 dedup 클로저를 배선 시점에 로컬로 캡처한다 —
    // 다음 attempt 의 beginProfileRefreshAttempt() 가 필드를 덮어써도 이미
    // 배선된 이 onUserEarnedReward 콜백에는 영향이 없다.
    final refreshUserProfileOnce = captureProfileRefreshOnce();
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
        logGa4Impression(); // Task B-4
      },
    );
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // 보상 적립은 SSV(callback-admob)가 서버에서 독립 수행한다. 클라이언트는
        // 프로필 갱신만 하며, 이는 세대 가드 밖 — 늦게 와도 무해하고 유익하다.
        logger.i('[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, userId=$userId');
        refreshUserProfileOnce(); // MINOR-1: onDismissed 와 attempt 당 1회로 dedup
      },
    );
  }

  /// `_attachCallbacksAndShow` 가 콜백 배선 시점에 [ga4AdContext] 스냅샷을
  /// 캡처해 반환한다 — 반환된 클로저를 호출하면 그 스냅샷으로 노출을
  /// 로깅한다(MAJOR-2). `@visibleForTesting` 로 노출해 `RewardedAd` 없이도
  /// "배선 시점 캡처가 이후 attempt 의 ga4AdContext 갱신에 영향받지 않는다"를
  /// 직접 검증한다.
  @visibleForTesting
  void Function() captureGa4ImpressionLogger() {
    final ga4Snapshot = ga4AdContext;
    return () => logGa4Impression(ga4Snapshot);
  }

  @visibleForTesting
  void logGa4Impression(FreeChargeAdGa4Context? ga4) {
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
