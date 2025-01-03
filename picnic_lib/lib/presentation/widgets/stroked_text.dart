import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class StrokedText extends StatelessWidget {
  const StrokedText({
    super.key,
    required this.text,
    required this.textStyle,
    this.strokeColor = AppColors.primary500,
    this.strokeWidth = 1,
  });

  final String text;
  final TextStyle textStyle;
  final double strokeWidth;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Stroke (외곽선)
        Text(
          text,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // Main text (내부 텍스트)
        Text(
          text,
          style: textStyle,
        ),
      ],
    );
  }
}
