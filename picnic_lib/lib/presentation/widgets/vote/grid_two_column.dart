import 'package:flutter/material.dart';

/// 스크롤하지 않는 순수 레이아웃 2열 그리드.
///
/// `GridView(shrinkWrap:true)`는 부모 스크롤뷰(홈 [ListView]) 안에서 중첩
/// 스크롤러블이 되어 스크롤 흔들림/재측정을 유발한다. 이 위젯은 [Column] +
/// [Row] + [AspectRatio] 만 사용해 스크롤러블 없이 동일한 2열 그리드를 만든다.
class GridTwoColumn extends StatelessWidget {
  final List<Widget> children;

  /// 각 셀의 가로:세로 비율.
  final double childAspectRatio;

  /// 열 사이 간격.
  final double crossAxisSpacing;

  /// 행 사이 간격.
  final double mainAxisSpacing;

  const GridTwoColumn({
    super.key,
    required this.children,
    this.childAspectRatio = 1.45,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: mainAxisSpacing));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: childAspectRatio,
                child: children[i],
              ),
            ),
            SizedBox(width: crossAxisSpacing),
            Expanded(
              child: i + 1 < children.length
                  ? AspectRatio(
                      aspectRatio: childAspectRatio,
                      child: children[i + 1],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
