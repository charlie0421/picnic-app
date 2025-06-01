import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

/// 중앙화된 애니메이션 관리 서비스
class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  // 캐시된 Lottie 애니메이션
  final Map<String, LottieComposition> _lottieCache = {};
  
  // 애니메이션 컨트롤러 풀
  final Set<AnimationController> _activeControllers = {};

  /// 공통 애니메이션 정의
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 600);
  static const Duration fastDuration = Duration(milliseconds: 150);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.easeOut;

  /// Slide 애니메이션 생성
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = defaultCurve,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Fade 애니메이션 생성
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Scale 애니메이션 생성
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Rotation 애니메이션 생성
  static Animation<double> createRotationAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 메모리 효율적 애니메이션 컨트롤러 생성
  AnimationController createController({
    required TickerProvider vsync,
    Duration duration = defaultDuration,
    double? value,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );
    
    _activeControllers.add(controller);
    return controller;
  }

  /// 컨트롤러 정리
  void disposeController(AnimationController controller) {
    _activeControllers.remove(controller);
    controller.dispose();
  }

  /// Lottie 애니메이션 프리로딩
  Future<LottieComposition?> preloadLottieAnimation(String assetPath) async {
    if (_lottieCache.containsKey(assetPath)) {
      return _lottieCache[assetPath];
    }

    try {
      final composition = await AssetLottie(assetPath).load();
      _lottieCache[assetPath] = composition;
      return composition;
    } catch (e) {
      debugPrint('Failed to preload Lottie animation: $assetPath - $e');
      return null;
    }
  }

  /// 캐시된 Lottie 애니메이션 가져오기
  LottieComposition? getCachedLottieAnimation(String assetPath) {
    return _lottieCache[assetPath];
  }

  /// 메모리 정리
  void dispose() {
    for (final controller in _activeControllers) {
      controller.dispose();
    }
    _activeControllers.clear();
    _lottieCache.clear();
  }

  /// 모든 활성 애니메이션 일시정지
  void pauseAllAnimations() {
    for (final controller in _activeControllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
    }
  }

  /// 모든 활성 애니메이션 재개
  void resumeAllAnimations() {
    for (final controller in _activeControllers) {
      if (!controller.isAnimating && controller.status != AnimationStatus.completed) {
        controller.forward();
      }
    }
  }

  /// 성능 통계
  Map<String, dynamic> getPerformanceStats() {
    return {
      'activeControllers': _activeControllers.length,
      'cachedLottieAnimations': _lottieCache.length,
      'memoryUsage': '${(_lottieCache.length * 0.5).toStringAsFixed(1)}MB (estimated)',
    };
  }
}

/// Provider for animation service
final animationServiceProvider = Provider<AnimationService>((ref) {
  final service = AnimationService();
  
  // Dispose all controllers when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final bool autoStart;

  const AnimationConfig({
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.curve = Curves.easeInOut,
    this.autoStart = false,
  });

  static const fast = AnimationConfig(
    duration: Duration(milliseconds: 150),
  );

  static const normal = AnimationConfig(
    duration: Duration(milliseconds: 300),
  );

  static const slow = AnimationConfig(
    duration: Duration(milliseconds: 500),
  );

  static const bounce = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.elasticOut,
  );

  static const slide = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.easeOutCubic,
  );
}