import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 로딩 오버레이의 애니메이션 초기화, 조합, 성능 모니터링을 담당하는 mixin.
///
/// [LoadingOverlayWithIcon]의 State 클래스에서 사용됩니다.
/// [TickerProviderStateMixin]이 적용된 [State]에서만 사용 가능합니다.
mixin LoadingOverlayAnimationsMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  // ── Animation controllers ──

  /// 오버레이 페이드 애니메이션 컨트롤러
  late AnimationController overlayFadeController;

  /// 오버레이 페이드 애니메이션
  late Animation<double> overlayFadeAnimation;

  /// 회전 애니메이션 컨트롤러
  AnimationController? rotationController;

  /// 회전 애니메이션
  Animation<double>? rotationAnimation;

  /// 스케일 애니메이션 컨트롤러
  AnimationController? scaleController;

  /// 스케일 애니메이션
  Animation<double>? scaleAnimation;

  /// 아이콘 페이드 애니메이션 컨트롤러
  AnimationController? iconFadeController;

  /// 아이콘 페이드 애니메이션
  Animation<double>? iconFadeAnimation;

  // ── Performance monitoring fields ──

  /// 성능 측정을 위한 프레임 카운트
  int frameCount = 0;

  /// 마지막 프레임 시간
  DateTime? lastFrameTime;

  /// 평균 FPS
  double averageFps = 0.0;

  // ── Animation initialization ──

  /// 모든 애니메이션 컨트롤러를 초기화합니다.
  ///
  /// [enableRotation], [enableScale], [enableFade]에 따라 필요한 컨트롤러만
  /// 지연 초기화하여 메모리를 절약합니다.
  void initializeAnimations({
    required bool enableRotation,
    required bool enableScale,
    required bool enableFade,
    required Duration rotationDuration,
    required bool clockwise,
    required Duration scaleDuration,
    required double minScale,
    required double maxScale,
    required Duration fadeDuration,
  }) {
    // 오버레이 페이드 애니메이션 컨트롤러 초기화
    overlayFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 오버레이 페이드 애니메이션 설정
    overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: overlayFadeController,
      curve: Curves.easeInOut,
    ));

    // 필요한 경우에만 애니메이션 컨트롤러 초기화 (메모리 최적화)
    if (enableRotation) {
      initializeRotationAnimation(
        duration: rotationDuration,
        clockwise: clockwise,
      );
    }

    if (enableScale) {
      initializeScaleAnimation(
        duration: scaleDuration,
        minScale: minScale,
        maxScale: maxScale,
      );
    }

    if (enableFade) {
      initializeIconFadeAnimation(duration: fadeDuration);
    }
  }

  /// 회전 애니메이션 초기화
  void initializeRotationAnimation({
    required Duration duration,
    required bool clockwise,
  }) {
    rotationController = AnimationController(
      duration: duration,
      vsync: this,
    );

    rotationAnimation = Tween<double>(
      begin: 0.0,
      end: clockwise ? 1.0 : -1.0,
    ).animate(CurvedAnimation(
      parent: rotationController!,
      curve: Curves.linear,
    ));
  }

  /// 스케일 애니메이션 초기화
  void initializeScaleAnimation({
    required Duration duration,
    required double minScale,
    required double maxScale,
  }) {
    scaleController = AnimationController(
      duration: duration,
      vsync: this,
    );

    scaleAnimation = Tween<double>(
      begin: minScale,
      end: maxScale,
    ).animate(CurvedAnimation(
      parent: scaleController!,
      curve: Curves.easeInOut,
    ));
  }

  /// 아이콘 페이드 애니메이션 초기화
  void initializeIconFadeAnimation({required Duration duration}) {
    iconFadeController = AnimationController(
      duration: duration,
      vsync: this,
    );

    iconFadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: iconFadeController!,
      curve: Curves.easeInOut,
    ));
  }

  /// 모든 애니메이션 컨트롤러를 정리합니다.
  void disposeAnimations() {
    overlayFadeController.dispose();
    rotationController?.dispose();
    scaleController?.dispose();
    iconFadeController?.dispose();
  }

  // ── Combined animation builder ──

  /// 모든 활성 애니메이션을 효율적으로 조합하여 위젯에 적용합니다.
  Widget buildCombinedAnimations(
    Widget child, {
    required bool enablePerformanceOptimization,
    required bool enableRotation,
    required bool enableScale,
    required bool enableFade,
  }) {
    // 단일 AnimatedBuilder로 모든 애니메이션 처리 (성능 최적화)
    if (enablePerformanceOptimization &&
        enableRotation &&
        enableScale &&
        enableFade &&
        rotationAnimation != null &&
        scaleAnimation != null &&
        iconFadeAnimation != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          rotationAnimation!,
          scaleAnimation!,
          iconFadeAnimation!,
        ]),
        builder: (context, _) {
          return Transform.rotate(
            angle: rotationAnimation!.value * 2 * 3.14159,
            child: Transform.scale(
              scale: scaleAnimation!.value,
              child: Opacity(
                opacity: iconFadeAnimation!.value,
                child: child,
              ),
            ),
          );
        },
      );
    }

    // 개별 애니메이션 적용 (호환성 모드)
    Widget result = child;

    // 스케일 애니메이션 적용
    if (enableScale && scaleAnimation != null) {
      result = AnimatedBuilder(
        animation: scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation!.value,
            child: child,
          );
        },
        child: result,
      );
    }

    // 회전 애니메이션 적용
    if (enableRotation && rotationAnimation != null) {
      result = RotationTransition(
        turns: rotationAnimation!,
        child: result,
      );
    }

    // 아이콘 페이드 애니메이션 적용
    if (enableFade && iconFadeAnimation != null) {
      result = AnimatedBuilder(
        animation: iconFadeAnimation!,
        builder: (context, child) {
          return Opacity(
            opacity: iconFadeAnimation!.value,
            child: child,
          );
        },
        child: result,
      );
    }

    return result;
  }

  // ── Performance monitoring ──

  /// 성능 모니터링을 시작합니다 (디버그 모드에서만 동작).
  ///
  /// [shouldContinue]는 매 프레임마다 호출되며, true를 반환하면
  /// 모니터링을 계속합니다.
  void startPerformanceMonitoring(bool Function() shouldContinue) {
    if (!kDebugMode) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      measureFrameRate(shouldContinue);
    });
  }

  /// 프레임율을 측정합니다.
  ///
  /// [shouldContinue]가 true를 반환하는 동안 반복적으로 프레임을 측정합니다.
  void measureFrameRate(bool Function() shouldContinue) {
    if (!mounted || !kDebugMode) return;

    final now = DateTime.now();
    if (lastFrameTime != null) {
      final frameDuration = now.difference(lastFrameTime!);
      final fps = 1000 / frameDuration.inMilliseconds;

      frameCount++;
      averageFps = (averageFps * (frameCount - 1) + fps) / frameCount;

      if (frameCount % 60 == 0) {
        debugPrint(
            'LoadingOverlayWithIcon FPS: ${averageFps.toStringAsFixed(1)}');
      }
    }
    lastFrameTime = now;

    if (shouldContinue()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        measureFrameRate(shouldContinue);
      });
    }
  }

  /// 성능 디버그 정보 위젯을 생성합니다.
  Widget buildPerformanceDebugInfo({
    required bool enablePerformanceOptimization,
  }) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS: ${averageFps.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Frames: $frameCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          Text(
            'Optimized: $enablePerformanceOptimization',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
