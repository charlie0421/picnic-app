import 'package:flutter/material.dart';

class RotationImage extends StatefulWidget {
  const RotationImage({super.key, required this.image});

  final Image image;

  @override
  State<RotationImage> createState() => _RotationImageState();
}

class _RotationImageState extends State<RotationImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // 반복 애니메이션을 위해
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.image, // 여기에 PNG 파일 경로를 넣으세요
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2.0 * 3.141592653589793,
            // 2π 라디안 (360도)
            child: child,
          );
        },
      ),
    );
  }
}
