import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

class PicnicAnimatedSwitcher extends ConsumerStatefulWidget {
  const PicnicAnimatedSwitcher({super.key});

  @override
  ConsumerState<PicnicAnimatedSwitcher> createState() =>
      _PicnicAnimatedSwitcherState();
}

class _PicnicAnimatedSwitcherState
    extends ConsumerState<PicnicAnimatedSwitcher> {
  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    // 현재 포털 타입에 따라 해당하는 NavigationStack의 모든 위젯을 가져와서
    // IndexedStack으로 유지하여 상태(스크롤 등)를 보존한다.
    List<Widget> stackChildren;
    switch (navigationInfo.portalType) {
      case PortalType.vote:
        stackChildren = navigationInfo.voteNavigationStack?.items ?? const [];
        break;
      case PortalType.community:
        stackChildren =
            navigationInfo.communityNavigationStack?.items ?? const [];
        break;
      case PortalType.pic:
        // pic은 현재 vote 스택 공유
        stackChildren = navigationInfo.voteNavigationStack?.items ?? const [];
        break;
      case PortalType.novel:
        // novel도 현재 vote 스택 공유
        stackChildren = navigationInfo.voteNavigationStack?.items ?? const [];
        break;
      default:
        stackChildren = navigationInfo.voteNavigationStack?.items ?? const [];
    }

    final currentIndex = stackChildren.isNotEmpty
        ? stackChildren.length - 1
        : 0;

    return Container(
      padding: navigationInfo.showBottomNavigation
          ? const EdgeInsets.only(
              bottom:
                  NavBarConstants.bottomNavHeight +
                  NavBarConstants.bottomNavOuterMargin,
            )
          : EdgeInsets.zero,
      child: stackChildren.isNotEmpty
          ? IndexedStack(index: currentIndex, children: stackChildren)
          : Container(),
    );
  }
}

class DrawerAnimatedSwitcher extends ConsumerWidget {
  const DrawerAnimatedSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return currentChild ?? Container();
      },
      child: Container(
        child:
            navigationInfo.drawerNavigationStack != null &&
                navigationInfo.drawerNavigationStack!.length > 0
            ? navigationInfo.drawerNavigationStack?.peek()
            : Container(),
      ),
    );
  }
}

class SignUpAnimatedSwitcher extends ConsumerWidget {
  const SignUpAnimatedSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    logger.i('signUpNavigationStack: ${navigationInfo.signUpNavigationStack}');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return currentChild ?? Container();
      },
      child: Container(
        child:
            navigationInfo.signUpNavigationStack != null &&
                navigationInfo.signUpNavigationStack!.length > 0
            ? navigationInfo.signUpNavigationStack?.peek()
            : Container(),
      ),
    );
  }
}
