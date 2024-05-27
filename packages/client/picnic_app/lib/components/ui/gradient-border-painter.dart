import 'package:flutter/material.dart';

class GradientBorderPainter extends CustomPainter {
  final double borderRadius;
  final Gradient gradient;
  final double borderWidth;

  GradientBorderPainter({
    required this.borderRadius,
    required this.gradient,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
