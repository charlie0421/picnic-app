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
    // 현재 위치의 인셋을 유지해야 키보드와 화면 전환을 반영하고,
    // SystemNavigationBarInset이 제거한 하단 여백도 되살리지 않는다.
    final live = MediaQuery.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, contentConstraints) => MediaQuery(
            data: live.copyWith(
              size: Size(
                contentConstraints.maxWidth,
                contentConstraints.hasBoundedHeight
                    ? contentConstraints.maxHeight
                    : live.size.height,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
