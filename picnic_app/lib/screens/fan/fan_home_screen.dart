import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/bottom/fan_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic-animated-switcher.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/fan/landing_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class FanHomeScreen extends ConsumerStatefulWidget {
  const FanHomeScreen({super.key});

  @override
  ConsumerState<FanHomeScreen> createState() => _FanHomeScreenState();
}

class _FanHomeScreenState extends ConsumerState<FanHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return Scaffold(
        body: Stack(
      children: [
        const PicnicAnimatedSwitcher(),
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
                backgroundColor: fanMainColor,
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
