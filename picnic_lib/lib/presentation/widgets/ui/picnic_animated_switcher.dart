import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
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

    logger.d('🔄 PicnicAnimatedSwitcher build - portalType: ${navigationInfo.portalType}');
    logger.d('🔄 voteNavigationStack length: ${navigationInfo.voteNavigationStack?.length ?? 0}');

    // 모든 포털이 voteNavigationStack을 공유
    List<Widget> stackChildren = navigationInfo.voteNavigationStack?.items ?? const [];

    // 스택이 비어있으면 기본 홈 페이지를 fallback으로 사용
    // 이는 로그인 후 간헐적 블랙 스크린 문제를 방지함
    if (stackChildren.isEmpty) {
      logger.w('⚠️ PicnicAnimatedSwitcher: Navigation stack is empty, using fallback page');
      stackChildren = [const VoteHomePage()];
    }

    final currentIndex = stackChildren.length - 1;

    return Container(
      padding: navigationInfo.showBottomNavigation
          ? const EdgeInsets.only(
              bottom:
                  NavBarConstants.bottomNavHeight +
                  NavBarConstants.bottomNavOuterMargin,
            )
          : EdgeInsets.zero,
      child: IndexedStack(index: currentIndex, children: stackChildren),
    );
  }
}

class DrawerAnimatedSwitcher extends ConsumerWidget {
  const DrawerAnimatedSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    final drawerStack = navigationInfo.drawerNavigationStack;
    final hasContent = drawerStack != null && drawerStack.length > 0;

    if (!hasContent) {
      logger.w('⚠️ DrawerAnimatedSwitcher: Drawer stack is empty');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      child: hasContent
          ? drawerStack.peek()
          : const SizedBox.shrink(),
    );
  }
}

class SignUpAnimatedSwitcher extends ConsumerWidget {
  const SignUpAnimatedSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    final signUpStack = navigationInfo.signUpNavigationStack;
    final hasContent = signUpStack != null && signUpStack.length > 0;

    if (!hasContent) {
      logger.w('⚠️ SignUpAnimatedSwitcher: SignUp stack is empty');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      child: hasContent
          ? signUpStack.peek()
          : const SizedBox.shrink(),
    );
  }
}
