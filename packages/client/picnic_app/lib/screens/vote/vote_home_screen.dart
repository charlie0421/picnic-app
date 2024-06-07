import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/bottom/navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/menu.dart';

class VoteHomeScreen extends ConsumerWidget {
  const VoteHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const PicnicAnimatedSwitcher(),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CommonBottomNavigationBar(
              screenInfo: voteScreenInfo,
            )),
      ],
    );
  }
}
