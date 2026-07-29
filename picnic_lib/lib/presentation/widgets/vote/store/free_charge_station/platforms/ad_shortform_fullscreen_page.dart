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
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';

/// Pure logic helpers for AdShortformFullscreenPage, testable without widget tree.
@visibleForTesting
class AdShortformLogic {
  static bool shouldUseLegacyBonusUx(InternalShortformViewResponse response) =>
      response.reward == null && response.rewardAdded > 0;

  static bool shouldSuppressLocalWalletUx(
    InternalShortformViewResponse response,
  ) => response.reward != null;

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

class AdShortformFullscreenPage extends ConsumerStatefulWidget {
  final String videoUrl;
  final String? ctaUrl;
  final Future<InternalShortformViewResponse> Function() onViewComplete;
  final Future<void> Function() onMore;

  /// Loads the ad at route-entry time.
  ///
  /// [blocked] signals that an anti-abuse rate-limit already popped the route
  /// and is showing its own dialog; in that case the page must stay silent
  /// (no duplicate error dialog). Any other empty videoUrl is treated as a
  /// load failure and surfaces an error instead of pulsing forever.
  final Future<({String videoUrl, String? ctaUrl, bool blocked})> Function()?
  loadAd;

  const AdShortformFullscreenPage({
    super.key,
    required this.videoUrl,
    required this.onViewComplete,
    required this.onMore,
    this.ctaUrl,
    this.loadAd,
  });

  @override
  ConsumerState<AdShortformFullscreenPage> createState() =>
      _AdShortformFullscreenPageState();
}

class _AdShortformFullscreenPageState
    extends ConsumerState<AdShortformFullscreenPage> {
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

  /// App-level Riverpod container, captured while this route is mounted, so a
  /// reward that settles after the user already closed the ad can still update
  /// the wallet summary (cf. `ContainerWalletSummaryApplier` in the purchase
  /// settlement path - `ConsumerState.ref` throws once unmounted).
  late final ProviderContainer _rewardContainer;

  @override
  void initState() {
    super.initState();
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
    if (AdShortformLogic.shouldUseLegacyBonusUx(response)) {
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

  Widget _buildPulseOverlay(bool visible) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1.0 : 0.0,
        child: const Center(child: MediumPulseLoadingIndicator()),
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

  Future<void> _openCta(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
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
                                    // 적립은 재생 종료 시 자동 처리됨
                                    await _openCta(cta!);
                                    if (mounted) {
                                      Navigator.of(
                                        navigatorKey.currentContext!,
                                      ).maybePop();
                                    }
                                    // widget.onMore()는 호출하지 않음 (More 보상 제거)
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
