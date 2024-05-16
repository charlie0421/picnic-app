import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/screens/developer/developer_home_screen.dart';
import 'package:picnic_app/screens/prame/prame_home_screen.dart';
import 'package:picnic_app/screens/vote/home_screen.dart';
import 'package:picnic_app/ui/style.dart';

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
    } else if (navigationInfo.portalString == 'developer') {
      currentScreen = const DeveloperHomeScreen();
    } else {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
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
            SizedBox(width: 20.w),
            InkWell(
              onTap: () {
                navigationInfoNotifier.setPortalString('developer');
              },
              child: Row(
                children: [
                  Icon(Icons.developer_mode,
                      color: navigationInfo.portalString == 'developer'
                          ? AppColors.GP00
                          : AppColors.Gray300),
                  Text(
                    'DEV',
                    style: navigationInfo.portalString == 'developer'
                        ? getTextStyle(context, AppTypo.UI16B, AppColors.GP00)
                        : getTextStyle(
                            context, AppTypo.UI16, AppColors.Gray300),
                  ),
                ],
              ),
            ),
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
