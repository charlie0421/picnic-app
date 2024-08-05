import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/ui/style.dart';

class SmoothCircularCountdown extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const SmoothCircularCountdown({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  _SmoothCircularCountdownState createState() =>
      _SmoothCircularCountdownState();
}

class _SmoothCircularCountdownState extends State<SmoothCircularCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentSeconds;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.remainingSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.remainingSeconds),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_controller);

    _controller.addListener(() {
      setState(() {
        _currentSeconds = (_animation.value * widget.remainingSeconds).ceil();
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16.w,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(16.w, 16.w),
                painter: CircularCountdownPainter(
                  progress: _animation.value,
                  remainingSeconds: _currentSeconds,
                ),
              );
            },
          ),
          Text(
            '$_currentSeconds',
            style: getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
          ),
        ],
      ),
    );
  }
}

class CircularCountdownPainter extends CustomPainter {
  final double progress;
  final int remainingSeconds;

  CircularCountdownPainter(
      {required this.progress, required this.remainingSeconds});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = AppColors.Grey700
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      true,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
