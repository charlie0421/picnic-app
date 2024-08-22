import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/bottom/navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the bottom padding of the screen (usually the height of the system navigation bar)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final navigationInfo = ref.watch(navigationInfoProvider);

    return Stack(
      children: [
        const PicnicAnimatedSwitcher(),
        if (navigationInfo.showBottomNavigation)
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigationBar(
                screenInfo: communityScreenInfo,
              )),
      ],
    );
  }
}
