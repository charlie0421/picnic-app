import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

class PicnicAnimatedSwitcher extends ConsumerStatefulWidget {
  const PicnicAnimatedSwitcher({super.key});

  @override
  ConsumerState<PicnicAnimatedSwitcher> createState() =>
      _PicnicAnimatedSwitcherState();
}

class _PicnicAnimatedSwitcherState
    extends ConsumerState<PicnicAnimatedSwitcher> {
  Widget? _previousTopWidget;

  @override
  void initState() {
    super.initState();
  }

  void _triggerAnimation() {
    if (mounted) {
      setState(() {});

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    // 현재 포털 타입에 따라 해당하는 NavigationStack을 선택
    Widget? currentTopWidget;
    switch (navigationInfo.portalType) {
      case PortalType.vote:
        currentTopWidget = navigationInfo.voteNavigationStack?.peek();
        break;
      case PortalType.community:
        currentTopWidget = navigationInfo.communityNavigationStack?.peek();
        break;
      case PortalType.pic:
        currentTopWidget = navigationInfo.voteNavigationStack
            ?.peek(); // pic은 아직 별도 스택이 없어서 vote 스택 사용
        break;
      case PortalType.novel:
        currentTopWidget = navigationInfo.voteNavigationStack
            ?.peek(); // novel도 아직 별도 스택이 없어서 vote 스택 사용
        break;
      default:
        currentTopWidget = navigationInfo.voteNavigationStack?.peek();
    }

    // 스택의 최상위 위젯이 변경될 때마다 애니메이션을 트리거합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentTopWidget != null && currentTopWidget != _previousTopWidget) {
        _triggerAnimation();
        _previousTopWidget = currentTopWidget;
      }
    });

    return Stack(
      children: [
        AnimatedSwitcher(
          key: ValueKey(currentTopWidget.hashCode),
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Container(
            padding: navigationInfo.showBottomNavigation
                ? EdgeInsets.only(bottom: getBottomPadding(context) + 52)
                : EdgeInsets.only(bottom: getBottomPadding(context)),
            child: currentTopWidget ?? Container(),
          ),
        ),
      ],
    );
  }
}

class DrawerAnimatedSwitcher extends ConsumerWidget {
  const DrawerAnimatedSwitcher({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return currentChild ?? Container();
        },
        child: Container(
            child: navigationInfo.drawerNavigationStack != null &&
                    navigationInfo.drawerNavigationStack!.length > 0
                ? navigationInfo.drawerNavigationStack?.peek()
                : Container()));
  }
}

class SignUpAnimatedSwitcher extends ConsumerWidget {
  const SignUpAnimatedSwitcher({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    logger.i('signUpNavigationStack: ${navigationInfo.signUpNavigationStack}');

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return currentChild ?? Container();
        },
        child: Container(
            child: navigationInfo.signUpNavigationStack != null &&
                    navigationInfo.signUpNavigationStack!.length > 0
                ? navigationInfo.signUpNavigationStack?.peek()
                : Container()));
  }
}
