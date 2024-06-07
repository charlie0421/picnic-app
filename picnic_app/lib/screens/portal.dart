import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/portal_menu_item.dart';
import 'package:picnic_app/components/common/screen_top.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/common/mypage.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/util.dart';

class Portal extends ConsumerStatefulWidget {
  static const String routeName = '/landing';

  const Portal({super.key});

  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);
    final userInfo = ref.watch(userInfoProvider);

    Widget currentScreen = navigationInfo.currentScreen;

    final bool logined = ref.watch(loginedProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: logined
            ? userInfo.when(
                data: (data) => data != null
                    ? GestureDetector(
                        onTap: () =>
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                          navigationInfoNotifier.setCurrentPage(
                            const MyPage(),
                          );
                        }),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          padding: EdgeInsets.all(16.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: data.avatar_url ?? '',
                              placeholder: (context, url) =>
                                  buildPlaceholderImage(),
                              width: 40.w,
                              height: 40.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : const Icon(Icons.person),
                error: (error, stackTrace) => const Icon(Icons.error),
                loading: () => Container(
                  width: 40.w,
                  height: 40.w,
                  padding: EdgeInsets.all(16.w),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: buildPlaceholderImage()),
                ),
              )
            : GestureDetector(
                onTap: () =>
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  navigationInfoNotifier.setCurrentPage(
                    const LoginScreen(),
                  );
                }),
                child: const Icon(Icons.person),
              ),
        title: SizedBox(
          width: double.infinity,
          child: SizedBox(
            height: 24.h,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const PortalMenuItem(portalType: PortalType.vote),
                      SizedBox(width: 20.w),
                      const PortalMenuItem(portalType: PortalType.pic),
                      SizedBox(width: 20.w),
                      const PortalMenuItem(portalType: PortalType.community),
                      SizedBox(width: 20.w),
                      const PortalMenuItem(portalType: PortalType.novel),
                      SizedBox(width: 20.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (ref.watch(
              navigationInfoProvider.select((value) => value.showTopMenu)))
            const ScreenTop(),
          Expanded(child: currentScreen),
        ],
      ),
    );
  }
}
