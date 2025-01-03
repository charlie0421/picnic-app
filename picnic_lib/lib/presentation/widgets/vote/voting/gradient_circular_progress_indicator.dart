import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

const Duration _duration = Duration(milliseconds: 1000);

class GradientCircularProgressIndicator extends StatefulWidget {
  final double value;
  final double strokeWidth;
  final List<Color> gradientColors;

  const GradientCircularProgressIndicator({
    super.key,
    required this.value,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  State<GradientCircularProgressIndicator> createState() =>
      _GradientCircularProgressIndicatorState();
}

class _GradientCircularProgressIndicatorState
    extends State<GradientCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    )..forward(); // 진행 후 멈춤

    _animation =
        Tween<double>(begin: 0, end: widget.value).animate(_controller);
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
        return CustomPaint(
          painter: _GradientCircularProgressPainter(
            value: _animation.value,
            strokeWidth: widget.strokeWidth,
            gradientColors: widget.gradientColors,
          ),
          child: const SizedBox(
            width: 100,
            height: 100,
          ),
        );
      },
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final List<Color> gradientColors;

  _GradientCircularProgressPainter({
    required this.value,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors: gradientColors,
      stops: const [0.0, 0.75],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint backgroundPaint = Paint()
      ..color = AppColors.grey200.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint endPaint = Paint()
      ..color = gradientColors.last
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double startAngle = -3.14159 / 2;
    final double sweepAngle = 2 * 3.14159 * value;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (value <= 0.75) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * 0.75,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 2 * 3.14159 * 0.75,
        sweepAngle - 2 * 3.14159 * 0.75,
        false,
        endPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
