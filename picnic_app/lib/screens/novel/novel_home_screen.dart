import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/bottom/navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class NovelHomeScreen extends ConsumerWidget {
  const NovelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));

    return Stack(
      children: [
        const PicnicAnimatedSwitcher(),
        if (showBottomNavigation == true)
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigationBar(
                screenInfo: novelScreenInfo,
              )),
      ],
    );
  }
}
