import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

class ScreenTop extends ConsumerStatefulWidget {
  const ScreenTop({
    super.key,
  });

  @override
  ConsumerState<ScreenTop> createState() => _TopState();
}

class _TopState extends ConsumerState<ScreenTop> {
  @override
  void initState() {
    super.initState();
    // _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);
    final appSetting = ref.watch(appSettingProvider);

    String pageName;
    try {
      pageName =
          (navigationInfo.topNavigationStack!.peek() as dynamic).pageName;
    } catch (e) {
      if (e is NoSuchMethodError) {
        pageName = '';
      } else {
        rethrow;
      }
    }
    return Container(
      height: 54.w,
      padding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            color: AppColors.Grey500.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          (navigationInfo.topNavigationStack != null &&
                  navigationInfo.topNavigationStack!.length > 1)
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    navigationInfoNotifier.goBack();
                  },
                  child: const Icon(Icons.arrow_back_ios),
                )
              : const CommonMyPoint(),
          navigationInfo.topNavigationStack != null &&
                  navigationInfo.topNavigationStack!.length > 1
              ? Text(
                  Intl.message(pageName),
                  style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                )
              : const SizedBox(),
          TopScreenRight(),
        ],
      ),
    );
  }

// void handleUserInfo(PostgresChangePayload payload) {
//   logger.d('Change received! $payload');
//   int starCandy = payload.newRecord['star_candy'];
//   logger.d('Star candy: $starCandy');
//   ref.read(userInfoProvider.notifier).setStarCandy(starCandy);
// }
//
// void _setupRealtime() {
//   final subscription = Supabase.instance.client
//       .channel('realtime')
//       .onPostgresChanges(
//           event: PostgresChangeEvent.update,
//           schema: 'public',
//           table: 'user_profiles',
//           callback: handleUserInfo)
//       .subscribe((status, payload) {
//     logger.d(status);
//   }, const Duration(seconds: 1));
// }
}

class TopScreenRight extends StatelessWidget {
  const TopScreenRight({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/icons/calendar_style=line.svg',
          width: 24.w,
          height: 24.w,
        ),
        Divider(
          color: AppColors.Grey900,
          thickness: 1.r,
          indent: 16.w,
        ),
        SvgPicture.asset(
          'assets/icons/alarm_style=line.svg',
          width: 24.w,
          height: 24.w,
        ),
      ],
    );
  }
}
