import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PicnicAnimatedSwitcher extends ConsumerWidget {
  const PicnicAnimatedSwitcher({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return currentChild ?? Container();
        },
        child: Container(
            margin: navigationInfo.showBottomNavigation
                ? const EdgeInsets.only(bottom: 60).r
                : null,
            child: navigationInfo.currentPage));
  }
}
