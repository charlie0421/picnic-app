import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/bottom/vote_navigation_bar.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class VoteHomeScreen extends ConsumerWidget {
  const VoteHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return Scaffold(
        backgroundColor: Colors.transparent,
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
                child: voteScreens[navigationInfo.voteBottomNavigationIndex]),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VoteBottomNavigationBar(),
            ),
          ],
        ));
  }
}
