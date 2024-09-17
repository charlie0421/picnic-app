import 'package:flutter/material.dart';

class FixedWidthLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const FixedWidthLayout({
    super.key,
    required this.child,
    this.maxWidth = 600, // 원하는 최대 너비를 설정하세요
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(maxWidth, constraints.maxHeight),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
