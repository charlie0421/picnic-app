import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/services/animation_service.dart';

/// Staggered 애니메이션이 적용된 리스트 아이템 위젯
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? duration;
  final Duration? delay;
  final AnimationType animationType;
  final Curve curve;
  final Offset? slideDirection;
  final double? fadeBegin;
  final double? scaleBegin;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration,
    this.delay,
    this.animationType = AnimationType.slideInFromRight,
    this.curve = Curves.easeInOut,
    this.slideDirection,
    this.fadeBegin = 0.0,
    this.scaleBegin = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration ?? AnimationService.defaultDuration,
      delay: delay,
      child: _buildAnimatedChild(),
    );
  }

  Widget _buildAnimatedChild() {
    switch (animationType) {
      case AnimationType.slideInFromRight:
        return SlideAnimation(
          verticalOffset: 0,
          horizontalOffset: slideDirection?.dx ?? 50.0,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.slideInFromLeft:
        return SlideAnimation(
          verticalOffset: 0,
          horizontalOffset: slideDirection?.dx ?? -50.0,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.slideInFromBottom:
        return SlideAnimation(
          verticalOffset: slideDirection?.dy ?? 50.0,
          horizontalOffset: 0,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.slideInFromTop:
        return SlideAnimation(
          verticalOffset: slideDirection?.dy ?? -50.0,
          horizontalOffset: 0,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.fadeIn:
        return FadeInAnimation(
          curve: curve,
          child: child,
        );

      case AnimationType.scaleIn:
        return ScaleAnimation(
          scale: scaleBegin ?? 0.8,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
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
          scale: scaleBegin ?? 0.0,
          curve: Curves.elasticOut,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.none:
        return child;
    }
  }
}

/// 그리드용 애니메이션 아이템
class AnimatedGridItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int columnCount;
  final Duration? duration;
  final AnimationType animationType;
  final Curve curve;

  const AnimatedGridItem({
    super.key,
    required this.child,
    required this.index,
    this.columnCount = 2,
    this.duration,
    this.animationType = AnimationType.scaleIn,
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: duration ?? AnimationService.defaultDuration,
      columnCount: columnCount,
      child: _buildAnimatedChild(),
    );
  }

  Widget _buildAnimatedChild() {
    switch (animationType) {
      case AnimationType.scaleIn:
        return ScaleAnimation(
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.slideInFromBottom:
        return SlideAnimation(
          verticalOffset: 50.0,
          curve: curve,
          child: FadeInAnimation(
            curve: curve,
            child: child,
          ),
        );

      case AnimationType.fadeIn:
        return FadeInAnimation(
          curve: curve,
          child: child,
        );

      default:
        return AnimatedListItem(
          index: index,
          animationType: animationType,
          curve: curve,
          duration: duration,
          child: child,
        );
    }
  }
}

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

/// 커스텀 staggered 애니메이션 빌더
class StaggeredAnimationBuilder extends StatelessWidget {
  final List<Widget> children;
  final Duration animationDuration;
  final Duration staggerDelay;
  final AnimationType animationType;
  final Curve curve;
  final Axis direction;

  const StaggeredAnimationBuilder({
    super.key,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationType = AnimationType.slideInFromRight,
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: direction == Axis.vertical
          ? Column(
              children: _buildAnimatedChildren(),
            )
          : Row(
              children: _buildAnimatedChildren(),
            ),
    );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(
      children.length,
      (index) => AnimatedListItem(
        index: index,
        duration: animationDuration,
        delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
        animationType: animationType,
        curve: curve,
        child: children[index],
      ),
    );
  }
}

/// 페이지 전환용 애니메이션
class PageTransitionBuilder {
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
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

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}