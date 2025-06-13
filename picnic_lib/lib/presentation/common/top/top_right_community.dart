import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/rotate_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/bounce_red_dot.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class TopRightCommunity extends ConsumerStatefulWidget {
  const TopRightCommunity({
    super.key,
  });

  @override
  ConsumerState<TopRightCommunity> createState() => _TopRightCommunityState();
}

class _TopRightCommunityState extends ConsumerState<TopRightCommunity> {
  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin));

    return isAdmin != null && isAdmin == true
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      isSupabaseLoggedSafely
                          ? SnackbarUtil().showSnackbar('Test')
                          : showRequireLoginDialog();
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      width: 40.w,
                      height: 36,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/calendar_style=line.svg',
                        width: 24.w,
                        height: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      isSupabaseLoggedSafely
                          ? SnackbarUtil().showSnackbar('Test')
                          : showRequireLoginDialog();
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      width: 40.w,
                      height: 36,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/calendar_style=line.svg',
                        width: 24.w,
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
                            package: 'picnic_lib',
                            'assets/icons/store/star_100.png',
                            width: 24.w,
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
                  isSupabaseLoggedSafely
                      ? SnackbarUtil().showSnackbar('Test')
                      : showRequireLoginDialog();
                },
                child: Stack(
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/alarm_style=line.svg',
                        width: 24.w,
                        height: 24,
                      ),
                    ),
                    Positioned(
                      top: 0.w,
                      right: 0.w,
                      left: 0.w,
                      bottom: 3.w,
                      child: const BounceRedDot(),
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox();
  }
}
