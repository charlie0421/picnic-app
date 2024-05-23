import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/appinfo.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/screens/prame/prame_home_screen.dart';
import 'package:picnic_app/screens/vote/home_screen.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

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

    Widget currentScreen;

    if (navigationInfo.portalString == 'vote') {
      currentScreen = const VoteHomeScreen();
    } else if (navigationInfo.portalString == 'fan') {
      currentScreen = const PrameHomeScreen();
    } else {
      return const PrameHomeScreen();
    }

    final bool logined = ref.watch(loginedProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          width: 50.w,
          height: 50.w,
          margin: EdgeInsets.only(left: 20.w),
          child: logined
              ? GestureDetector(
                  onTap: () =>
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    ref.read(loginedProvider.notifier).setLogined(true);
                    navigationInfoNotifier.setCurrentPage(
                      const AppInfo(),
                    );
                  }),
                  child:
                      Supabase.instance.client.auth.currentUser?.userMetadata !=
                              null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50.r),
                              child: CachedNetworkImage(
                                  imageUrl: Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.userMetadata?['avatar_url']),
                            )
                          : const Icon(Icons.person),
                )
              : IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => WidgetsBinding.instance.addPostFrameCallback(
                      (timeStamp) => navigationInfoNotifier.setCurrentPage(
                            const LoginScreen(),
                          )),
                ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                navigationInfoNotifier.setPortalString('vote');
              },
              child: Row(
                children: [
                  Icon(Icons.how_to_vote,
                      color: navigationInfo.portalString == 'vote'
                          ? AppColors.GP00
                          : AppColors.Gray300),
                  Text(
                    'VOTE',
                    style: navigationInfo.portalString == 'vote'
                        ? getTextStyle(context, AppTypo.UI16B, AppColors.GP00)
                        : getTextStyle(
                            context, AppTypo.UI16, AppColors.Gray300),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20.w),
            InkWell(
              onTap: () {
                navigationInfoNotifier.setPortalString('fan');
              },
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: navigationInfo.portalString == 'fan'
                          ? AppColors.GP00
                          : AppColors.Gray300),
                  Text(
                    'FAN',
                    style: navigationInfo.portalString == 'fan'
                        ? getTextStyle(context, AppTypo.UI16B, AppColors.GP00)
                        : getTextStyle(
                            context, AppTypo.UI16, AppColors.Gray300),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: Container(),
        ),
      ),
      body: currentScreen,
    );
  }
}
