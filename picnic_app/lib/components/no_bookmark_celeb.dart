import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/ui/style.dart';

class NoBookmarkCeleb extends ConsumerStatefulWidget {
  const NoBookmarkCeleb({
    super.key,
  });

  @override
  ConsumerState<NoBookmarkCeleb> createState() => _NoBookmarkCelebState();
}

class _NoBookmarkCelebState extends ConsumerState<NoBookmarkCeleb> {
  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingProvider);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/landing/no_celeb.svg',
              width: 60.w,
              height: 60.w,
              colorFilter:
                  const ColorFilter.mode(Color(0xFFB7B7B7), BlendMode.srcIn)),
          SizedBox(height: 8.w),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              S.of(context).label_no_celeb,
              textAlign: TextAlign.center,
              style: getTextStyle(AppTypo.TITLE18M, AppColors.Grey300),
            ),
          )
        ],
      ),
    );
  }
}
