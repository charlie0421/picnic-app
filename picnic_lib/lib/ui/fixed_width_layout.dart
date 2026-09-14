import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';

class FixedWidthLayout extends ConsumerWidget {
  final Widget child;
  final double maxWidth;

  const FixedWidthLayout({
    super.key,
    required this.child,
    this.maxWidth = 600, // 원하는 최대 너비를 설정하세요
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 크기 등은 시작 시점 스냅샷을 쓰되, 안전영역 인셋은 현재 위치의
        // 라이브 값을 따른다. 앱 루트의 SystemNavigationBarInset 이 Android
        // 시스템 내비 바 높이를 이미 예약하고 하위 bottom 인셋을 0 으로 만들기
        // 때문에, 스냅샷의 bottom 값을 되살리면 이중 여백이 생긴다(PICNIC-777).
        final live = MediaQuery.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: MediaQuery(
              data: ref
                  .watch(globalMediaQueryProvider)
                  .copyWith(
                    size: Size(maxWidth, constraints.maxHeight),
                    padding: live.padding,
                    viewPadding: live.viewPadding,
                  ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
