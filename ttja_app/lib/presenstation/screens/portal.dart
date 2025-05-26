import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/top/top_menu.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class Portal extends ConsumerStatefulWidget {
  static const String routeName = '/landing';

  const Portal({super.key});

  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  @override
  Widget build(BuildContext context) {
    final currentScreen = ref
        .watch(navigationInfoProvider.select((value) => value.currentScreen));
    final showTopMenu =
        ref.watch(navigationInfoProvider.select((value) => value.showTopMenu));
    final userInfoState = ref.watch(userInfoProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: commonGradient,
      ),
      child: FixedWidthLayout(
        child: Scaffold(
          drawerEnableOpenDragGesture: false,
          drawer: const Drawer(
            width: double.infinity,
            child: MyPageScreen(),
          ),
          appBar: AppBar(
            toolbarHeight: ref.watch(
                    navigationInfoProvider.select((value) => value.showPortal))
                ? 56
                : 0,
            leading: Builder(
              builder: (BuildContext context) {
                return Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: supabase.isLogged
                      ? userInfoState.when(
                          data: (data) => data != null
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: ProfileImageContainer(
                                    avatarUrl: data.avatarUrl,
                                    width: 36,
                                    height: 36,
                                    borderRadius: 8.r,
                                  ))
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      Scaffold.of(context).openDrawer(),
                                  child: const DefaultAvatar()),
                          error: (error, stackTrace) => const Icon(Icons.error),
                          loading: () => SizedBox(
                            width: 36,
                            height: 36,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: buildPlaceholderImage()),
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: const DefaultAvatar(),
                        ),
                );
              },
            ),
            leadingWidth: 52.w,
            titleSpacing: 0,
            actions: [
              SvgPicture.asset(
                'assets/top_logo.svg',
                width: 36.w,
                height: 15,
              ),
              SizedBox(width: 16.w),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return kIsWeb
                  ? Center(
                      child: SizedBox(
                      width: webDesignSize.width,
                      child: Column(children: [
                        if (showTopMenu) const TopMenu(),
                        Expanded(
                            child: currentScreen ?? const VoteHomeScreen()),
                      ]),
                    ))
                  : SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Column(children: [
                        if (showTopMenu) const TopMenu(),
                        Expanded(
                            child: currentScreen ?? const VoteHomeScreen()),
                      ]),
                    );
            },
          ),
        ),
      ),
    );
  }
}
