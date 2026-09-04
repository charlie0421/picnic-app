import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:video_player/video_player.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/widgets/ad_reward_dialog_host.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

/// '더보기'를 눌렀을 때 광고주 랜딩으로 보내고, 그 클릭을 서버에 기록한다.
///
/// [reportClick] 은 **launch 이전에** 시작한다. 외부 브라우저가 뜨는 순간 앱이
/// 백그라운드로 밀리고 iOS 는 진행 중이던 요청을 정지시킬 수 있어, launch 뒤에
/// 시작하면 클릭이 통계에서 통째로 누락된다. 대신 launch 가 실패하는 드문 경우
/// 클릭이 소폭 과다 집계될 수 있다 — 통계 누락보다 낫다고 보고 택한 쪽이다.
/// GA4 `ad_cta_click` 은 로컬 버퍼에 쌓였다가 나중에 전송되므로 기존대로 이동
/// 성공 이후에 남긴다.
///
/// "시작"이 "요청이 소켓에 실렸다"를 뜻하지는 않는다. `functions_client` 의
/// `invoke` 는 `request.send()` 전에 body 를 isolate 에서 인코딩하며
/// (`functions_client/lib/src/functions_client.dart` 의 `_isolate.encode`),
/// 그 await 지점에서 제어가 돌아오기 때문에 launch 가 먼저 실행될 수 있다.
/// body 가 수십 바이트고 launch 자체가 플랫폼 채널 왕복이라 실제로는 대개 먼저
/// 나가지만, 보장은 아니다 — 그래서 실패한 기록은 재시도할 수 있어야 한다
/// ([AdCtaClickReporter]).
///
/// 기록 실패는 삼킨다. 통계용 쓰기가 광고주 랜딩 이동을 막아선 안 된다.
///
/// 반환값은 실제로 이동했는지 여부. [launch] 가 external/in-app 두 경로 모두
/// 예외를 던지면 그대로 전파된다(호출자가 이동 실패로 처리).
@visibleForTesting
Future<bool> openAdCta(
  String url, {
  required Future<bool> Function(Uri uri, {required bool external}) launch,
  Future<void> Function()? reportClick,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (reportClick != null) {
    unawaited(Future.sync(reportClick).catchError((_) {}));
  }
  try {
    return await launch(uri, external: true);
  } catch (_) {
    return await launch(uri, external: false);
  }
}

/// '더보기' 서버 기록의 단발 가드 — **성공 1회** 기준.
///
/// "시청 건당 1회"를 시도 기준으로 세면, 첫 탭이 타임아웃·5xx·백그라운드 정지로
/// 실패했을 때 그 시청 건의 클릭이 영구히 사라진다. 사용자가 랜딩에서 돌아와 다시
/// 눌러도 요청이 나가지 않기 때문이다. 서버 기록은 멱등하므로(같은 임프레션의
/// 두 번째 호출은 `recorded:false`) 재시도에 비용이 없다.
///
/// 진행 중 래치는 따로 둔다 — 연타로 같은 요청이 두 번 나가는 것만 막고,
/// 끝난 뒤의 재시도는 막지 않는다.
@visibleForTesting
class AdCtaClickReporter {
  AdCtaClickReporter(this._report);

  /// 서버 기록을 시도하고 성공 여부를 돌려준다.
  final Future<bool> Function() _report;

  bool _reported = false;
  bool _inFlight = false;

  /// 이 시청 건의 클릭이 서버에 남았는가.
  bool get reported => _reported;

  Future<void> call() async {
    if (_reported || _inFlight) return;
    _inFlight = true;
    try {
      _reported = await _report();
    } finally {
      // 예외가 나가도 래치는 반드시 풀어, 다음 탭이 재시도할 수 있게 한다.
      _inFlight = false;
    }
  }
}

/// Pure logic helpers for AdShortformFullscreenPage, testable without widget tree.
@visibleForTesting
class AdShortformLogic {
  static bool shouldUseLegacyBonusUx(InternalShortformViewResponse response) =>
      response.reward == null && response.rewardAdded > 0;

  static bool shouldPresentWalletRewardImmediately(
    InternalShortformViewResponse response,
  ) => response.reward?.state == AdRewardState.granted;

  static WalletSummaryModel? walletSummaryToApply(
    InternalShortformViewResponse response,
  ) => response.reward?.wallet;

  static bool shouldRefreshLegacyProfile(
    InternalShortformViewResponse response,
  ) => response.ok && response.reward == null;

  /// Applies the credited reward to the wallet summary (별사탕 파우치).
  ///
  /// Runs through the app-level [ProviderContainer], captured while the page
  /// was mounted - the same move as the purchase flow's
  /// `ContainerWalletSummaryApplier` - because the candy was credited
  /// server-side the moment the view callback settled: even if the user
  /// already left the ad route, the pouch must reflect the new balance.
  ///
  /// A wallet-aware response carries the settled balance and is written as-is;
  /// a legacy response carries no wallet snapshot, so the summary is re-read
  /// from the server. (Was: legacy path refreshed the user profile only,
  /// which left `walletSummaryProvider` - and the pouch it drives - stale.)
  static Future<void> applyRewardOutcome({
    required ProviderContainer container,
    required InternalShortformViewResponse response,
  }) async {
    final wallet = walletSummaryToApply(response);
    if (wallet != null) {
      container.read(walletSummaryProvider.notifier).setSummary(wallet);
      return;
    }
    if (shouldRefreshLegacyProfile(response)) {
      await container.read(walletSummaryProvider.notifier).refresh();
    }
  }

  /// Whether the countdown (<= 5s remaining) should start.
  static bool shouldStartCountdown({
    required bool ctaRevealStarted,
    required bool isInitialized,
    required Duration remaining,
  }) {
    if (ctaRevealStarted) return false;
    if (!isInitialized) return false;
    return !remaining.isNegative && remaining <= const Duration(seconds: 5);
  }

  /// Whether playback is complete (position within 150ms of duration).
  static bool isPlaybackComplete({
    required bool isInitialized,
    required Duration position,
    required Duration duration,
  }) {
    return isInitialized &&
        position >= (duration - const Duration(milliseconds: 150));
  }

  static bool shouldReportView({
    required bool isInitialized,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) {
    if (!isInitialized || duration <= Duration.zero) return false;
    if (isPlaybackComplete(
      isInitialized: isInitialized,
      position: position,
      duration: duration,
    )) {
      return true;
    }
    final remaining = duration - position;
    return !isPlaying &&
        position > Duration.zero &&
        !remaining.isNegative &&
        remaining <= const Duration(seconds: 1);
  }

  /// Whether close action can happen immediately (video finished + reward done).
  static bool canCloseImmediately({
    required bool isInitialized,
    required bool isBuffering,
    required Duration position,
    required Duration duration,
  }) {
    return isInitialized && !isBuffering && position >= duration;
  }

  /// Whether the CTA/More button should be visible.
  static bool shouldShowCtaButton({
    required bool ctaRevealStarted,
    required bool finished,
    required String? ctaUrl,
  }) {
    if (ctaUrl == null || ctaUrl.isEmpty) return false;
    return ctaRevealStarted || finished;
  }

  /// Whether the CTA/More button should be enabled (clickable).
  static bool isCtaButtonEnabled({
    required bool finished,
    required bool viewReported,
    required bool rewarding,
  }) {
    return finished && viewReported && !rewarding;
  }

  /// CTA navigation is independent from reward completion. Once the button is
  /// visible, it stays actionable unless the reward callback owns the UI.
  static bool isCtaActionEnabled({
    required bool visible,
    required bool rewarding,
  }) {
    return visible && !rewarding;
  }

  /// Whether the ad route may close itself right after the CTA was opened.
  ///
  /// The CTA is only a landing-page hop; it must never cost the user the candy
  /// they already watched for. Popping the route disposes the video controller,
  /// which removes the `_onProgress` listener and with it the ONLY path to
  /// `_startReward()` - so closing before the view reward has settled forfeits
  /// the base watch reward entirely.
  ///
  /// The button becomes visible with 5s of playback left
  /// ([shouldShowCtaButton]) and stays actionable by design
  /// ([isCtaActionEnabled]), so "CTA tapped" and "reward settled" genuinely do
  /// not imply each other. When the reward has not settled we leave the route
  /// mounted: the user returns from the browser, playback finishes, and the
  /// reward lands normally. The close (X) button stays available throughout, so
  /// nobody is trapped.
  ///
  /// (Was: the route popped unconditionally, so tapping '더보기' during those
  /// last 5 seconds dropped the view reward on the floor.)
  static bool shouldCloseAfterCta({required bool viewReported}) => viewReported;

  static bool isCloseActionEnabled({
    required bool finished,
    required bool viewReported,
    required bool rewarding,
  }) {
    return true;
  }

  /// Whether the loader overlay should be visible.
  static bool shouldShowLoader({
    required bool loading,
    required bool isInitialized,
    required bool isBuffering,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required bool finished,
  }) {
    return loading ||
        !isInitialized ||
        (isBuffering && !finished) ||
        (!isPlaying && position == Duration.zero);
  }

  /// Whether the countdown badge should be visible.
  static bool shouldShowCountdown({
    required bool finished,
    required int remainingSeconds,
  }) {
    return !finished && remainingSeconds > 0 && remainingSeconds <= 5;
  }

  /// The close (X) button must ALWAYS be rendered so the user can escape even
  /// when the controller never initializes (infinite-pulse guard). Kept as a
  /// named helper for explicitness/testability.
  static bool shouldRenderCloseButton({required bool hasController}) {
    return true;
  }

  /// Whether a video-load error dialog should be raised for an empty videoUrl.
  /// anti-abuse rate-limit returns an empty url with [blocked] = true and pops
  /// the route itself, so we must NOT raise a duplicate error dialog in that
  /// case. Any other empty/failed url should surface the error instead of
  /// silently pulsing forever.
  static bool shouldErrorOnEmptyVideoUrl({
    required String videoUrl,
    required bool blocked,
  }) {
    if (videoUrl.isNotEmpty) return false;
    return !blocked;
  }
}

/// Legacy shortform 응답도 granted-reward 경로와 같은 durable outbox 계약을 탄다.
///
/// 예전 코드는 위젯의 `_earnLogged`를 sink 호출 전에 true로 만들고 bool 결과를
/// 버렸다. 실패하면 해당 impression이 다시 흐를 곳이 없어 영구 누락됐다. 이제
/// 서버가 돌려준 impression reference를 idempotency key로 payload부터 저장한다.
@visibleForTesting
Future<bool> enqueueLegacyShortformEarnAnalytics({
  required InternalShortformViewResponse response,
  required FreeChargeAdGa4Context ga4,
  EarnAnalyticsStore? store,
}) {
  return (store ?? EarnAnalyticsStore()).enqueueEarn(
    reference:
        '${AdRewardReferenceType.internalImpression.wireValue}:${response.impressionId}',
    virtualCurrencyName: FreeChargeGa4.currencyName(
      WalletCurrency.bonusStarCandy,
    ),
    rewardAmount: response.rewardAdded,
    earnMethod: FreeChargeGa4.earnMethodRewardedAd,
    sectionName: ga4.sectionName,
    adCategory: ga4.adCategory,
  );
}

class AdShortformFullscreenPage extends ConsumerStatefulWidget {
  final String videoUrl;
  final String? ctaUrl;
  final Future<InternalShortformViewResponse> Function() onViewComplete;

  /// Loads the ad at route-entry time.
  ///
  /// [blocked] signals that an anti-abuse rate-limit already popped the route
  /// and is showing its own dialog; in that case the page must stay silent
  /// (no duplicate error dialog). Any other empty videoUrl is treated as a
  /// load failure and surfaces an error instead of pulsing forever.
  final Future<({String videoUrl, String? ctaUrl, bool blocked})> Function()?
  loadAd;

  /// `ad_request` 를 발송한 구좌의 GA4 컨텍스트. null 이면 이 화면에서
  /// 광고 이벤트를 보내지 않는다(임의값으로 채우지 않는다).
  final FreeChargeAdGa4Context? ga4;

  /// Called after a wallet-aware reward receipt has rendered its first frame.
  /// The platform acknowledges the durable pending record at this point.
  final Future<void> Function(AdRewardStatusModel status)?
  onWalletRewardPresented;

  /// '더보기'로 이동할 때 그 클릭을 서버에 기록한다 (시청 1회당 **성공** 1번).
  /// 어드민 캠페인 리포트의 `more_clicks` 가 여기서 채워진다.
  /// 기록에 성공했으면 true — 실패는 [AdCtaClickReporter] 가 재시도로 남겨둔다.
  final Future<bool> Function()? onCtaClick;

  const AdShortformFullscreenPage({
    super.key,
    required this.videoUrl,
    required this.onViewComplete,
    this.ctaUrl,
    this.loadAd,
    this.ga4,
    this.onWalletRewardPresented,
    this.onCtaClick,
  });

  @override
  ConsumerState<AdShortformFullscreenPage> createState() =>
      _AdShortformFullscreenPageState();
}

class _AdShortformFullscreenPageState
    extends ConsumerState<AdShortformFullscreenPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _viewReported = false;
  bool _loading = true;
  bool _rewarding = false;
  String? _resolvedVideoUrl;
  String? _resolvedCtaUrl;
  bool _ctaRevealStarted =
      false; // once countdown starts, keep More button visible
  final GlobalKey<LoadingOverlayState> _loadingOverlayKey =
      GlobalKey<LoadingOverlayState>();

  /// Watchdog: if the controller never initializes within this window (server
  /// failure / network stall anywhere in initialize/setLooping/setVolume/play),
  /// force a single error+exit so the loader can never pulse forever.
  static const Duration _watchdogTimeout = Duration(seconds: 20);

  /// Timeout for the underlying [VideoPlayerController.initialize] call, which
  /// itself has no timeout (cf. pangle_platform.dart's 5s guard).
  static const Duration _initializeTimeout = Duration(seconds: 15);

  Timer? _watchdog;
  bool _errorDialogShown = false;

  /// GA4 단발 발송 가드. 위젯 리빌드/리스너 재호출로 같은 시청 건의
  /// ad_impression·earn_virtual_currency·ad_cta_click 이 2번 나가지 않게 한다.
  bool _impressionLogged = false;
  bool _earnLogged = false;
  bool _earnLogging = false;
  bool _adCtaClickLogged = false;

  /// 서버 클릭 기록(`callback-ad-shortform-more`) 단발 가드 — 성공 1회 기준.
  late final AdCtaClickReporter _ctaClickReporter = AdCtaClickReporter(
    () async => await widget.onCtaClick?.call() ?? false,
  );

  /// App-level Riverpod container, captured while this route is mounted, so a
  /// reward that settles after the user already closed the ad can still update
  /// the wallet summary (cf. `ContainerWalletSummaryApplier` in the purchase
  /// settlement path - `ConsumerState.ref` throws once unmounted).
  late final ProviderContainer _rewardContainer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rewardContainer = ProviderScope.containerOf(context, listen: false);
    _enterImmersive();
    _startWatchdog();
    _initializeFlow();
  }

  /// Starts the single-exit watchdog. Cancelled when the controller is set,
  /// on dispose, or once an error dialog is shown.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(_watchdogTimeout, () {
      if (!mounted) return;
      if (_controller != null) return; // controller arrived in time
      if (_errorDialogShown) return; // error path already handled exit
      _showVideoLoadErrorDialog(
        TimeoutException('ad-shortform watchdog: controller never initialized'),
      );
    });
  }

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  Future<void> _enterImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initializeFlow() async {
    try {
      // anti-abuse rate-limit 등으로 loadAd 가 빈 url 을 sentinel 로 반환한 경우,
      // platform 측이 route pop + rate-limited dialog 를 이미 예약했음을 blocked=true
      // 로 알려준다. 그 외(network/server 실패·예외)는 빈 url 이라도 에러 다이얼로그를
      // 띄워 무한펄스로 빠지지 않게 한다.
      var blocked = false;
      if (widget.loadAd != null) {
        try {
          final result = await widget.loadAd!();
          _resolvedVideoUrl = result.videoUrl;
          _resolvedCtaUrl = result.ctaUrl;
          blocked = result.blocked;
        } catch (e) {
          // loadAd 자체가 throw (anti-abuse 아님) → 에러 다이얼로그 + pop.
          _showVideoLoadErrorDialog(e);
          return;
        }
      } else {
        _resolvedVideoUrl = widget.videoUrl;
        _resolvedCtaUrl = widget.ctaUrl;
      }

      final resolvedUrl = _resolvedVideoUrl ?? '';
      if (resolvedUrl.isEmpty) {
        // blocked(anti-abuse) 면 조용히 종료(platform 이 dialog/pop 담당),
        // 그 외 빈 url 은 실패로 보고 에러 다이얼로그.
        if (AdShortformLogic.shouldErrorOnEmptyVideoUrl(
          videoUrl: resolvedUrl,
          blocked: blocked,
        )) {
          _showVideoLoadErrorDialog(
            StateError('ad-shortform: empty video_url'),
          );
        }
        return;
      }
      if (!mounted) return;
      try {
        await _initPlayer(resolvedUrl);
      } catch (e) {
        _showVideoLoadErrorDialog(e);
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _initPlayer(String videoUrl) async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      // initialize() 자체엔 타임아웃이 없어 네트워크 stall 시 영구 hang.
      // TimeoutException 은 아래 generic catch 로 흘러 에러 다이얼로그로 이어진다.
      await ctrl.initialize().timeout(_initializeTimeout);
    } on PlatformException catch (e) {
      _showVideoLoadErrorDialog(e);
      return;
    } catch (e) {
      _showVideoLoadErrorDialog(e);
      return;
    }
    try {
      await ctrl.setLooping(false);
    } catch (_) {}
    try {
      await ctrl.setVolume(1.0);
    } catch (_) {}
    ctrl.addListener(_onProgress);
    // 컨트롤러가 준비됐으니 워치독 해제 — 단일 탈출 경로 유지.
    _cancelWatchdog();
    setState(() {
      _controller = ctrl;
    });
    try {
      await ctrl.play();
    } on PlatformException catch (e) {
      _showVideoLoadErrorDialog(e);
      return;
    } catch (e) {
      _showVideoLoadErrorDialog(e);
      return;
    }
    // ad_impression (스펙 §2-6): 재생이 실제로 시작된 시점이 자체 숏폼 광고의
    // '노출'이다. 로드/초기화 실패 경로는 위에서 return 되므로 여기 오지 않는다.
    _logAdImpression();
  }

  /// `ad_impression` — 시청 건당 1회.
  void _logAdImpression() {
    final ga4 = widget.ga4;
    if (ga4 == null || _impressionLogged) return;
    _impressionLogged = true;
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

  void _showVideoLoadErrorDialog(dynamic error) {
    if (!mounted) return;
    // 워치독·initialize 타임아웃·loadAd 예외 등 여러 경로에서 호출될 수 있으므로
    // 중복 다이얼로그를 막는다.
    if (_errorDialogShown) return;
    _errorDialogShown = true;
    _cancelWatchdog();
    // 권한/보호된 리소스 등으로 재생 실패 시 공통 에러 다이얼로그 표시 후 화면 종료
    void closePage() {
      final c = navigatorKey.currentContext;
      if (c != null && c.mounted) Navigator.of(c).pop();
      if (mounted) Navigator.of(context).maybePop();
    }

    final message = AppLocalizations.of(context).label_ads_load_fail;
    showSimpleDialog(
      type: DialogType.error,
      content: message,
      onOk: closePage,
      onCancel: closePage,
    );
  }

  void _onProgress() {
    final v = _controller;
    if (v == null) return;
    final value = v.value;
    // Mark countdown start (<= 5s remaining) to keep More button visible without flicker
    if (AdShortformLogic.shouldStartCountdown(
      ctaRevealStarted: _ctaRevealStarted,
      isInitialized: value.isInitialized,
      remaining: value.duration - value.position,
    )) {
      setState(() {
        _ctaRevealStarted = true;
      });
    }
    // 재생 완료 시 자동 적립 시작 (중복 방지)
    if (AdShortformLogic.shouldReportView(
          isInitialized: value.isInitialized,
          isPlaying: value.isPlaying,
          position: value.position,
          duration: value.duration,
        ) &&
        !_viewReported &&
        !_rewarding) {
      _startReward();
    }
  }

  Future<void> _startReward() async {
    if (_rewarding || _viewReported) return;
    setState(() {
      _rewarding = true;
    });
    _loadingOverlayKey.currentState?.show();
    InternalShortformViewResponse? response;
    try {
      response = await widget.onViewComplete();
      if (mounted) {
        setState(() {
          _viewReported = true;
        });
      }
    } catch (_) {
      // 보상 실패 시 추가 안내 없이 진행
    } finally {
      _loadingOverlayKey.currentState?.hide();
      if (mounted) {
        setState(() {
          _rewarding = false;
        });
      }
    }
    if (response == null) return;
    // 서버는 이미 적립을 끝냈으므로 파우치(walletSummaryProvider) 반영은 페이지
    // mount 여부와 무관하게 실행한다 - 구매 정산이 WalletSummaryApplier 로
    // 지갑을 쓰는 것과 같은 이유. (기존엔 mounted 뒤에서 프로필만 갱신해
    // 광고를 닫고 상점으로 돌아오면 파우치가 이전 잔액으로 남았다.)
    await AdShortformLogic.applyRewardOutcome(
      container: _rewardContainer,
      response: response,
    );
    if (AdShortformLogic.shouldRefreshLegacyProfile(response) && mounted) {
      await ref.read(userInfoProvider.notifier).getUserProfiles();
    }
    if (AdShortformLogic.shouldPresentWalletRewardImmediately(response) &&
        mounted) {
      await _showWalletRewardReceipt(response.reward!);
      return;
    }
    if (AdShortformLogic.shouldUseLegacyBonusUx(response)) {
      // earn_virtual_currency (스펙 §2-7) — legacy 응답 경로.
      //
      // 발송 기준은 SDK 콜백이 아니라 **서버 적립 성공**이다:
      //   - `onViewComplete()` 가 throw 하면 response 는 null 이라 여기 못 온다.
      //   - `shouldUseLegacyBonusUx` == `reward == null && rewardAdded > 0`,
      //     즉 서버가 적립 수량을 확정해 돌려준 경우에만 참이다.
      //   - wallet-aware 응답(`reward != null`)은 서버 확정 시점이 적립 폴링
      //     이후라, 중복을 피하려 여기서 보내지 않고 AdRewardDialogHost 가
      //     granted 상태에서 한 번만 보낸다.
      // legacy 계약은 보너스 스타캔디를 적립한다(receiptFromInternalShortformView).
      _logEarnVirtualCurrency(response);

      // 구매 성공과 동일한 공용 적립 영수증 다이얼로그를 재사용한다
      // (적립 수량 + 현재 잔액). wallet-aware 응답의 영수증은
      // AdRewardDialogHost 가 담당하므로 여기는 legacy 응답만 온다.
      final receipt = receiptFromInternalShortformView(response);
      final dialogContext = mounted ? context : navigatorKey.currentContext;
      if (receipt != null && dialogContext != null && dialogContext.mounted) {
        await showCandyRewardReceiptDialog(dialogContext, receipt);
      }
    }
  }

  Future<void> _showWalletRewardReceipt(AdRewardStatusModel status) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdRewardDialogBody(
        status: status,
        onFirstFrame: () async {
          final acknowledge = widget.onWalletRewardPresented;
          if (acknowledge != null) await acknowledge(status);
        },
      ),
    );
  }

  Widget _buildPulseOverlay(bool visible) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1.0 : 0.0,
        child: Center(child: AdLoadingOverlay.indicator),
      ),
    );
  }

  /// The circular close (X) icon. Always rendered so the user is never trapped
  /// in the loader. [onTap] is null when the close action is intentionally
  /// disabled (e.g. reward in progress at the end of playback).
  Widget _buildCloseIcon({required VoidCallback? onTap}) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Close',
      child: GestureDetector(
        key: const Key('ad-shortform-close'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey500),
              ),
              child: Icon(Icons.close, color: AppColors.grey500, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleClosePressed() async {
    // 컨트롤러가 아직 없으면(로딩/실패 중) 재생 중이 아니므로 확인 다이얼로그 없이
    // 즉시 route pop — 무한펄스에 갇히지 않는 탈출 경로.
    if (_controller == null) {
      debugPrint('[internal] close pressed (controller null) -> pop');
      _cancelWatchdog();
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    final v = _controller?.value;
    final canClose =
        v != null &&
        AdShortformLogic.canCloseImmediately(
          isInitialized: v.isInitialized,
          isBuffering: v.isBuffering,
          position: v.position,
          duration: v.duration,
        );
    if (canClose) {
      debugPrint('[internal] close pressed (finished=true)');
      debugPrint('[internal] closing route');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    try {
      await _controller?.pause();
    } catch (_) {}
    debugPrint('[internal] close pressed (confirm dialog)');
    final i18n = AppLocalizations.of(navigatorKey.currentContext!);
    showSimpleDialog(
      title: i18n.ad_close_confirm_title,
      content: i18n.ad_close_confirm_message,
      onCancel: () async {
        debugPrint('[internal] close confirm: cancel (resume playing)');
        try {
          await _controller?.play();
        } catch (_) {}
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
      },
      onOk: () {
        debugPrint('[internal] close confirm: ok (no reward)');
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
        if (mounted) Navigator.of(context).maybePop();
      },
    );
  }

  /// `earn_virtual_currency` — 시청 건당 1회.
  void _logEarnVirtualCurrency(InternalShortformViewResponse response) {
    final ga4 = widget.ga4;
    if (ga4 == null || _earnLogged || _earnLogging) return;
    _earnLogging = true;
    unawaited(
      enqueueLegacyShortformEarnAnalytics(response: response, ga4: ga4)
          .then((stored) {
            _earnLogged = stored;
          })
          .whenComplete(() {
            _earnLogging = false;
          }),
    );
  }

  Future<void> _openCta(String url) async {
    final launched = await openAdCta(
      url,
      launch: (uri, {required external}) => external
          ? launchUrl(uri, mode: LaunchMode.externalApplication)
          : launchUrl(uri),
      reportClick: _ctaClickReporter.call,
    );
    // ad_cta_click (스펙 §2-8): '더보기'로 실제 이동한 시점. launchUrl 이 두 경로 모두
    // 실패하면(예외) 이동하지 않으므로 발송하지 않는다.
    // 이동에 실패했으면(false 반환) 클릭 이벤트를 보내지 않는다.
    if (launched) _logAdCtaClick(url);
  }

  /// `ad_cta_click` — 시청 건당 1회.
  void _logAdCtaClick(String url) {
    final ga4 = widget.ga4;
    if (ga4 == null || _adCtaClickLogged) return;
    _adCtaClickLogged = true;
    unawaited(
      PicnicAnalytics.instance.logAdCtaClick(
        adPlatform: ga4.adPlatform,
        adSource: ga4.adSource,
        adFormat: ga4.adFormat,
        adUnitName: ga4.adUnitName,
        sectionName: ga4.sectionName,
        adCategory: ga4.adCategory,
        destinationType: FreeChargeGa4.destinationType(url),
      ),
    );
  }

  /// '더보기'로 광고주 랜딩에 다녀온 뒤 재생을 이어 붙인다.
  ///
  /// CTA 를 누르면 외부 브라우저가 앱을 백그라운드로 밀고, OS 가 재생을 멈춘다.
  /// [AdShortformLogic.shouldCloseAfterCta] 덕에 라우트는 살아 있지만, 돌아왔을
  /// 때 영상이 멈춘 채로 있으면 `_onProgress` 가 다시 돌지 않아
  /// [AdShortformLogic.shouldReportView] 조건에 영원히 도달하지 못한다 — 결국
  /// 시청 보상이 유실되고 화면도 자동으로 닫히지 않는다.
  ///
  /// 반대로 백그라운드에서도 재생이 계속되는 플랫폼에서는 광고 소리가 랜딩
  /// 페이지 위로 흐른다. 양쪽 모두를 막으려면 나갈 때 멈추고 돌아올 때 이어야
  /// 한다. 이미 적립이 끝났거나(`_viewReported`) 보상 콜백이 UI 를 쥐고 있는
  /// 동안(`_rewarding`)은 건드리지 않는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_viewReported || _rewarding) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.play().catchError((_) {}));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(controller.pause().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelWatchdog();
    try {
      _controller?.removeListener(_onProgress);
    } catch (_) {}
    try {
      _controller?.dispose();
    } catch (_) {}
    _exitImmersive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상위 SafeArea 영향 제거
    final media = MediaQuery.of(context);
    final pad = media.viewPadding;
    final ctrl = _controller;

    return LoadingOverlay(
      key: _loadingOverlayKey,
      child: MediaQuery(
        data: media.copyWith(
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 영상 전체화면
              Positioned.fill(
                child: ctrl == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, _, _) {
                          final size = ctrl.value.size;
                          final vw = size.width == 0 ? 16.0 : size.width;
                          final vh = size.height == 0 ? 9.0 : size.height;
                          return FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: vw,
                              height: vh,
                              child: VideoPlayer(ctrl),
                            ),
                          );
                        },
                      ),
              ),

              // 로더
              Positioned.fill(
                child: ctrl == null
                    ? _buildPulseOverlay(true)
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, _, _) {
                          final v = ctrl.value;
                          final finished = AdShortformLogic.canCloseImmediately(
                            isInitialized: v.isInitialized,
                            isBuffering: v.isBuffering,
                            position: v.position,
                            duration: v.duration,
                          );
                          final show = AdShortformLogic.shouldShowLoader(
                            loading: _loading,
                            isInitialized: v.isInitialized,
                            isBuffering: v.isBuffering,
                            isPlaying: v.isPlaying,
                            position: v.position,
                            duration: v.duration,
                            finished: finished,
                          );
                          return _buildPulseOverlay(show);
                        },
                      ),
              ),

              // 닫기 + 카운트다운 (우상단, SafeArea 패딩 수동 적용).
              // 닫기(X) 버튼은 controller 가 null(로딩/실패) 이어도 항상 렌더해
              // 무한펄스에 갇히지 않게 한다. 카운트다운 뱃지는 controller 가 있을 때만.
              Positioned(
                top: pad.top,
                right: 12,
                child: ctrl == null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_buildCloseIcon(onTap: _handleClosePressed)],
                      )
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, _, _) {
                          final v = ctrl.value;
                          final finished = AdShortformLogic.canCloseImmediately(
                            isInitialized: v.isInitialized,
                            isBuffering: v.isBuffering,
                            position: v.position,
                            duration: v.duration,
                          );
                          final remaining = v.isInitialized
                              ? (v.duration - v.position).inSeconds
                              : 0;
                          final showCountdown =
                              AdShortformLogic.shouldShowCountdown(
                                finished: finished,
                                remainingSeconds: remaining,
                              );
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showCountdown)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 1000),
                                  switchInCurve: Curves.easeOutBack,
                                  switchOutCurve: Curves.easeOutBack,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                  child: Container(
                                    key: ValueKey<int>(remaining),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.grey500,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.grey500,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$remaining',
                                        style: getTextStyle(
                                          AppTypo.caption10SB,
                                          AppColors.grey300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _buildCloseIcon(onTap: _handleClosePressed),
                            ],
                          );
                        },
                      ),
              ),

              // More 버튼 (우하단)
              Positioned(
                left: 24,
                right: 24,
                bottom: pad.bottom + 12,
                child: ctrl == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, _, _) {
                          final v = ctrl.value;
                          final finished = AdShortformLogic.canCloseImmediately(
                            isInitialized: v.isInitialized,
                            isBuffering: v.isBuffering,
                            position: v.position,
                            duration: v.duration,
                          );
                          final cta = _resolvedCtaUrl ?? widget.ctaUrl;
                          if (!AdShortformLogic.shouldShowCtaButton(
                            ctaRevealStarted: _ctaRevealStarted,
                            finished: finished,
                            ctaUrl: cta,
                          )) {
                            return const SizedBox.shrink();
                          }
                          final bool enabled =
                              AdShortformLogic.isCtaActionEnabled(
                                visible: true,
                                rewarding: _rewarding,
                              );
                          return ElevatedButton(
                            onPressed: enabled
                                ? () async {
                                    debugPrint('[internal] more pressed');
                                    // '더보기'는 광고주 랜딩으로 보내고 `ad_cta_click`
                                    // 을 남기는 것이 전부다. 추가 적립은 하지
                                    // 않기로 확정됐다(PICNIC-2377) - 적립은 재생
                                    // 종료 시 시청 보상 한 건으로만 처리된다.
                                    await _openCta(cta!);
                                    // 적립이 확정되기 전에 닫으면 컨트롤러가
                                    // dispose 되어 시청 보상까지 날아간다.
                                    if (AdShortformLogic.shouldCloseAfterCta(
                                          viewReported: _viewReported,
                                        ) &&
                                        mounted) {
                                      Navigator.of(
                                        navigatorKey.currentContext!,
                                      ).maybePop();
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: Colors.white24,
                              disabledForegroundColor: Colors.white70,
                            ),
                            child: Text(
                              AppLocalizations.of(context).ad_more_info_button,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
