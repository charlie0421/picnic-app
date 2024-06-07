import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            color: AppColors.Gray500.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          navigationInfo.navigationStack != null &&
                  navigationInfo.navigationStack!.length > 1
              ? GestureDetector(
                  onTap: () {
                    navigationInfoNotifier.goBack();
                  },
                  child: const Icon(Icons.arrow_back_ios),
                )
              : const CommonMyPoint(),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/header/daily_check.svg',
                width: 24.w,
                height: 24.h,
              ),
              Divider(
                color: AppColors.Gray900,
                thickness: 1.r,
                indent: 16.w,
              ),
              SvgPicture.asset(
                'assets/icons/header/alarm.svg',
                width: 24.w,
                height: 24.h,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void handleUserInfo(PostgresChangePayload payload) {
    logger.d('Change received! $payload');
    int starCandy = payload.newRecord['star_candy'];
    logger.d('Star candy: $starCandy');
    ref.read(userInfoProvider.notifier).setStarCandy(starCandy);
  }

  void _setupRealtime() {
    final subscription = Supabase.instance.client
        .channel('realtime')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_profiles',
            callback: handleUserInfo)
        .subscribe((status, payload) {
      logger.d(status);
    }, const Duration(seconds: 1));
  }
}
