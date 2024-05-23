import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/bottom/prame_navigation_bar.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/prame/landing_page.dart';
import 'package:picnic_app/pages/prame/prame_home_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PrameHomeScreen extends ConsumerStatefulWidget {
  const PrameHomeScreen({super.key});

  @override
  ConsumerState<PrameHomeScreen> createState() => _PrameHomeScreenState();
}

class _PrameHomeScreenState extends ConsumerState<PrameHomeScreen> {
  @override
  Widget build(BuildContext context) {
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
              return currentChild ?? PrameHomePage();
            },
            child: navigationInfo.currentPage),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FanBottomNavigationBar(),
        ),
        if (navigationInfo.fanBottomNavigationIndex == 0)
          Positioned(
              right: 20.w,
              bottom: 120.h,
              child: FloatingActionButton(
                onPressed: _buildFloating,
                backgroundColor: Constants.fanMainColor,
                child: const Icon(Icons.bookmarks),
              )),
      ],
    ));
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
