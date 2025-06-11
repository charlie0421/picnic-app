// ignore_for_file: unused_import, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/common_bottom_navigation_bar.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';

class NovelHomeScreen extends ConsumerWidget {
  const NovelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBottomNavigation = ref.watch(
        navigationInfoProvider.select((value) => value.showBottomNavigation));

    return Stack(
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
    );
  }
}
