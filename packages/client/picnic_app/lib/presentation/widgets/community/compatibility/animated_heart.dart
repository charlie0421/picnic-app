import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

class PulsingHeart extends StatefulWidget {
  const PulsingHeart({
    super.key,
    this.size = 24.0,
    this.color = AppColors.primary500,
    this.duration = const Duration(seconds: 1),
  });

  final double size;
  final Color color;
  final Duration duration;

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.favorite,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

// 더 화려한 버전을 원하시면 아래 컴포넌트를 사용하세요
class FancyPulsingHeart extends StatefulWidget {
  const FancyPulsingHeart({
    super.key,
    this.size = 24.0,
    this.color = AppColors.primary500,
    this.duration = const Duration(seconds: 2),
  });

  final double size;
  final Color color;
  final Duration duration;

  @override
  State<FancyPulsingHeart> createState() => _FancyPulsingHeartState();
}

class _FancyPulsingHeartState extends State<FancyPulsingHeart>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_mainController);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_glowAnimation.value * 0.4),
              child: Opacity(
                opacity: (1 - _glowAnimation.value) * 0.5,
                child: Icon(
                  Icons.favorite,
                  size: widget.size * 1.2,
                  color: widget.color.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        ),
        // Main heart
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                Icons.favorite,
                size: widget.size,
                color: widget.color,
              ),
            );
          },
        ),
      ],
    );
  }
}
