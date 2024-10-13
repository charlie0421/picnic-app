import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/providers/global_media_query.dart';

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
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: MediaQuery(
              data: ref.watch(globalMediaQueryProvider).copyWith(
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
