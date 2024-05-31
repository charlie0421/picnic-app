import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/bottom/navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic-animated-switcher.dart';
import 'package:picnic_app/menu.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const PicnicAnimatedSwitcher(),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CommonBottomNavigationBar(screenInfo: communityScreenInfo)),
      ],
    );
  }
}
