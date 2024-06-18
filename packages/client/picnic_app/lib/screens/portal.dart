import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/portal_menu_item.dart';
import 'package:picnic_app/components/common/screen_top.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/screens/mypage_screen.dart';
import 'package:picnic_app/ui/style.dart';
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
    final currentScreen = ref.watch(navigationInfoProvider.select((value) {
      return value.currentScreen;
    }));
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);
    final userInfo = ref.watch(userInfoProvider);

    final bool logined = ref.watch(loginedProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const Drawer(
        width: double.infinity,
        child: MyPageScreen(),
      ),
      appBar: AppBar(
        leading: Container(
          width: 36.w,
          height: 36.w,
          alignment: Alignment.center,
          child: Builder(
            builder: (context) => logined
                ? userInfo.when(
                    data: (data) => data != null
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              alignment: Alignment.center,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: CachedNetworkImage(
                                  imageUrl: data.avatar_url ?? '',
                                  placeholder: (context, url) =>
                                      buildPlaceholderImage(),
                                  width: 36.w,
                                  height: 36.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : const DefaultAvatar(),
                    error: (error, stackTrace) => const Icon(Icons.error),
                    loading: () => SizedBox(
                      width: 36.w,
                      height: 36.w,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: buildPlaceholderImage()),
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => navigationInfoNotifier.setCurrentPage(
                      const LoginScreen(),
                    ),
                    child: const DefaultAvatar(),
                  ),
          ),
        ),
        leadingWidth: 52.w,
        titleSpacing: 0,
        title: SizedBox(
          height: 26.w,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(
                height: 26.w,
                width: MediaQuery.of(context).size.width,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    PortalMenuItem(portalType: PortalType.vote),
                    PortalMenuItem(portalType: PortalType.pic),
                    PortalMenuItem(portalType: PortalType.community),
                    PortalMenuItem(portalType: PortalType.novel),
                  ],
                ),
              ),
            ],
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

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      padding: const EdgeInsets.all(6).r,
      decoration: BoxDecoration(
        color: AppColors.Grey200,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: SvgPicture.asset(
        'assets/icons/header/default_avatar.svg',
        width: 24.w,
        height: 24.w,
        colorFilter: const ColorFilter.mode(
          AppColors.Grey00,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
