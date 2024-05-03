import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/pages/home_page.dart';
import 'package:prame_app/pages/landing_page.dart';
import 'package:prame_app/providers/navigation_provider.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return Scaffold(
        bottomNavigationBar: const FanBottomNavigationBar(),
        floatingActionButton: navigationInfo.bottomNavigationIndex == 0
            ? FloatingActionButton(
                onPressed: () => _buildFloating,
                backgroundColor: Constants.mainColor,
                child: const Icon(Icons.bookmarks),
              )
            : null,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500), // 애니메이션 지속 시간을 줄입니다.
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return currentChild ?? Container();
          },
          child: navigationInfo.currentPage ?? const HomePage(),
        ));
  }

  void _buildFloating(context) {
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
