import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:ttja_app/bottom_navigation_menu.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
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
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onPanUpdate: (details) {
            // 수평 방향의 움직임이 수직 방향보다 크고, 오른쪽으로 움직일 때만 처리
            if (details.delta.dx.abs() > details.delta.dy.abs() &&
                details.delta.dx > 0) {
              // 여기서 임계값을 설정하여 작은 움직임은 무시할 수 있습니다.
              if (details.delta.dx > 20) {
                // 예: 20픽셀 이상의 움직임만 고려
                _handleRightSwipe();
              }
            }
          },
          child: Stack(
            children: [
              const PicnicAnimatedSwitcher(),
              if (navigationInfo.showBottomNavigation)
                Positioned(
                  bottom: getBottomPadding(context),
                  left: 0,
                  right: 0,
                  child: CommonBottomNavigationBar(
                    screenInfo: communityScreenInfo,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
