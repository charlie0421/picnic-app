import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/components/common/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  double _cumulativeDx = 0;
  bool _isSwipeEnabled = true;
  Timer? _swipeTimer;

  @override
  void dispose() {
    _swipeTimer?.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        logger.d('PopScope onPopInvokedWithResult: $didPop, $result');
        _handleRightSwipe();
      },
      child: Listener(
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
        ),
      ),
    );
  }
}
