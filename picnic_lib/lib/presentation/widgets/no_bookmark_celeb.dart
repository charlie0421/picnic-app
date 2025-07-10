import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/ui/style.dart';

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
          SvgPicture.asset(
              package: 'picnic_lib',
              'assets/landing/no_celeb.svg',
              width: 60.w,
              height: 60,
              colorFilter:
                  const ColorFilter.mode(Color(0xFFB7B7B7), BlendMode.srcIn)),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context).label_no_celeb,
              textAlign: TextAlign.center,
              style: getTextStyle(AppTypo.title18M, AppColors.grey300),
            ),
          )
        ],
      ),
    );
  }
}
