import 'package:flutter/material.dart';

Widget buildImageLoadingOverlay() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: const Color.fromRGBO(158, 158, 158, 0.05),
    child: ShimmerLoading(
      isLoading: true,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    ),
  );
}

class ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const ShimmerLoading({super.key, required this.isLoading, required this.child});

  @override
  ShimmerLoadingState createState() => ShimmerLoadingState();
}

class ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: const [
                  Color(0xFFEBEBF4),
                  Color(0xFFF4F4F4),
                  Color(0xFFEBEBF4),
                ],
                stops: const [0.1, 0.3, 0.4],
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                tileMode: TileMode.clamp,
                transform: SlidingGradientTransform(
                  slidePercent: _animation.value,
                ),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  const SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
