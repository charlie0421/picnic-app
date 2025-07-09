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
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? textStyle;
  final Color? underlineColor;
  final double underlineHeight;
  final double underlineGap;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          style: textStyle,
          maxLines: maxLines,
          overflow: overflow,
        ),
        SizedBox(height: underlineGap),
        Container(
          height: underlineHeight,
          color: underlineColor ?? AppColors.primary500,
        ),
      ],
    );
  }
}
