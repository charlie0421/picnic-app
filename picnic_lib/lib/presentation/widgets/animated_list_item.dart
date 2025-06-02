import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// 애니메이션 타입 열거형
enum AnimationType {
  slideInFromRight,
  slideInFromLeft,
  slideInFromBottom,
  slideInFromTop,
  fadeIn,
  scaleIn,
  flipInX,
  flipInY,
  bounceIn,
  none,
}

/// 애니메이션 방향
enum AnimationDirection {
  horizontal,
  vertical,
}

/// 애니메이션이 적용된 리스트 아이템 위젯
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.animationType = AnimationType.slideInFromRight,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.direction = AnimationDirection.horizontal,
    this.offset = 50.0,
    this.enabled = true,
  });

  final int index;
  final Widget child;
  final AnimationType animationType;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final AnimationDirection direction;
  final double offset;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || animationType == AnimationType.none) {
      return child;
    }

    return AnimationConfiguration.staggeredList(
      position: index,
      delay: delay,
      duration: duration,
      child: _buildAnimatedChild(),
    );
  }

  Widget _buildAnimatedChild() {
    switch (animationType) {
      case AnimationType.slideInFromRight:
        return SlideAnimation(
          horizontalOffset: offset,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromLeft:
        return SlideAnimation(
          horizontalOffset: -offset,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromBottom:
        return SlideAnimation(
          verticalOffset: offset,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromTop:
        return SlideAnimation(
          verticalOffset: -offset,
          curve: curve,
          child: child,
        );
      
      case AnimationType.fadeIn:
        return FadeInAnimation(
          curve: curve,
          child: child,
        );
      
      case AnimationType.scaleIn:
        return ScaleAnimation(
          curve: curve,
          child: child,
        );
      
      case AnimationType.flipInX:
        return FlipAnimation(
          flipAxis: FlipAxis.x,
          curve: curve,
          child: child,
        );
      
      case AnimationType.flipInY:
        return FlipAnimation(
          flipAxis: FlipAxis.y,
          curve: curve,
          child: child,
        );
      
      case AnimationType.bounceIn:
        return ScaleAnimation(
          curve: Curves.bounceOut,
          child: child,
        );
      
      case AnimationType.none:
        return child;
    }
  }
}

/// 그리드 아이템용 애니메이션 위젯
class AnimatedGridItem extends StatelessWidget {
  const AnimatedGridItem({
    super.key,
    required this.index,
    required this.child,
    required this.columnCount,
    this.animationType = AnimationType.scaleIn,
    this.duration = const Duration(milliseconds: 375),
    this.delay = Duration.zero,
    this.curve = Curves.elasticOut,
    this.enabled = true,
  });

  final int index;
  final Widget child;
  final int columnCount;
  final AnimationType animationType;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || animationType == AnimationType.none) {
      return child;
    }

    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: duration,
      delay: delay,
      columnCount: columnCount,
      child: _buildAnimatedChild(),
    );
  }

  Widget _buildAnimatedChild() {
    switch (animationType) {
      case AnimationType.slideInFromRight:
        return SlideAnimation(
          horizontalOffset: 50.0,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromLeft:
        return SlideAnimation(
          horizontalOffset: -50.0,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromBottom:
        return SlideAnimation(
          verticalOffset: 50.0,
          curve: curve,
          child: child,
        );
      
      case AnimationType.slideInFromTop:
        return SlideAnimation(
          verticalOffset: -50.0,
          curve: curve,
          child: child,
        );
      
      case AnimationType.fadeIn:
        return FadeInAnimation(
          curve: curve,
          child: child,
        );
      
      case AnimationType.scaleIn:
        return ScaleAnimation(
          curve: curve,
          child: child,
        );
      
      case AnimationType.flipInX:
        return FlipAnimation(
          flipAxis: FlipAxis.x,
          curve: curve,
          child: child,
        );
      
      case AnimationType.flipInY:
        return FlipAnimation(
          flipAxis: FlipAxis.y,
          curve: curve,
          child: child,
        );
      
      case AnimationType.bounceIn:
        return ScaleAnimation(
          curve: Curves.bounceOut,
          child: child,
        );
      
      case AnimationType.none:
        return child;
    }
  }
}

/// 복잡한 스태거드 애니메이션을 위한 빌더
class StaggeredAnimationBuilder extends StatelessWidget {
  const StaggeredAnimationBuilder({
    super.key,
    required this.children,
    this.animationType = AnimationType.slideInFromRight,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    this.enabled = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.direction = Axis.vertical,
  });

  final List<Widget> children;
  final AnimationType animationType;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;
  final bool enabled;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return direction == Axis.vertical
          ? Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            )
          : Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            );
    }

    final animatedChildren = children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return AnimatedListItem(
        index: index,
        animationType: animationType,
        duration: duration,
        delay: staggerDelay * index,
        curve: curve,
        child: child,
      );
    }).toList();

    return direction == Axis.vertical
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: animatedChildren,
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: animatedChildren,
          );
  }
}

/// 페이지 전환을 위한 애니메이션 빌더
class PageTransitionBuilder {
  /// 슬라이드 페이지 전환
  static Route<T> slideTransition<T>({
    required Widget page,
    required RouteSettings settings,
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.rightToLeft:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.leftToRight:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.topToBottom:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.bottomToTop:
            begin = const Offset(0.0, 1.0);
            break;
        }

        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// 페이드 페이지 전환
  static Route<T> fadeTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }

  /// 스케일 페이지 전환
  static Route<T> scaleTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.elasticOut,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          alignment: alignment,
          child: child,
        );
      },
    );
  }

  /// 회전 페이지 전환
  static Route<T> rotationTransition<T>({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          ),
        );

        return RotationTransition(
          turns: rotationAnimation,
          alignment: alignment,
          child: ScaleTransition(
            scale: rotationAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

/// 슬라이드 방향 열거형
enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}

/// 애니메이션 프리셋
class AnimationPresets {
  /// 빠른 페이드인
  static const Duration quickFade = Duration(milliseconds: 150);
  
  /// 표준 슬라이드
  static const Duration standardSlide = Duration(milliseconds: 300);
  
  /// 느린 스케일
  static const Duration slowScale = Duration(milliseconds: 500);
  
  /// 바운스 효과
  static const Curve bounceCurve = Curves.bounceOut;
  
  /// 엘라스틱 효과
  static const Curve elasticCurve = Curves.elasticOut;
  
  /// 빠른 시작 느린 끝
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

/// 애니메이션 유틸리티
class AnimationHelper {
  /// 인덱스 기반 지연 계산
  static Duration calculateDelay(int index, {
    Duration baseDelay = const Duration(milliseconds: 50),
    int maxDelay = 5,
  }) {
    final delayIndex = index.clamp(0, maxDelay);
    return baseDelay * delayIndex;
  }

  /// 거리 기반 애니메이션 지속시간 계산
  static Duration calculateDuration(double distance, {
    double pixelsPerMillisecond = 1.0,
    Duration minDuration = const Duration(milliseconds: 100),
    Duration maxDuration = const Duration(milliseconds: 800),
  }) {
    final calculatedDuration = Duration(
      milliseconds: (distance / pixelsPerMillisecond).round(),
    );
    
    if (calculatedDuration < minDuration) return minDuration;
    if (calculatedDuration > maxDuration) return maxDuration;
    return calculatedDuration;
  }

  /// 화면 크기 기반 오프셋 계산
  static double calculateOffset(BuildContext context, {
    double factor = 0.1,
    double minOffset = 20.0,
    double maxOffset = 100.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedOffset = screenWidth * factor;
    return calculatedOffset.clamp(minOffset, maxOffset);
  }
}