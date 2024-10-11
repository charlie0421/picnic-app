import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/components/common/top/top_right_common.dart';
import 'package:picnic_app/components/common/top/top_right_post.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/ui.dart';

class TopMenu extends ConsumerStatefulWidget {
  const TopMenu({
    super.key,
  });

  @override
  ConsumerState<TopMenu> createState() => _TopState();
}

class _TopState extends ConsumerState<TopMenu> {
  @override
  void initState() {
    super.initState();
    // _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);

    return Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 10),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: (navigationInfo.voteNavigationStack != null &&
                    navigationInfo.voteNavigationStack!.length > 1)
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      navigationInfoNotifier.goBack();
                    },
                    child: SizedBox(
                      width: 24.cw,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left_style=line.svg',
                        width: 24.cw,
                        height: 24,
                      ),
                    ),
                  )
                : const CommonMyPoint(),
          ),
          Positioned.fill(
              right: 0,
              top: 0,
              bottom: 0,
              child: navigationInfo.topRightMenu == TopRightType.none
                  ? Container()
                  : navigationInfo.topRightMenu == TopRightType.common
                      ? const TopRightCommon()
                      : const TopRightPost()),
        ],
      ),
    );
  }
}
