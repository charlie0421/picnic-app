import 'package:flutter/material.dart';
import 'package:picnic_app/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/data/models/vote/vote.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';

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
            decoration: const BoxDecoration(
              gradient: commonGradient,
            ),
          ),
        ),
        Positioned(
          bottom: (barHeight + width * .7),
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Text(
              isAchieve ? '{$S.of(context).achieve}!' : '',
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
                  width: 1.cw,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: PicnicCachedNetworkImage(
                          imageUrl: rank.reward.thumbnail!,
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
                  '${S.of(context).reward}${rank.order}',
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
