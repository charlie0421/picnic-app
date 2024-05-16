import 'package:flutter/material.dart';

class DialogCommonVerticalDivider extends StatelessWidget {
  const DialogCommonVerticalDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      color: Colors.grey,
      thickness: 1,
      indent: 5,
      endIndent: 5,
    );
  }
}
