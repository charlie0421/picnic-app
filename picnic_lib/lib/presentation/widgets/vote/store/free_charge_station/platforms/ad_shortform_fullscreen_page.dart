import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay.dart';

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
      if (!mounted) return;
      await _initPlayer(_resolvedVideoUrl!);
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _initPlayer(String videoUrl) async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await ctrl.initialize();
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
    await ctrl.play();
  }

  void _onProgress() {
    final v = _controller;
    if (v == null) return;
    final value = v.value;
    // Mark countdown start (<= 5s remaining) to keep More button visible without flicker
    if (!_ctaRevealStarted && value.isInitialized) {
      final remaining = value.duration - value.position;
      if (!remaining.isNegative && remaining <= const Duration(seconds: 5)) {
        setState(() {
          _ctaRevealStarted = true;
        });
      }
    }
    // 재생 완료 시 자동 적립 호출 제거 (닫기/More 시점에서만 적립)
  }

  Future<void> _handleClosePressed() async {
    final v = _controller?.value;
    final canClose =
        v != null &&
        v.isInitialized &&
        !v.isBuffering &&
        v.position >= v.duration;
    if (canClose) {
      debugPrint('[internal] close pressed (finished=true)');
      // 재생 종료 후 닫기: 기본 보상 보장 + 성공 안내 후 닫기
      if (!_viewReported) {
        _viewReported = true;
        debugPrint('[internal] ensuring view reward before close');
        try {
          _loadingOverlayKey.currentState?.show();
          await widget.onViewComplete();
          showSimpleDialog(
            title: '',
            content: '적립 되었습니다.',
            onCancel: () {
              final ctx = navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).maybePop();
            },
            onOk: () {
              final ctx = navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).maybePop();
            },
          );
          return;
        } catch (_) {
          // 실패 시에는 안내 없이 닫기
          debugPrint('[internal] view reward failed on close; closing route');
        } finally {
          _loadingOverlayKey.currentState?.hide();
        }
      }
      debugPrint('[internal] closing route');
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    try {
      await _controller?.pause();
    } catch (_) {}
    debugPrint('[internal] close pressed (confirm dialog)');
    final i18n = AppLocalizations.of(context);
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
                        builder: (_, __, ___) {
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
                child: (ctrl == null || _loading)
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, __, ___) {
                          final v = ctrl.value;
                          final isFinished =
                              v.isInitialized &&
                              v.position >=
                                  (v.duration -
                                      const Duration(milliseconds: 150));
                          final isPlayingSmooth =
                              v.isInitialized && v.isPlaying && !v.isBuffering;
                          final showLoader =
                              !v.isInitialized ||
                              (v.isBuffering && !isFinished) ||
                              (!isPlayingSmooth && v.position == Duration.zero);
                          return IgnorePointer(
                            ignoring: true,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: showLoader ? 1.0 : 0.0,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 닫기 + 카운트다운 (우상단, SafeArea 패딩 수동 적용)
              Positioned(
                top: pad.top,
                right: 12,
                child: ctrl == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, __, ___) {
                          final v = ctrl.value;
                          final canClose =
                              v.isInitialized &&
                              !v.isBuffering &&
                              v.position >= v.duration;
                          final remaining = v.isInitialized
                              ? (v.duration - v.position).inSeconds
                              : 0;
                          final showCountdown =
                              !canClose && remaining > 0 && remaining <= 5;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showCountdown)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 420),
                                  switchInCurve: Curves.easeOutBack,
                                  switchOutCurve: Curves.easeOutBack,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                            begin: 0.8,
                                            end: 1.0,
                                          ).animate(anim),
                                          child: child,
                                        ),
                                      ),
                                  child: Container(
                                    key: ValueKey<int>(remaining),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '$remaining',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _handleClosePressed,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // More 버튼 (우하단)
              Positioned(
                right: 24,
                bottom: pad.bottom + 24,
                child: ctrl == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder(
                        valueListenable: ctrl,
                        builder: (_, __, ___) {
                          final v = ctrl.value;
                          final finished =
                              v.isInitialized &&
                              !v.isBuffering &&
                              v.position >= v.duration;
                          final cta = _resolvedCtaUrl ?? widget.ctaUrl;
                          if (cta == null || cta.isEmpty)
                            return const SizedBox.shrink();
                          // 노출 조건: 카운트다운이 한 번 시작되었거나(플래그) 종료 후
                          if (!(_ctaRevealStarted || finished)) {
                            return const SizedBox.shrink();
                          }
                          final bool enabled = finished;
                          return ElevatedButton(
                            onPressed: enabled
                                ? () async {
                                    debugPrint('[internal] more pressed');
                                    // 기본 보상만 보장 (More 보상 제거), 이후 URL 오픈
                                    if (!_viewReported) {
                                      _viewReported = true;
                                      debugPrint(
                                        '[internal] ensuring view reward before more',
                                      );
                                      _loadingOverlayKey.currentState?.show();
                                      try {
                                        await widget.onViewComplete();
                                      } finally {
                                        _loadingOverlayKey.currentState?.hide();
                                      }
                                    }
                                    await _openCta(cta);
                                    if (mounted)
                                      Navigator.of(context).maybePop();
                                    // widget.onMore()는 호출하지 않음 (More 보상 제거)
                                  }
                                : null,
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    if (states.contains(MaterialState.disabled))
                                      return Colors.white24;
                                    return null; // default
                                  }),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    if (states.contains(MaterialState.disabled))
                                      return Colors.white70;
                                    return null; // default
                                  }),
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
