import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class UnderlinedText extends StatelessWidget {
  const UnderlinedText({
    super.key,
    required this.text,
    this.textStyle,
    this.underlineColor,
    this.underlineHeight = 2,
    this.underlineGap = 4,
  });

  final String text;
  final TextStyle? textStyle;
  final Color? underlineColor;
  final double underlineHeight;
  final double underlineGap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(text, style: textStyle),
        Positioned(
          bottom: -underlineGap,
          left: 0,
          right: 0,
          child: Container(
            height: underlineHeight,
            color: underlineColor ?? AppColors.primary500,
          ),
        ),
      ],
    );
  }
}
