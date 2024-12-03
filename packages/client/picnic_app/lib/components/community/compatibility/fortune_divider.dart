import 'package:flutter/material.dart';

class FortuneDivider extends StatelessWidget {
  final Color color;

  const FortuneDivider({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 3,
        width: 48,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color,
        ),
      ),
    );
  }
}
