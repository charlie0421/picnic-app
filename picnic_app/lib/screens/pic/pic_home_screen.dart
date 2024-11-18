import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/common/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';

class PicHomeScreen extends ConsumerStatefulWidget {
  const PicHomeScreen({super.key});

  @override
  ConsumerState<PicHomeScreen> createState() => _PicHomeScreenState();
}

class _PicHomeScreenState extends ConsumerState<PicHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));
    final picBottomNavigationIndex = ref.watch(navigationInfoProvider
        .select((value) => value.picBottomNavigationIndex));
    logger.d('showBottomNavigation: $showBottomNavigation');
    logger.d('picBottomNavigationIndex: $picBottomNavigationIndex');

    return Stack(
      children: [
        const PicnicAnimatedSwitcher(),
        if (showBottomNavigation == true)
          Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: CommonBottomNavigationBar(
                screenInfo: picScreenInfo,
              )),
      ],
    );
  }
}
