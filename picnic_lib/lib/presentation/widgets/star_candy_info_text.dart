import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class StarCandyInfoText extends ConsumerStatefulWidget {
  final MainAxisAlignment alignment;

  const StarCandyInfoText({
    super.key,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  ConsumerState<StarCandyInfoText> createState() => _StarCandyInfoTextState();
}

class _StarCandyInfoTextState extends ConsumerState<StarCandyInfoText> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final starCandy = ref
        .watch(userInfoProvider.select((value) => value.value?.starCandy ?? 0));
    final starCandyBonus = ref.watch(
        userInfoProvider.select((value) => value.value?.starCandyBonus ?? 0));

    String firstPart = '';
    String secondPart = '';

    String currentLocale = Localizations.localeOf(context).languageCode;

    if (currentLocale == 'ko') {
      firstPart = '${numberFormatter.format(starCandy)}';
      secondPart = '';
    } else if (currentLocale == 'en') {
      firstPart = numberFormatter.format(starCandy);
      secondPart = '';
    } else if (currentLocale == 'ja') {
      firstPart = '${numberFormatter.format(starCandy)}';
      secondPart = '';
    } else if (currentLocale == 'zh') {
      firstPart = numberFormatter.format(starCandy);
      secondPart = '';
    } else if (currentLocale == 'id') {
      firstPart = numberFormatter.format(starCandy);
      secondPart = '';
    } else {
      // 기본값: 영어 형식
      firstPart = numberFormatter.format(starCandy);
      secondPart = '';
    }
    return Row(
      mainAxisAlignment: widget.alignment,
      children: [
        Image.asset(
          package: 'picnic_lib',
          'assets/icons/store/star_100.png',
          width: 48.w,
          height: 48,
        ),
        SizedBox(width: 4.w),
        Text(
          firstPart,
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        ),
        if (starCandyBonus > 0) ...[
          SizedBox(width: 8.w),
          Text(
            '+',
            style: getTextStyle(AppTypo.body16B, AppColors.primary500),
          ),
          SizedBox(width: 8.w),
          Image.asset(
            'assets/icons/store/bonus.png',
            width: 24.w,
            height: 24.w,
            package: 'picnic_lib',
          ),
          SizedBox(width: 4.w),
          Text(
            '${numberFormatter.format(starCandyBonus)}',
            style: getTextStyle(AppTypo.body16B, AppColors.primary500),
          ),
        ],
      ],
    );
  }
}
