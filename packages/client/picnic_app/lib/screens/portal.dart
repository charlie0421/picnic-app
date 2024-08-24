import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/portal_menu_item.dart';
import 'package:picnic_app/components/common/screen_top.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/mypage_screen.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/util/ui.dart';
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
    final userInfoState = ref.watch(userInfoProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: commonGradient,
      ),
      child: Scaffold(
        drawerEnableOpenDragGesture: false,
        drawer: const Drawer(
          width: double.infinity,
          child: MyPageScreen(),
        ),
        appBar: AppBar(
          toolbarHeight: ref.watch(
                  navigationInfoProvider.select((value) => value.showTopMenu))
              ? 56.h
              : 0,
          leading: Builder(
            builder: (BuildContext context) {
              return Container(
                width: 24,
                height: 24,
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
                                  avatarUrl: data.avatar_url,
                                  width: 36.w,
                                  height: 36,
                                  borderRadius: 8.r,
                                ))
                            : const DefaultAvatar(),
                        error: (error, stackTrace) => const Icon(Icons.error),
                        loading: () => SizedBox(
                          width: 36.w,
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
          title: Container(
            height: 26,
            padding: EdgeInsets.only(right: 24.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (Environment.currentEnvironment != 'prod')
                    Text(Environment.currentEnvironment),
                  const PortalMenuItem(portalType: PortalType.vote),
                  if (supabase.isLogged)
                    userInfoState.when(
                      data: (userInfo) {
                        if (userInfo != null && userInfo.is_admin) {
                          return const Row(children: [
                            PortalMenuItem(portalType: PortalType.pic),
                            PortalMenuItem(portalType: PortalType.community),
                            PortalMenuItem(portalType: PortalType.novel),
                          ]);
                        } else {
                          return Container();
                        }
                      },
                      error: (error, stackTrace) => const Icon(Icons.error),
                      loading: () => const SizedBox(),
                    ),
                ],
              ),
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return kIsWeb
                ? Center(
                    child: SizedBox(
                    width: webDesignSize.width,
                    child: Column(children: [
                      if (supabase.isLogged) const ScreenTop(),
                      Expanded(child: currentScreen),
                    ]),
                  ))
                : SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(children: [
                      if (supabase.isLogged) const ScreenTop(),
                      Expanded(child: currentScreen),
                    ]),
                  );
          },
        ),
      ),
    );
  }
}
