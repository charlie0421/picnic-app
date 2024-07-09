import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/portal_menu_item.dart';
import 'package:picnic_app/components/common/screen_top.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/screens/mypage_screen.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

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
    final userInfo = ref.watch(userInfoProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: commonGradient,
      ),
      child: Center(
        child: Container(
          color: voteMainColor,
          constraints: BoxConstraints(
            maxWidth: getPlatformScreenSize(context).width,
            minWidth: getPlatformScreenSize(context).width,
            minHeight: getPlatformScreenSize(context).height,
            // maxHeight: getPlatformScreenSize(context).height
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            drawer: const Drawer(
              width: double.infinity,
              child: MyPageScreen(),
            ),
            appBar: AppBar(
              toolbarHeight: ref.watch(navigationInfoProvider
                      .select((value) => value.showTopMenu))
                  ? 56.h
                  : 0,
              leading: Container(
                width: 24.w,
                height: 24.w,
                alignment: Alignment.center,
                child: Builder(
                  builder: (context) => supabase.isLogged
                      ? userInfo.when(
                          data: (data) => data != null
                              ? GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: Container(
                                    width: 24.w,
                                    height: 24.w,
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: data.avatar_url!.contains('https')
                                          ? CachedNetworkImage(
                                              imageUrl: data.avatar_url ?? '',
                                              width: 24.w,
                                              height: 24.w,
                                              fit: BoxFit.cover,
                                            )
                                          : PicnicCachedNetworkImage(
                                              imageUrl: data.avatar_url ?? '',
                                              width: 24.w,
                                              height: 24.w,
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
                          onTap: () => Navigator.of(context)
                              .pushNamed(LoginScreen.routeName),
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
                      width: getPlatformScreenSize(context).width,
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
                const ScreenTop(),
                Expanded(child: currentScreen),
              ],
            ),
          ),
        ),
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
