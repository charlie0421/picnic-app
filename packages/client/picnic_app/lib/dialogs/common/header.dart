import 'package:flutter/material.dart';

class DialogCommonHeader extends StatelessWidget {
  final String title;

  const DialogCommonHeader({super.key, required this.title});

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
