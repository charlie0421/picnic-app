import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/common/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/pic/landing_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

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
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigationBar(
                screenInfo: picScreenInfo,
              )),
        if (picBottomNavigationIndex == 0)
          Positioned(
              right: 20.cw,
              bottom: 120.cw,
              child: FloatingActionButton(
                onPressed: _buildFloating,
                backgroundColor: picMainColor,
                child: const Icon(Icons.bookmarks),
              )),
      ],
    );
  }

  void _buildFloating() {
    logger.d('Floating button clicked');
    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return const LandingPage();
        });
  }
}
