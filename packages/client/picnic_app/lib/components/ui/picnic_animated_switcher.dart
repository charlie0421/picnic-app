import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PicnicAnimatedSwitcher extends ConsumerStatefulWidget {
  const PicnicAnimatedSwitcher({super.key});

  @override
  _PicnicAnimatedSwitcherState createState() => _PicnicAnimatedSwitcherState();
}

class _PicnicAnimatedSwitcherState
    extends ConsumerState<PicnicAnimatedSwitcher> {
  bool _showAnimation = false;
  Widget? _previousTopWidget;
  Uint8List? _gifBytes;
  Key _animationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // _loadGifBytes();
  }

  Future<void> _loadGifBytes() async {
    final ByteData data = await rootBundle.load('assets/splash.gif');
    setState(() {
      _gifBytes = data.buffer.asUint8List();
    });
  }

  void _triggerAnimation() {
    if (mounted) {
      setState(() {
        _showAnimation = true;
        _animationKey = UniqueKey();
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
            margin: navigationInfo.showBottomNavigation
                ? const EdgeInsets.only(bottom: 102)
                : null,
            child: currentTopWidget ?? Container(),
          ),
        ),
        if (_showAnimation && _gifBytes != null)
          Positioned.fill(
            key: _animationKey,
            child: Image.memory(
              _gifBytes!,
              fit: BoxFit.fill,
              gaplessPlayback: true,
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

    logger.i('drawerNavigationStack: ${navigationInfo.drawerNavigationStack}');

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
