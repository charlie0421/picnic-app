import 'package:flutter/material.dart';

class DialogCommonDivider extends StatelessWidget {
  const DialogCommonDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1.2,
      indent: 20,
      endIndent: 20,
    );
  }
}
