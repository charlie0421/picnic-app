import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/top/top_menu.dart';
import 'package:picnic_lib/presentation/common/top/top_right_notifications.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';
import 'package:picnic_lib/presentation/widgets/ui/popup_carousel.dart';
import 'package:picnic_lib/presentation/common/scaffold_key.dart';

class Portal extends ConsumerStatefulWidget {
  static const String routeName = '/landing';

  const Portal({super.key});

  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  @override
  Widget build(BuildContext context) {
    final navigationNotifier = ref.watch(navigationInfoProvider.notifier);
    final showTopMenu = ref.watch(
      navigationInfoProvider.select((value) => value.showTopMenu),
    );
    final userInfoState = ref.watch(userInfoProvider);
    return Container(
      decoration: BoxDecoration(gradient: commonGradient),
      child: FixedWidthLayout(
        child: Scaffold(
          key: scaffoldKey,
          drawerEnableOpenDragGesture: false,
          drawer: const Drawer(width: double.infinity, child: MyPageScreen()),
          appBar: AppBar(
            toolbarHeight:
                ref.watch(
                  navigationInfoProvider.select((value) => value.showPortal),
                )
                ? 56
                : 0,
            leading: Builder(
              builder: (BuildContext context) {
                return Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: userInfoState.when(
                    data: (data) => data != null
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: ProfileImageContainer(
                              avatarUrl: data.avatarUrl,
                              width: 40,
                              height: 40,
                              borderRadius: 8.r,
                            ),
                          )
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: const DefaultAvatar(),
                          ),
                    error: (error, stackTrace) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: const DefaultAvatar(),
                    ),
                    loading: () => SizedBox(
                      width: 36,
                      height: 36,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: buildPlaceholderImage(),
                      ),
                    ),
                  ),
                );
              },
            ),
            leadingWidth: 56.w,
            titleSpacing: 0,
            centerTitle: true,
            title: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 앱 워드마크 로고 (중앙 정렬)
                  SvgPicture.asset(
                    'assets/images/fortune/picnic_logo.svg',
                    package: 'picnic_lib',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  if (Environment.currentEnvironment == 'dev') ...[
                    SizedBox(width: 8.w),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        child: Text(
                          'STAGING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [TopRightNotifications()],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final mainContent = kIsWeb
                  ? Center(
                      child: SizedBox(
                        width: webDesignSize.width,
                        child: Column(
                          children: [
                            if (showTopMenu) const TopMenu(),
                            Expanded(child: navigationNotifier.getScreen()),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          if (showTopMenu) const TopMenu(),
                          Expanded(child: navigationNotifier.getScreen()),
                        ],
                      ),
                    );
              return Stack(children: [mainContent, const PopupCarousel()]);
            },
          ),
        ),
      ),
    );
  }
}
