import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/bounce_red_dot.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/components/rotate_image.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/signup/login_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

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
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
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
          const TopScreenRight(),
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
//   final subscription = supabase
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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                supabase.isLogged
                    ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: const Duration(milliseconds: 300),
                        content: Text('로그인 되어 있습니다')))
                    : showSimpleDialog(
                        context: context,
                        content: S.of(context).dialog_content_login_required,
                        onOk: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, LoginPage.routeName);
                        },
                        onCancel: () => Navigator.pop(context),
                      );
              },
              child: Container(
                alignment: Alignment.centerLeft,
                width: 40.w,
                height: 36.h,
                child: SvgPicture.asset(
                  'assets/icons/calendar_style=line.svg',
                  width: 24.w,
                  height: 24.h,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                children: [
                  RotationImage(
                    image: Image.asset(
                      'assets/icons/store/star_100.png',
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            supabase.isLogged
                ? ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: const Duration(milliseconds: 200),
                    content: Text('로그인 되어 있습니다')))
                : showSimpleDialog(
                    context: context,
                    content: S.of(context).dialog_content_login_required,
                    onOk: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, LoginPage.routeName);
                    },
                    onCancel: () => Navigator.pop(context),
                  );
          },
          child: Stack(
            children: [
              Container(
                width: 24.w,
                height: 24.h,
                child: SvgPicture.asset(
                  'assets/icons/alarm_style=line.svg',
                  width: 24.w,
                  height: 24.h,
                ),
              ),
              Positioned(
                top: 0.w,
                right: 0.w,
                left: 0.w,
                bottom: 3.w,
                child: BounceRedDot(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
