import 'package:flutter/foundation.dart';
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

/// Pure logic helpers for AdShortformFullscreenPage, testable without widget tree.
@visibleForTesting
class AdShortformLogic {
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
}

class AdShortformFullscreenPage extends StatefulWidget {
  final String videoUrl;
  final String? ctaUrl;
  final Future<void> Function() onViewComplete;
  final Future<void> Function() onMore;
  final Future<({String videoUrl, String? ctaUrl})> Function()? loadAd;

  const AdShortformFullscreenPage({
    super.key,
    required this.videoUrl,
    required this.onViewComplete,
    required this.onMore,
    this.ctaUrl,
    this.loadAd,
  });

  @override
  State<AdShortformFullscreenPage> createState() =>
      _AdShortformFullscreenPageState();
}

class _AdShortformFullscreenPageState extends State<AdShortformFullscreenPage> {
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

  @override
  void initState() {
    super.initState();
    _enterImmersive();
    _initializeFlow();
  }

  Future<void> _enterImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initializeFlow() async {
    try {
      if (widget.loadAd != null) {
        final result = await widget.loadAd!();
        _resolvedVideoUrl = result.videoUrl;
        _resolvedCtaUrl = result.ctaUrl;
      } else {
        _resolvedVideoUrl = widget.videoUrl;
        _resolvedCtaUrl = widget.ctaUrl;
      }
      // anti-abuse rate-limit 등으로 loadAd 가 빈 url 을 sentinel 로 반환한 경우, page
      // 가 다음 frame 에 pop 되더라도 그 frame 동안 _initPlayer('') 가 실행되며 충돌.
      // 빈 url 이면 init 시도 자체를 skip — pop 는 platform 측에서 이미 예약됨.
      if ((_resolvedVideoUrl ?? '').isEmpty) return;
      if (!mounted) return;
      try {
        await _initPlayer(_resolvedVideoUrl!);
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
      await ctrl.initialize();
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
    if (AdShortformLogic.isPlaybackComplete(
          isInitialized: value.isInitialized,
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
    var success = false;
    try {
      await widget.onViewComplete();
      success = true;
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
    if (success && mounted) {
      showSimpleDialog(
        // 국제화된 성공 메시지 사용, 버튼 없음
        content: AppLocalizations.of(context).ad_reward_success_message,
      );
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

  Future<void> _handleClosePressed() async {
    final v = _controller?.value;
    final canClose = v != null &&
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

              // 닫기 + 카운트다운 (우상단, SafeArea 패딩 수동 적용)
              Positioned(
                top: pad.top - 12,
                right: 24,
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
                          final remaining = v.isInitialized
                              ? (v.duration - v.position).inSeconds
                              : 0;
                          final showCountdown =
                              AdShortformLogic.shouldShowCountdown(
                            finished: finished,
                            remainingSeconds: remaining,
                          );
                          final canCloseNow =
                              AdShortformLogic.isCtaButtonEnabled(
                            finished: finished,
                            viewReported: _viewReported,
                            rewarding: _rewarding,
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
                              GestureDetector(
                                onTap: finished
                                    ? (canCloseNow ? _handleClosePressed : null)
                                    : _handleClosePressed,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey300,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.grey500,
                                    size: 18,
                                  ),
                                ),
                              ),
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
                              AdShortformLogic.isCtaButtonEnabled(
                            finished: finished,
                            viewReported: _viewReported,
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
