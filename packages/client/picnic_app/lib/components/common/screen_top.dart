import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_my_point_info.dart';
import 'package:picnic_app/components/rotate_image.dart';
import 'package:picnic_app/components/ui/bounce_red_dot.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
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
    final userInfoState = ref.watch(userInfoProvider);

    String pageName = navigationInfo.pageTitle;

    return Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          (navigationInfo.voteNavigationStack != null &&
                  navigationInfo.voteNavigationStack!.length > 1)
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    navigationInfoNotifier.goBack();
                  },
                  child: const Icon(Icons.arrow_back_ios),
                )
              : const CommonMyPoint(),
          navigationInfo.voteNavigationStack != null &&
                  navigationInfo.voteNavigationStack!.length > 1
              ? Text(
                  Intl.message(pageName),
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                )
              : const SizedBox(),
          userInfoState.when(
              data: (data) => data != null && data.is_admin
                  ? const TopScreenRight()
                  : Container(),
              loading: () => Container(),
              error: (error, stackTrace) => Container())
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
                    ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        duration: Duration(milliseconds: 300),
                        content: Text('로그인 되어 있습니다')))
                    : showRequireLoginDialog(
                        context: context,
                      );
              },
              child: Container(
                alignment: Alignment.centerLeft,
                width: 40.cw,
                height: 36,
                child: SvgPicture.asset(
                  'assets/icons/calendar_style=line.svg',
                  width: 24.cw,
                  height: 24,
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
                      width: 24.cw,
                      height: 24,
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
                ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    duration: Duration(milliseconds: 200),
                    content: Text('로그인 되어 있습니다')))
                : showRequireLoginDialog(
                    context: context,
                  );
          },
          child: Stack(
            children: [
              SizedBox(
                width: 24.cw,
                height: 24,
                child: SvgPicture.asset(
                  'assets/icons/alarm_style=line.svg',
                  width: 24.cw,
                  height: 24,
                ),
              ),
              Positioned(
                top: 0.cw,
                right: 0.cw,
                left: 0.cw,
                bottom: 3.cw,
                child: const BounceRedDot(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
