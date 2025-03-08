import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';

class NovelHomeScreen extends ConsumerWidget {
  const NovelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));
    final screenInfoAsync = ref.watch(screenInfosProvider);

    return screenInfoAsync.when(
      data: (screenInfoMap) {
        final screenInfo = screenInfoMap[PortalType.vote.name.toString()];
        if (screenInfo == null) {
          logger.w('Vote 화면 정보가 없습니다');
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          children: [
            const PicnicAnimatedSwitcher(),
            if (showBottomNavigation == true)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CommonBottomNavigationBar(),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) {
        logger.e('screenInfo 로드 중 오류 발생', error: error, stackTrace: stack);
        return const Center(
          child: Text('화면 정보를 불러오는데 실패했습니다'),
        );
      },
    );
  }
}
