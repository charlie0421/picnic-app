import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prame_app/providers/navigation_provider.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/vote_list_screen.dart';
import 'package:prame_app/ui/style.dart';

class Portal extends ConsumerStatefulWidget {
  static const String routeName = '/landing';

  const Portal({super.key});

  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    Widget currentScreen;
    if (navigationInfo.portalString == 'vote') {
      currentScreen = const VoteListScreen();
    } else if (navigationInfo.portalString == 'fan') {
      currentScreen = const HomeScreen();
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
          ],
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(0.0), // AppBar의 하단에 추가할 위젯의 높이를 0으로 설정합니다.
          child: Container(), // 빈 Container를 추가합니다.
        ),
      ),
      body: currentScreen,
    );
  }
}
