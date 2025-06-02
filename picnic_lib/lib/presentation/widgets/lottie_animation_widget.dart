import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/animation_service.dart';

/// Lottie 애니메이션 상태
enum LottieAnimationState {
  loading,
  loaded,
  playing,
  paused,
  stopped,
  error,
}

/// 메모리 효율적인 Lottie 애니메이션 위젯
class LottieAnimationWidget extends StatefulWidget {
  const LottieAnimationWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.reverse = false,
    this.animate = true,
    this.frameRate = FrameRate.max,
    this.fallbackWidget,
    this.errorWidget,
    this.loadingWidget,
    this.onLoaded,
    this.onError,
    this.controller,
    this.delegates,
    this.options,
    this.addRepaintBoundary = true,
    this.filterQuality = FilterQuality.low,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool repeat;
  final bool reverse;
  final bool animate;
  final FrameRate frameRate;
  final Widget? fallbackWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final VoidCallback? onLoaded;
  final ValueChanged<String>? onError;
  final AnimationController? controller;
  final LottieDelegates? delegates;
  final LottieOptions? options;
  final bool addRepaintBoundary;
  final FilterQuality filterQuality;

  @override
  State<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends State<LottieAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  LottieAnimationState _state = LottieAnimationState.loading;
  String? _errorMessage;
  final AnimationService _animationService = AnimationService();

  @override
  void initState() {
    super.initState();
    _initializeController();
    _preloadAnimation();
  }

  void _initializeController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = _animationService.createController(
        vsync: this,
        tag: 'lottie_${widget.assetPath}',
      );
    }

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (!mounted) return;

    switch (status) {
      case AnimationStatus.completed:
        if (widget.repeat) {
          if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.repeat();
          }
        } else {
          setState(() {
            _state = LottieAnimationState.stopped;
          });
        }
        break;
      case AnimationStatus.dismissed:
        if (widget.repeat && widget.reverse) {
          _controller.forward();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _preloadAnimation() async {
    try {
      setState(() {
        _state = LottieAnimationState.loading;
      });

      // 프리로드된 애니메이션 확인
      final preloaded =
          _animationService.getPreloadedLottieAnimation(widget.assetPath);
      if (preloaded != null) {
        _onAnimationLoaded();
        return;
      }

      // 새로 로드
      await _animationService.preloadLottieAnimation(
          widget.assetPath, widget.assetPath);
      _onAnimationLoaded();
    } catch (e) {
      _onAnimationError(e.toString());
    }
  }

  void _onAnimationLoaded() {
    if (!mounted) return;

    setState(() {
      _state = LottieAnimationState.loaded;
    });

    widget.onLoaded?.call();

    if (widget.animate) {
      play();
    }
  }

  void _onAnimationError(String error) {
    if (!mounted) return;

    setState(() {
      _state = LottieAnimationState.error;
      _errorMessage = error;
    });

    widget.onError?.call(error);
  }

  /// 애니메이션 재생
  void play() {
    if (_state == LottieAnimationState.loaded ||
        _state == LottieAnimationState.paused ||
        _state == LottieAnimationState.stopped) {
      setState(() {
        _state = LottieAnimationState.playing;
      });

      if (widget.reverse) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  /// 애니메이션 일시정지
  void pause() {
    if (_state == LottieAnimationState.playing) {
      setState(() {
        _state = LottieAnimationState.paused;
      });
      _controller.stop();
    }
  }

  /// 애니메이션 정지
  void stop() {
    setState(() {
      _state = LottieAnimationState.stopped;
    });
    _controller.reset();
  }

  /// 애니메이션 재개
  void resume() {
    if (_state == LottieAnimationState.paused) {
      play();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case LottieAnimationState.loading:
        return _buildLoadingWidget();

      case LottieAnimationState.error:
        return _buildErrorWidget();

      case LottieAnimationState.loaded:
      case LottieAnimationState.playing:
      case LottieAnimationState.paused:
      case LottieAnimationState.stopped:
        return _buildLottieWidget();
    }
  }

  Widget _buildLoadingWidget() {
    return widget.loadingWidget ??
        SizedBox(
          width: widget.width ?? 50,
          height: widget.height ?? 50,
          child: const CircularProgressIndicator(),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        widget.fallbackWidget ??
        SizedBox(
          width: widget.width ?? 50,
          height: widget.height ?? 50,
          child: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: (widget.width ?? 50) * 0.6,
          ),
        );
  }

  Widget _buildLottieWidget() {
    Widget lottieWidget = Lottie.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      controller: _controller,
      repeat: false, // 컨트롤러에서 직접 관리
      reverse: false, // 컨트롤러에서 직접 관리
      animate: _state == LottieAnimationState.playing,
      frameRate: widget.frameRate,
      delegates: widget.delegates,
      options: widget.options,
      errorBuilder: (context, error, stackTrace) {
        _onAnimationError(error.toString());
        return _buildErrorWidget();
      },
      filterQuality: widget.filterQuality,
    );

    if (widget.addRepaintBoundary) {
      lottieWidget = RepaintBoundary(child: lottieWidget);
    }

    return lottieWidget;
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    if (widget.controller == null) {
      _animationService.disposeController('lottie_${widget.assetPath}');
    }
    super.dispose();
  }
}

/// 사전 정의된 Lottie 애니메이션들
class PreDefinedLottieAnimations {
  static const String loadingAsset = 'assets/animations/loading.json';
  static const String successAsset = 'assets/animations/success.json';
  static const String errorAsset = 'assets/animations/error.json';
  static const String heartAsset = 'assets/animations/heart.json';
  static const String thumbsUpAsset = 'assets/animations/thumbs_up.json';
  static const String confettiAsset = 'assets/animations/confetti.json';
  static const String emptyAsset = 'assets/animations/empty.json';
  static const String noInternetAsset = 'assets/animations/no_internet.json';

  /// 로딩 애니메이션
  static Widget loading({
    double size = 80,
    Color? color,
  }) =>
      LottieAnimationWidget(
        assetPath: PreDefinedLottieAnimations.loadingAsset,
        width: size,
        height: size,
        repeat: true,
        delegates: color != null
            ? LottieDelegates(
                values: [
                  ValueDelegate.color(
                    const ['**'],
                    value: color,
                  ),
                ],
              )
            : null,
      );

  /// 성공 애니메이션
  static Widget success({
    double size = 100,
    VoidCallback? onCompleted,
  }) =>
      LottieAnimationWidget(
        assetPath: PreDefinedLottieAnimations.successAsset,
        width: size,
        height: size,
        repeat: false,
        onLoaded: onCompleted,
      );

  /// 에러 애니메이션
  static Widget error({
    double size = 100,
    Color color = Colors.red,
  }) =>
      LottieAnimationWidget(
        assetPath: PreDefinedLottieAnimations.errorAsset,
        width: size,
        height: size,
        repeat: false,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              const ['**'],
              value: color,
            ),
          ],
        ),
      );

  /// 좋아요 애니메이션
  static Widget heart({
    double size = 60,
    Color color = Colors.red,
    bool animate = true,
  }) =>
      LottieAnimationWidget(
        assetPath: PreDefinedLottieAnimations.heartAsset,
        width: size,
        height: size,
        repeat: false,
        animate: animate,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color(
              const ['**'],
              value: color,
            ),
          ],
        ),
      );

  /// 빈 상태 애니메이션
  static Widget empty({
    double size = 200,
    String? text,
    TextStyle? textStyle,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LottieAnimationWidget(
            assetPath: PreDefinedLottieAnimations.emptyAsset,
            width: size,
            height: size,
            repeat: true,
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text,
              style: textStyle ??
                  const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
}

/// Lottie 애니메이션 프리로더
class LottiePreloader {
  static final Map<String, Future<LottieComposition>> _loadingFutures = {};
  static final Set<String> _preloadedAnimations = {};

  /// 애니메이션 배치 프리로드
  static Future<void> preloadAnimations(List<String> assetPaths) async {
    final futures = assetPaths.map((path) => preloadAnimation(path));
    await Future.wait(futures);
  }

  /// 단일 애니메이션 프리로드
  static Future<LottieComposition> preloadAnimation(String assetPath) async {
    if (_preloadedAnimations.contains(assetPath)) {
      return AnimationService().getPreloadedLottieAnimation(assetPath)!;
    }

    if (_loadingFutures.containsKey(assetPath)) {
      return _loadingFutures[assetPath]!;
    }

    final future = AssetLottie(assetPath).load();
    _loadingFutures[assetPath] = future;

    try {
      final composition = await future;
      await AnimationService().preloadLottieAnimation(assetPath, assetPath);
      _preloadedAnimations.add(assetPath);
      _loadingFutures.remove(assetPath);
      return composition;
    } catch (e) {
      _loadingFutures.remove(assetPath);
      rethrow;
    }
  }

  /// 사전 정의된 애니메이션들 프리로드
  static Future<void> preloadPredefinedAnimations() async {
    await preloadAnimations([
      PreDefinedLottieAnimations.loadingAsset,
      PreDefinedLottieAnimations.successAsset,
      PreDefinedLottieAnimations.errorAsset,
      PreDefinedLottieAnimations.heartAsset,
      PreDefinedLottieAnimations.emptyAsset,
    ]);
  }

  /// 프리로드 상태 확인
  static bool isPreloaded(String assetPath) {
    return _preloadedAnimations.contains(assetPath);
  }

  /// 프리로드된 애니메이션들 정리
  static void clearPreloadedAnimations() {
    _preloadedAnimations.clear();
    _loadingFutures.clear();
  }

  /// 프리로드 진행 상황 스트림
  static Stream<double> preloadProgressStream(List<String> assetPaths) async* {
    var completed = 0;
    final total = assetPaths.length;

    yield 0.0;

    for (final path in assetPaths) {
      try {
        await preloadAnimation(path);
        completed++;
        yield completed / total;
      } catch (e) {
        debugPrint('Failed to preload animation $path: $e');
        completed++;
        yield completed / total;
      }
    }
  }
}

/// Lottie 애니메이션 컨트롤러
class LottieAnimationController {
  final AnimationController _controller;
  final String assetPath;
  LottieAnimationState _state = LottieAnimationState.stopped;

  LottieAnimationController._(this._controller, this.assetPath);

  static LottieAnimationController create({
    required TickerProvider vsync,
    required String assetPath,
    Duration duration = const Duration(seconds: 2),
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );
    return LottieAnimationController._(controller, assetPath);
  }

  /// 애니메이션 재생
  void play() {
    _state = LottieAnimationState.playing;
    _controller.forward();
  }

  /// 애니메이션 일시정지
  void pause() {
    _state = LottieAnimationState.paused;
    _controller.stop();
  }

  /// 애니메이션 정지
  void stop() {
    _state = LottieAnimationState.stopped;
    _controller.reset();
  }

  /// 애니메이션 재개
  void resume() {
    if (_state == LottieAnimationState.paused) {
      play();
    }
  }

  /// 애니메이션 반복
  void repeat({bool reverse = false}) {
    _controller.repeat(reverse: reverse);
  }

  /// 특정 프레임으로 이동
  void seekToFrame(double frame) {
    _controller.value = frame.clamp(0.0, 1.0);
  }

  /// 현재 상태
  LottieAnimationState get state => _state;

  /// 애니메이션 진행률
  double get progress => _controller.value;

  /// 애니메이션 컨트롤러
  AnimationController get controller => _controller;

  /// 리소스 정리
  void dispose() {
    _controller.dispose();
  }
}
