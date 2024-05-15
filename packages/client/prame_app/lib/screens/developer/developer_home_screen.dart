import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/components/developer/developer_navigation_bar.dart';
import 'package:prame_app/providers/navigation_provider.dart';

class DeveloperHomeScreen extends ConsumerWidget {
  const DeveloperHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return Scaffold(
        body: Stack(
      children: [
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
              return currentChild ?? Container();
            },
            child: navigationInfo.currentPage),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: DeveloperBottomNavigationBar(),
        ),
      ],
    ));
  }
}
