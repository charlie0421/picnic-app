import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/util.dart';

class StarCandyInfoText extends ConsumerStatefulWidget {
  final MainAxisAlignment alignment;

  const StarCandyInfoText({
    super.key,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  _StarCandyInfoTextState createState() => _StarCandyInfoTextState();
}

class _StarCandyInfoTextState extends ConsumerState<StarCandyInfoText> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final starCandy = ref.watch(
        userInfoProvider.select((value) => value.value?.star_candy ?? 0));
    final starCandyBonus = ref.watch(
        userInfoProvider.select((value) => value.value?.star_candy_bonus ?? 0));

    String firstPart = '';
    String secondPart = '';

    if (Intl.getCurrentLocale() == 'ko') {
      firstPart = '${numberFormatter.format(starCandy)}개';
      secondPart = ' +${numberFormatter.format(starCandyBonus)}개 보너스';
    } else if (Intl.getCurrentLocale() == 'en') {
      firstPart = numberFormatter.format(starCandy);
      secondPart = ' +${numberFormatter.format(starCandyBonus)} bonus';
    } else if (Intl.getCurrentLocale() == 'ja') {
      firstPart = '${numberFormatter.format(starCandy)}個';
      secondPart = ' +${numberFormatter.format(starCandyBonus)}個ボーナス';
    } else if (Intl.getCurrentLocale() == 'zh') {
      firstPart = numberFormatter.format(starCandy);
      secondPart = ' +${numberFormatter.format(starCandyBonus)} 奖金';
    }
    return Container(
      child: Row(
        mainAxisAlignment: widget.alignment,
        children: [
          Image.asset(
            'assets/icons/store/star_100.png',
            width: 48.w,
            height: 48,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: firstPart,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
                if (starCandyBonus > 0)
                  TextSpan(
                    text: secondPart,
                    style: getTextStyle(AppTypo.body16B, AppColors.primary500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
