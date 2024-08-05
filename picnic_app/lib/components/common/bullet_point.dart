import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text(
          '• ',
          style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
        ),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}
