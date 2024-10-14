import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/common/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class VoteHomeScreen extends ConsumerStatefulWidget {
  const VoteHomeScreen({super.key});

  @override
  ConsumerState<VoteHomeScreen> createState() => _VoteHomeScreenState();
}

class _VoteHomeScreenState extends ConsumerState<VoteHomeScreen> {
  double _cumulativeDx = 0;
  bool _isSwipeEnabled = true;
  Timer? _swipeTimer;

  void _handleRightSwipe() {
    if (_isSwipeEnabled) {
      logger.d('Right swipe detected');
      final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);
      navigationInfoNotifier.goBack();
      setState(() {
        _isSwipeEnabled = false;
      });

      _swipeTimer?.cancel();
      _swipeTimer = Timer(const Duration(seconds: 1), () {
        setState(() {
          _isSwipeEnabled = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _swipeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (PointerMoveEvent event) {
        _cumulativeDx += event.delta.dx;
        if (_cumulativeDx.abs() > 100) {
          if (_cumulativeDx > 0) {
            _handleRightSwipe();
          }
          _cumulativeDx = 0; // 누적값 리셋
        }
      },
      onPointerUp: (PointerUpEvent event) {
        _cumulativeDx = 0; // 터치 종료 시 누적값 리셋
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          const PicnicAnimatedSwitcher(),
          if (showBottomNavigation == true)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CommonBottomNavigationBar(
                screenInfo: voteScreenInfo,
              ),
            ),
        ],
      ),
    );
  }
}
