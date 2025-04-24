import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_page.dart';
import 'package:picnic_lib/presentation/pages/pic/library_page.dart';

class PicHomeScreen extends ConsumerStatefulWidget {
  const PicHomeScreen({super.key});

  @override
  ConsumerState<PicHomeScreen> createState() => _PicHomeScreenState();
}

class _PicHomeScreenState extends ConsumerState<PicHomeScreen> {
  bool _isSwipeEnabled = true;
  Timer? _swipeTimer;

  // 스크린 정보 직접 정의
  final List<BottomNavigationItem> picPages = const [
    BottomNavigationItem(
      title: 'nav_home',
      assetPath: 'assets/icons/bottom/home.svg',
      index: 0,
      pageWidget: PicHomePage(),
      needLogin: false,
    ),
    BottomNavigationItem(
      title: 'nav_gallery',
      assetPath: 'assets/icons/bottom/gallery.svg',
      index: 1,
      pageWidget: GalleryPage(),
      needLogin: false,
    ),
    BottomNavigationItem(
      title: 'nav_library',
      assetPath: 'assets/icons/bottom/library.svg',
      index: 3,
      pageWidget: LibraryPage(),
      needLogin: false,
    ),
  ];

  late final ScreenInfo screenInfo = ScreenInfo(
    type: PortalType.pic,
    color: picMainColor,
    pages: picPages,
  );

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
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));
    final picBottomNavigationIndex = ref.watch(navigationInfoProvider
        .select((value) => value.picBottomNavigationIndex));
    logger.d('showBottomNavigation: $showBottomNavigation');
    logger.d('picBottomNavigationIndex: $picBottomNavigationIndex');

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
              if (showBottomNavigation == true)
                Positioned(
                    bottom: getBottomPadding(context),
                    left: 0,
                    right: 0,
                    child: CommonBottomNavigationBar()),
            ],
          ),
        ),
      ),
    );
  }
}
