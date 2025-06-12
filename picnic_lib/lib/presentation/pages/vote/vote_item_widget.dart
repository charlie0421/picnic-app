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
          child: Container(
            constraints:
                BoxConstraints(minHeight: 55), // 45에서 55로 증가하여 오버플로우 해결
            padding: EdgeInsets.symmetric(vertical: 6.h), // 패딩도 약간 증가
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 39,
                  height: 45, // 높이를 다시 줄임 (크라운만 표시하므로)
                  child: Center(
                    child: actualRank <= 3
                        ? SvgPicture.asset(
                            package: 'picnic_lib',
                            'assets/icons/vote/crown$actualRank.svg',
                            height: 24, // 크라운 크기를 더 크게 하여 잘 보이게
                            width: 24,
                          )
                        : Text(
                            actualRank.toString(), // 4위 이하는 숫자만 표시
                            style: getTextStyle(
                                AppTypo.body16B, AppColors.point900), // 더 큰 폰트
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                SizedBox(width: 8.w),
                artistImage,
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // 2에서 1로 변경
                        text: TextSpan(
                            children: (item.artist?.id ?? 0) != 0
                                ? [
                                    TextSpan(
                                      text: getLocaleTextFromJson(
                                          item.artist?.name ?? {}),
                                      style: getTextStyle(
                                          AppTypo.body14B, AppColors.grey900),
                                    ),
                                    // 그룹명을 괄호 안에 작게 표시
                                    if (item.artist?.artistGroup?.name != null)
                                      TextSpan(
                                        text: ' (',
                                        style: getTextStyle(AppTypo.caption10SB,
                                            AppColors.grey600),
                                      ),
                                    if (item.artist?.artistGroup?.name != null)
                                      TextSpan(
                                        text: getLocaleTextFromJson(
                                            item.artist!.artistGroup!.name),
                                        style: getTextStyle(AppTypo.caption10SB,
                                            AppColors.grey600),
                                      ),
                                    if (item.artist?.artistGroup?.name != null)
                                      TextSpan(
                                        text: ')',
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
                      SizedBox(height: 4.h), // 간격 유지
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
