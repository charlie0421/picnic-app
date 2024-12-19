import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class PicnicAnimatedSwitcher extends ConsumerStatefulWidget {
  const PicnicAnimatedSwitcher({super.key});

  @override
  ConsumerState<PicnicAnimatedSwitcher> createState() =>
      _PicnicAnimatedSwitcherState();
}

class _PicnicAnimatedSwitcherState
    extends ConsumerState<PicnicAnimatedSwitcher> {
  bool _showAnimation = false;
  Widget? _previousTopWidget;

  @override
  void initState() {
    super.initState();
  }

  void _triggerAnimation() {
    if (mounted) {
      setState(() {
        _showAnimation = true;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showAnimation = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final currentTopWidget = navigationInfo.voteNavigationStack?.peek();

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
