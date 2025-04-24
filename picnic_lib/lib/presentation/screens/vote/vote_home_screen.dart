import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/pic_chart_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_media_list_page.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';

class VoteHomeScreen extends ConsumerStatefulWidget {
  const VoteHomeScreen({super.key});

  @override
  ConsumerState<VoteHomeScreen> createState() => _VoteHomeScreenState();
}

class _VoteHomeScreenState extends ConsumerState<VoteHomeScreen> {
  bool _isSwipeEnabled = true;
  Timer? _swipeTimer;
  int _lastRebuildMarker = 0;

  // 스크린 정보 직접 정의
  final List<BottomNavigationItem> votePages = [
    const BottomNavigationItem(
      title: 'nav_vote',
      assetPath: 'assets/icons/bottom/vote.svg',
      index: 0,
      pageWidget: VoteHomePage(),
      needLogin: false,
    ),
    BottomNavigationItem(
      title: 'nav_picchart',
      assetPath: 'assets/icons/bottom/pic_chart.svg',
      index: 1,
      pageWidget: PicChartPage(),
      needLogin: false,
    ),
    const BottomNavigationItem(
      title: 'nav_media',
      assetPath: 'assets/icons/bottom/media.svg',
      index: 2,
      pageWidget: VoteMediaListPage(),
      needLogin: false,
    ),
    const BottomNavigationItem(
      title: 'nav_store',
      assetPath: 'assets/icons/bottom/store.svg',
      index: 3,
      pageWidget: StorePage(),
      needLogin: false,
    ),
  ];

  late final ScreenInfo screenInfo = ScreenInfo(
    type: PortalType.vote,
    color: voteMainColor,
    pages: votePages,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 언어 변경 감지
    final currentLanguage = ref.read(appSettingProvider).language;
    final currentRebuildMarker = globalRebuildMarker;

    if (currentRebuildMarker != _lastRebuildMarker) {
      _lastRebuildMarker = currentRebuildMarker;
      logger.i('VoteHomeScreen: 언어 변경 감지, UI 리빌드 ($currentLanguage)');

      if (mounted) {
        // 화면 전체 갱신
        setState(() {});
      }
    }
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
  void dispose() {
    _swipeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));

    // 언어 변경 감지를 위해 rebuildMarkerProvider와 appSettingProvider를 감시
    ref.watch(rebuildMarkerProvider);
    ref.watch(appSettingProvider.select((value) => value.language));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        logger.d('PopScope onPopInvokedWithResult: $didPop, $result');
        _handleRightSwipe();
      },
      child: GestureDetector(
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
          fit: StackFit.expand,
          children: [
            const PicnicAnimatedSwitcher(),
            if (showBottomNavigation == true)
              Positioned(
                bottom: getBottomPadding(context),
                left: 0,
                right: 0,
                child: CommonBottomNavigationBar(),
              ),
          ],
        ),
      ),
    );
  }
}
