import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/l10n.dart';

class VoteItemWidget extends StatelessWidget {
  final VoteItemModel item;
  final int index;
  final int actualRank;
  final int voteCountDiff;
  final bool rankChanged;
  final bool rankUp;
  final bool isEnded;
  final bool isSaving;
  final VoidCallback onTap;
  final Widget artistImage;
  final Widget voteCountContainer;
  final String rankText;

  const VoteItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.actualRank,
    required this.voteCountDiff,
    required this.rankChanged,
    required this.rankUp,
    required this.isEnded,
    required this.isSaving,
    required this.onTap,
    required this.artistImage,
    required this.voteCountContainer,
    required this.rankText,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: rankChanged
              ? (rankUp
                  ? Colors.blue.withValues(alpha: 0.18)
                  : Colors.red.withValues(alpha: 0.18))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 45,
            child: Row(
              children: [
                SizedBox(
                  width: 39,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (actualRank <= 3)
                        SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/vote/crown$actualRank.svg',
                        ),
                      Text(
                        rankText,
                        style: getTextStyle(
                            AppTypo.caption12B, AppColors.point900),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                artistImage,
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            children: (item.artist?.id ?? 0) != 0
                                ? [
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artist?.name ?? {}),
                                      style: getTextStyle(
                                          AppTypo.body14B, AppColors.grey900),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text: item.artist?.artistGroup?.name !=
                                              null
                                          ? getLocaleTextFromJson(
                                              item.artist!.artistGroup!.name)
                                          : '',
                                      style: getTextStyle(AppTypo.caption10SB,
                                          AppColors.grey600),
                                    ),
                                  ]
                                : [
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artistGroup?.name ?? {}),
                                      style: getTextStyle(
                                          AppTypo.body14B, AppColors.grey900),
                                    ),
                                  ]),
                      ),
                      voteCountContainer,
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                if (!isEnded && !isSaving)
                  SizedBox(
                    width: 24.w,
                    height: 24,
                    child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/star_candy_icon.svg'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
