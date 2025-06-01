import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/animation_service.dart';

/// 메모리 효율적이고 성능 최적화된 Lottie 애니메이션 위젯
class LottieAnimationWidget extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool reverse;
  final bool autoPlay;
  final Duration? duration;
  final VoidCallback? onCompleted;
  final AnimationController? controller;
  final bool preload;
  final bool cacheEnabled;
  final AlignmentGeometry alignment;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LottieAnimationWidget({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.reverse = false,
    this.autoPlay = true,
    this.duration,
    this.onCompleted,
    this.controller,
    this.preload = true,
    this.cacheEnabled = true,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends State<LottieAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  LottieComposition? _composition;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupController();
    _loadAnimation();
  }

  void _setupController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AnimationService().createController(
        vsync: this,
        duration: widget.duration ?? AnimationService.defaultDuration,
      );
    }

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted?.call();
      
      if (widget.repeat) {
        if (widget.reverse) {
          _controller.reverse();
        } else {
          _controller.reset();
          _controller.forward();
        }
      }
    } else if (status == AnimationStatus.dismissed && widget.reverse && widget.repeat) {
      _controller.forward();
    }
  }

  Future<void> _loadAnimation() async {
    try {
      LottieComposition? composition;

      // 캐시 확인
      if (widget.cacheEnabled) {
        composition = AnimationService().getCachedLottieAnimation(widget.assetPath);
      }

      // 캐시에 없거나 프리로드가 필요한 경우
      if (composition == null) {
        if (widget.preload) {
          composition = await AnimationService().preloadLottieAnimation(widget.assetPath);
        } else {
          composition = await AssetLottie(widget.assetPath).load();
        }
      }

      if (mounted) {
        setState(() {
          _composition = composition;
          _isLoading = false;
          _hasError = composition == null;
        });

        // 자동 재생
        if (widget.autoPlay && composition != null) {
          _controller.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      debugPrint('Failed to load Lottie animation: ${widget.assetPath} - $e');
    }
  }

  @override
  void didUpdateWidget(LottieAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.assetPath != widget.assetPath) {
      _loadAnimation();
    }
    
    if (oldWidget.autoPlay != widget.autoPlay && widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    
    // 컨트롤러가 외부에서 제공된 경우가 아니라면 정리
    if (widget.controller == null) {
      AnimationService().disposeController(_controller);
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _composition == null) {
      return _buildErrorWidget();
    }

    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Lottie(
          composition: _composition!,
          controller: _controller,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          repeat: false, // 수동으로 제어하므로 false
          reverse: false, // 수동으로 제어하므로 false
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return SizedBox(
      width: widget.width ?? 100,
      height: widget.height ?? 100,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return SizedBox(
      width: widget.width ?? 100,
      height: widget.height ?? 100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Animation Error',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 애니메이션 제어 메서드들
  void play() => _controller.forward();
  void pause() => _controller.stop();
  void stop() => _controller.reset();
  void resume() => _controller.forward();
  
  bool get isPlaying => _controller.isAnimating;
  bool get isCompleted => _controller.isCompleted;
  double get progress => _controller.value;
}

/// 미리 정의된 Lottie 애니메이션 위젯들
class PreDefinedLottieAnimations {
  static const String _basePath = 'assets/animations/';
  
  // 로딩 애니메이션
  static Widget loading({
    double size = 80,
    Color? color,
  }) {
    return LottieAnimationWidget(
      assetPath: '${_basePath}loading.json',
      width: size,
      height: size,
      repeat: true,
      placeholder: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(color ?? Colors.blue),
        ),
      ),
    );
  }

  // 성공 애니메이션
  static Widget success({
    double size = 100,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      assetPath: '${_basePath}success.json',
      width: size,
      height: size,
      repeat: false,
      onCompleted: onCompleted,
    );
  }

  // 에러 애니메이션
  static Widget error({
    double size = 100,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      assetPath: '${_basePath}error.json',
      width: size,
      height: size,
      repeat: false,
      onCompleted: onCompleted,
    );
  }

  // 하트 애니메이션
  static Widget heart({
    double size = 60,
    bool isLiked = false,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      assetPath: isLiked 
          ? '${_basePath}heart_filled.json'
          : '${_basePath}heart_empty.json',
      width: size,
      height: size,
      repeat: false,
      onCompleted: onCompleted,
    );
  }

  // 빈 상태 애니메이션
  static Widget empty({
    double size = 150,
    String? message,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LottieAnimationWidget(
          assetPath: '${_basePath}empty.json',
          width: size,
          height: size,
          repeat: true,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Lottie 애니메이션 프리로더
class LottiePreloader {
  static final List<String> _commonAnimations = [
    'assets/animations/loading.json',
    'assets/animations/success.json',
    'assets/animations/error.json',
    'assets/animations/heart_filled.json',
    'assets/animations/heart_empty.json',
    'assets/animations/empty.json',
  ];

  /// 공통 애니메이션들을 미리 로드
  static Future<void> preloadCommonAnimations() async {
    final service = AnimationService();
    
    for (final path in _commonAnimations) {
      try {
        await service.preloadLottieAnimation(path);
      } catch (e) {
        debugPrint('Failed to preload animation: $path - $e');
      }
    }
  }

  /// 특정 애니메이션들을 미리 로드
  static Future<void> preloadAnimations(List<String> assetPaths) async {
    final service = AnimationService();
    
    for (final path in assetPaths) {
      try {
        await service.preloadLottieAnimation(path);
      } catch (e) {
        debugPrint('Failed to preload animation: $path - $e');
      }
    }
  }
}