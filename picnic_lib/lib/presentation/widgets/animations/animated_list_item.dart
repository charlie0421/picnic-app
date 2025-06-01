import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Animated list item that uses staggered animations for better performance
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final double slideDistance;
  final double scaleBegin;
  final double fadeBegin;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.slideAndFade,
    this.slideDistance = 50.0,
    this.scaleBegin = 0.8,
    this.fadeBegin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      delay: delay,
      child: _buildAnimation(),
    );
  }

  Widget _buildAnimation() {
    switch (animationType) {
      case AnimationType.slideAndFade:
        return SlideAnimation(
          duration: duration,
          curve: curve,
          verticalOffset: slideDistance,
          child: FadeInAnimation(
            duration: duration,
            curve: curve,
            child: child,
          ),
        );
      
      case AnimationType.scaleAndFade:
        return ScaleAnimation(
          duration: duration,
          curve: curve,
          scale: scaleBegin,
          child: FadeInAnimation(
            duration: duration,
            curve: curve,
            child: child,
          ),
        );
      
      case AnimationType.slideFromLeft:
        return SlideAnimation(
          duration: duration,
          curve: curve,
          horizontalOffset: -slideDistance,
          child: child,
        );
      
      case AnimationType.slideFromRight:
        return SlideAnimation(
          duration: duration,
          curve: curve,
          horizontalOffset: slideDistance,
          child: child,
        );
      
      case AnimationType.fadeIn:
        return FadeInAnimation(
          duration: duration,
          curve: curve,
          child: child,
        );
      
      case AnimationType.scale:
        return ScaleAnimation(
          duration: duration,
          curve: curve,
          scale: scaleBegin,
          child: child,
        );
      
      case AnimationType.flipVertical:
        return FlipAnimation(
          duration: duration,
          curve: curve,
          flipAxis: FlipAxis.y,
          child: child,
        );
      
      case AnimationType.flipHorizontal:
        return FlipAnimation(
          duration: duration,
          curve: curve,
          flipAxis: FlipAxis.x,
          child: child,
        );
    }
  }
}

/// Animation types for list items
enum AnimationType {
  slideAndFade,
  scaleAndFade,
  slideFromLeft,
  slideFromRight,
  fadeIn,
  scale,
  flipVertical,
  flipHorizontal,
}

/// Optimized animated grid item for grid views
class AnimatedGridItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int columnCount;
  final Duration delay;
  final Duration duration;

  const AnimatedGridItem({
    super.key,
    required this.child,
    required this.index,
    this.columnCount = 2,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      columnCount: columnCount,
      delay: delay,
      child: ScaleAnimation(
        duration: duration,
        curve: Curves.elasticOut,
        child: FadeInAnimation(
          duration: duration,
          child: child,
        ),
      ),
    );
  }
}

/// Custom staggered animation wrapper
class StaggeredAnimationWrapper extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Axis scrollDirection;
  final AnimationType animationType;

  const StaggeredAnimationWrapper({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.scrollDirection = Axis.vertical,
    this.animationType = AnimationType.slideAndFade,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: children
            .asMap()
            .entries
            .map((entry) => AnimatedListItem(
                  index: entry.key,
                  delay: delay,
                  duration: duration,
                  animationType: animationType,
                  child: entry.value,
                ))
            .toList(),
      ),
    );
  }
}

/// Reusable animation configurations
class AnimationConfigs {
  static const Duration fastDelay = Duration(milliseconds: 30);
  static const Duration normalDelay = Duration(milliseconds: 50);
  static const Duration slowDelay = Duration(milliseconds: 100);

  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Common curve combinations
  static const Curve bounceInCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve sharpCurve = Curves.easeOutExpo;
}

/// Performance optimized animated container
class OptimizedAnimatedContainer extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.isVisible = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.slideAndFade,
  });

  @override
  State<OptimizedAnimatedContainer> createState() => _OptimizedAnimatedContainerState();
}

class _OptimizedAnimatedContainerState extends State<OptimizedAnimatedContainer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(_animation);

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OptimizedAnimatedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.slideAndFade:
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _animation,
                child: widget.child,
              ),
            );
          
          case AnimationType.scaleAndFade:
            return ScaleTransition(
              scale: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: widget.child,
              ),
            );
          
          case AnimationType.fadeIn:
            return FadeTransition(
              opacity: _animation,
              child: widget.child,
            );
          
          default:
            return FadeTransition(
              opacity: _animation,
              child: widget.child,
            );
        }
      },
    );
  }
}