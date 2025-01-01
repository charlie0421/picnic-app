import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/presentation/widgets/rotate_image.dart';
import 'package:picnic_app/presentation/widgets/ui/bounce_red_dot.dart';
import 'package:picnic_app/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_app/presentation/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/core/utils/snackbar_util.dart';
import 'package:picnic_app/core/utils/ui.dart';
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
                      supabase.isLogged
                          ? SnackbarUtil().showSnackbar('Test')
                          : showRequireLoginDialog();
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
                  GestureDetector(
                    onTap: () {
                      supabase.isLogged
                          ? SnackbarUtil().showSnackbar('Test')
                          : showRequireLoginDialog();
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
                      ? SnackbarUtil().showSnackbar('Test')
                      : showRequireLoginDialog();
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
          )
        : const SizedBox();
  }
}
