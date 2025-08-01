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

    return Row(
      mainAxisAlignment: widget.alignment,
      children: [
        Image.asset(
          package: 'picnic_lib',
          'assets/icons/store/star_100.png',
          width: 48.w,
          height: 48,
        ),
        Text(
          numberFormatter.format(starCandy),
          style: getTextStyle(AppTypo.body16B, AppColors.primary500),
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
          SizedBox(width: 8.w),
          Text(
            numberFormatter.format(starCandyBonus),
            style: getTextStyle(AppTypo.body16B, AppColors.grey500),
          ),
        ],
      ],
    );
  }
}
