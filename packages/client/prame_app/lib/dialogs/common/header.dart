import 'package:flutter/material.dart';

class DialogCommonHeader extends StatelessWidget {
  final String title;

  const DialogCommonHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: 54,
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ));
  }
}
