import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:lottie/lottie.dart';

/// 애니메이션 성능 통계
class AnimationStats {
  int activeControllers = 0;
  int disposedControllers = 0;
  int preloadedAnimations = 0;
  double averageFrameTime = 0.0;

  Map<String, dynamic> toJson() => {
        'activeControllers': activeControllers,
        'disposedControllers': disposedControllers,
        'preloadedAnimations': preloadedAnimations,
        'averageFrameTime': averageFrameTime,
      };
}

/// 애니메이션 서비스 - 메모리 효율적인 애니메이션 관리
class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  final Map<String, AnimationController> _controllers = {};
  final Map<String, LottieComposition> _preloadedLottieAnimations = {};
  final Set<String> _disposedControllers = {};
  final AnimationStats _stats = AnimationStats();

  Timer? _statsUpdateTimer;
  bool _isInitialized = false;

  /// 서비스 초기화
  void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;
    _startStatsTracking();
  }

  /// 통계 추적 시작
  void _startStatsTracking() {
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateStats();
    });
  }

  /// 통계 업데이트
  void _updateStats() {
    _stats.activeControllers = _controllers.length;
    _stats.disposedControllers = _disposedControllers.length;
    _stats.preloadedAnimations = _preloadedLottieAnimations.length;
  }

  /// 애니메이션 컨트롤러 생성
  AnimationController createController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    String? tag,
    Duration? reverseDuration,
    double? value,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    final controllerId =
        tag ?? 'controller_${DateTime.now().millisecondsSinceEpoch}';

    // 기존 컨트롤러가 있다면 정리
    if (_controllers.containsKey(controllerId)) {
      disposeController(controllerId);
    }

    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: vsync,
    );

    _controllers[controllerId] = controller;
    return controller;
  }

  /// 컨트롤러 해제
  void disposeController(String controllerId) {
    final controller = _controllers.remove(controllerId);
    if (controller != null) {
      controller.dispose();
      _disposedControllers.add(controllerId);
    }
  }

  /// 모든 컨트롤러 해제
  void disposeAllControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _disposedControllers.clear();
  }

  /// 컨트롤러 가져오기
  AnimationController? getController(String controllerId) {
    return _controllers[controllerId];
  }

  /// 모든 애니메이션 일시정지
  void pauseAllAnimations() {
    for (final controller in _controllers.values) {
      if (controller.isAnimating) {
        controller.stop();
      }
    }
  }

  /// 모든 애니메이션 재개
  void resumeAllAnimations() {
    for (final controller in _controllers.values) {
      if (!controller.isAnimating &&
          controller.status != AnimationStatus.completed) {
        controller.forward();
      }
    }
  }

  /// Lottie 애니메이션 프리로드
  Future<void> preloadLottieAnimation(String path, String key) async {
    try {
      final composition = await AssetLottie(path).load();
      _preloadedLottieAnimations[key] = composition;
    } catch (e) {
      debugPrint('Failed to preload Lottie animation $path: $e');
    }
  }

  /// 프리로드된 Lottie 애니메이션 가져오기
  LottieComposition? getPreloadedLottieAnimation(String key) {
    return _preloadedLottieAnimations[key];
  }

  /// 일반적인 애니메이션 생성 도우미들

  /// 슬라이드 애니메이션
  Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 페이드 애니메이션
  Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 스케일 애니메이션
  Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 회전 애니메이션
  Animation<double> createRotationAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.linear,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 크기 애니메이션
  Animation<Size> createSizeAnimation(
    AnimationController controller, {
    required Size begin,
    required Size end,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<Size>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 색상 애니메이션
  Animation<Color?> createColorAnimation(
    AnimationController controller, {
    required Color begin,
    required Color end,
    Curve curve = Curves.easeInOut,
  }) {
    return ColorTween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 공통 애니메이션 지속시간들
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration slowDuration = Duration(milliseconds: 600);
  static const Duration veryFastDuration = Duration(milliseconds: 100);
  static const Duration verySlowDuration = Duration(milliseconds: 1000);

  /// 공통 애니메이션 커브들
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// 성능 통계 가져오기
  AnimationStats get stats => _stats;

  /// 메모리 정리
  void cleanup() {
    _statsUpdateTimer?.cancel();
    disposeAllControllers();
    _preloadedLottieAnimations.clear();
    _disposedControllers.clear();
    _isInitialized = false;
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    debugPrint('=== Animation Service Debug Info ===');
    debugPrint('Active Controllers: ${_controllers.length}');
    debugPrint('Disposed Controllers: ${_disposedControllers.length}');
    debugPrint('Preloaded Lottie: ${_preloadedLottieAnimations.length}');
    debugPrint('Controller IDs: ${_controllers.keys.toList()}');
    debugPrint('===================================');
  }
}

/// 애니메이션 믹스인 - 위젯에서 쉽게 사용할 수 있도록
mixin AnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  final AnimationService _animationService = AnimationService();
  final List<String> _controllerIds = [];

  /// 애니메이션 컨트롤러 생성 (자동 관리)
  AnimationController createManagedController({
    Duration duration = AnimationService.defaultDuration,
    String? tag,
    Duration? reverseDuration,
    double? value,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    final controllerId = tag ?? 'widget_${hashCode}_${_controllerIds.length}';
    final controller = _animationService.createController(
      vsync: this,
      duration: duration,
      tag: controllerId,
      reverseDuration: reverseDuration,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );

    _controllerIds.add(controllerId);
    return controller;
  }

  @override
  void dispose() {
    // 관리되는 모든 컨트롤러 정리
    for (final controllerId in _controllerIds) {
      _animationService.disposeController(controllerId);
    }
    _controllerIds.clear();
    super.dispose();
  }
}

/// 애니메이션 유틸리티 함수들
class AnimationUtils {
  /// 스프링 애니메이션 시뮬레이션
  static SpringSimulation createSpringSimulation({
    required double mass,
    required double stiffness,
    required double damping,
    required double velocity,
    required double target,
  }) {
    final spring = SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
    return SpringSimulation(spring, 0.0, target, velocity);
  }

  /// 바운스 애니메이션
  static Animation<double> createBounceAnimation(
      AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.bounceOut,
    ));
  }

  /// 진동 애니메이션
  static Animation<double> createShakeAnimation(
    AnimationController controller, {
    double amplitude = 10.0,
    int frequency = 3,
  }) {
    return Tween<double>(
      begin: -amplitude,
      end: amplitude,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        0.0,
        1.0,
        curve: Curves.bounceOut,
      ),
    ));
  }

  /// 맥박 애니메이션 (반복)
  static void startPulseAnimation(
    AnimationController controller, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    controller.duration = duration;
    controller.repeat(reverse: true);
  }

  /// 애니메이션 지연 실행
  static void delayedAnimation(
    VoidCallback animation, {
    Duration delay = Duration.zero,
  }) {
    if (delay == Duration.zero) {
      animation();
    } else {
      Timer(delay, animation);
    }
  }
}
