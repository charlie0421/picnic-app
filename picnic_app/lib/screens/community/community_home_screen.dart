import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/bottom/community_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic-animated-switcher.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            PicnicAnimatedSwitcher(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommunityBottomNavigationBar(),
            ),
          ],
        ));
  }
}
