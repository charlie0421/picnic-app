import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteCardColumnAchieve extends StatelessWidget {
  const VoteCardColumnAchieve({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
  });

  final VoteItemModel voteItem;
  final VoteAchieve rank;
  final Animation<double> opacityAnimation;

  @override
  Widget build(
    BuildContext context,
  ) {
    const width = 50.0;
    final isAchieve = voteItem.voteTotal! >= rank.amount;
    final barHeight = isAchieve ? rank.order * 20.0 + 60 : 60.0;
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: width,
          height: barHeight,
        ),
        Positioned(
          bottom: 0,
          width: width,
          height: barHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: commonGradient,
            ),
          ),
        ),
        Positioned(
          bottom: (barHeight + width * .7),
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Text(
              isAchieve ? '${AppLocalizations.of(context).achieve}!' : '',
              style: getTextStyle(AppTypo.caption12B, AppColors.point900),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: (barHeight - width * .4),
          child: Container(
            width: width,
            height: width,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isAchieve ? goldGradient : silverGradient,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Container(
              width: width * .9,
              height: width * .9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.grey00,
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      // `thumbnail` 은 운영자가 이미지를 안 올리면 실제로 null
                      // 인 순수 nullable 컬럼(`RewardModel.thumbnail`)이다.
                      // 단언하면 달성 카드 전체가 에러 박스로 바뀐다.
                      // reward_dialog.dart / reward_list_section.dart 와 같은
                      // 처리로 맞춘다.
                      child: PicnicCachedNetworkImage(
                          imageUrl: rank.reward.thumbnail ?? '',
                          width: 100,
                          height: 100),
                    ),
                    if (!isAchieve)
                      Positioned(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.grey200.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: SizedBox(
              width: width,
              child: Column(children: [
                Text(
                  '${AppLocalizations.of(context).reward} ${rank.order}',
                  style: getTextStyle(
                    AppTypo.caption10SB,
                    AppColors.grey00,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
