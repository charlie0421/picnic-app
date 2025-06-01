import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

/// Optimized Lottie animation widget with memory management
class LottieAnimationWidget extends ConsumerStatefulWidget {
  final String asset;
  final String? package;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool reverse;
  final bool animate;
  final Duration? duration;
  final VoidCallback? onLoaded;
  final AnimationController? controller;
  final bool preloadImages;
  final LottieFrameRate? frameRate;

  const LottieAnimationWidget({
    super.key,
    required this.asset,
    this.package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.reverse = false,
    this.animate = true,
    this.duration,
    this.onLoaded,
    this.controller,
    this.preloadImages = false,
    this.frameRate,
  });

  @override
  ConsumerState<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends ConsumerState<LottieAnimationWidget>
    with TickerProviderStateMixin {
  AnimationController? _internalController;
  LottieComposition? _composition;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.controller == null && widget.animate) {
      _internalController = AnimationController(
        duration: widget.duration ?? const Duration(seconds: 2),
        vsync: this,
      );

      if (widget.repeat) {
        _internalController!.repeat(reverse: widget.reverse);
      } else {
        _internalController!.forward();
      }
    }
  }

  @override
  void didUpdateWidget(LottieAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation state changes
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
    
    // Handle repeat changes
    if (widget.repeat != oldWidget.repeat && widget.animate) {
      _restartAnimation();
    }
  }

  void _startAnimation() {
    if (_internalController != null && !_isDisposed) {
      if (widget.repeat) {
        _internalController!.repeat(reverse: widget.reverse);
      } else {
        _internalController!.forward();
      }
    }
  }

  void _stopAnimation() {
    if (_internalController != null && !_isDisposed) {
      _internalController!.stop();
    }
  }

  void _restartAnimation() {
    if (_internalController != null && !_isDisposed) {
      _internalController!.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AnimationController activeController = widget.controller ?? _internalController!;

    return Lottie.asset(
      widget.asset,
      package: widget.package,
      controller: widget.animate ? activeController : null,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: widget.repeat && widget.animate,
      reverse: widget.reverse,
      animate: widget.animate,
      frameRate: widget.frameRate ?? FrameRate.max,
      onLoaded: (composition) {
        _composition = composition;
        if (_internalController != null) {
          _internalController!.duration = composition.duration;
        }
        widget.onLoaded?.call();
      },
      options: LottieOptions(
        enableMergePaths: true,
      ),
    );
  }
}

/// Controlled Lottie animation for precise control
class ControlledLottieAnimation extends ConsumerStatefulWidget {
  final String asset;
  final String? package;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onCompleted;
  final VoidCallback? onLoaded;

  const ControlledLottieAnimation({
    super.key,
    required this.asset,
    this.package,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onCompleted,
    this.onLoaded,
  });

  @override
  ConsumerState<ControlledLottieAnimation> createState() => _ControlledLottieAnimationState();
}

class _ControlledLottieAnimationState extends ConsumerState<ControlledLottieAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        _isCompleted = true;
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Play animation once
  void play() {
    _isCompleted = false;
    _controller.reset();
    _controller.forward();
  }

  /// Play animation in reverse
  void playReverse() {
    _controller.reverse();
  }

  /// Stop animation
  void stop() {
    _controller.stop();
  }

  /// Reset animation
  void reset() {
    _controller.reset();
    _isCompleted = false;
  }

  /// Check if animation is playing
  bool get isPlaying => _controller.isAnimating;

  /// Check if animation is completed
  bool get isCompleted => _isCompleted;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.asset,
      package: widget.package,
      controller: _controller,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: false,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        widget.onLoaded?.call();
      },
    );
  }
}

/// Lottie loading indicator
class LottieLoadingIndicator extends StatelessWidget {
  final String? asset;
  final double size;
  final Color? color;

  const LottieLoadingIndicator({
    super.key,
    this.asset,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Use default loading animation if no asset provided
    final String animationAsset = asset ?? 'assets/animations/loading.json';

    return SizedBox(
      width: size,
      height: size,
      child: LottieAnimationWidget(
        asset: animationAsset,
        width: size,
        height: size,
        repeat: true,
        animate: true,
      ),
    );
  }
}

/// Lottie success indicator
class LottieSuccessIndicator extends StatefulWidget {
  final String? asset;
  final double size;
  final VoidCallback? onCompleted;
  final Duration delay;

  const LottieSuccessIndicator({
    super.key,
    this.asset,
    this.size = 100.0,
    this.onCompleted,
    this.delay = Duration.zero,
  });

  @override
  State<LottieSuccessIndicator> createState() => _LottieSuccessIndicatorState();
}

class _LottieSuccessIndicatorState extends State<LottieSuccessIndicator> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    
    // Delay animation start if specified
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            _showAnimation = true;
          });
        }
      });
    } else {
      _showAnimation = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showAnimation) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
      );
    }

    final String animationAsset = widget.asset ?? 'assets/animations/success.json';

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ControlledLottieAnimation(
        asset: animationAsset,
        width: widget.size,
        height: widget.size,
        onCompleted: widget.onCompleted,
        onLoaded: () {
          // Auto-play when loaded
          Future.microtask(() {
            final state = context.findAncestorStateOfType<_ControlledLottieAnimationState>();
            state?.play();
          });
        },
      ),
    );
  }
}

/// Preloaded Lottie animations manager
class LottiePreloader {
  static final Map<String, LottieComposition> _cache = {};
  
  /// Preload a Lottie animation
  static Future<LottieComposition> preload(String asset, {String? package}) async {
    final key = '$asset${package != null ? ':$package' : ''}';
    
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    final composition = await AssetLottie(asset, package: package).load();
    _cache[key] = composition;
    return composition;
  }
  
  /// Get preloaded composition
  static LottieComposition? getPreloaded(String asset, {String? package}) {
    final key = '$asset${package != null ? ':$package' : ''}';
    return _cache[key];
  }
  
  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }
  
  /// Clear specific animation from cache
  static void clearSpecific(String asset, {String? package}) {
    final key = '$asset${package != null ? ':$package' : ''}';
    _cache.remove(key);
  }
}

/// Lottie animation provider for Riverpod
final lottieAnimationProvider = Provider.family<LottieComposition?, String>((ref, asset) {
  return LottiePreloader.getPreloaded(asset);
});

/// Common Lottie animations used throughout the app
class CommonLottieAnimations {
  static const String loading = 'assets/animations/loading.json';
  static const String success = 'assets/animations/success.json';
  static const String error = 'assets/animations/error.json';
  static const String heart = 'assets/animations/heart.json';
  static const String confetti = 'assets/animations/confetti.json';
  static const String thumbsUp = 'assets/animations/thumbs_up.json';
  static const String wave = 'assets/animations/wave.json';
  
  /// Preload common animations
  static Future<void> preloadCommonAnimations() async {
    await Future.wait([
      LottiePreloader.preload(loading),
      LottiePreloader.preload(success),
      LottiePreloader.preload(error),
      LottiePreloader.preload(heart),
      LottiePreloader.preload(confetti),
      LottiePreloader.preload(thumbsUp),
      LottiePreloader.preload(wave),
    ]);
  }
}