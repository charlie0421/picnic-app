import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class VoteCardColumnHorizontal extends StatelessWidget {
  const VoteCardColumnHorizontal({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
  });

  final ArtistVoteItemModel voteItem;
  final int rank;
  final Animation<double> opacityAnimation;

  @override
  Widget build(
    BuildContext context,
  ) {
    final barWidth = rank == 1
        ? 240.cw
        : rank == 2
            ? 200.cw
            : 160.cw;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: AppColors.grey00,
          width: double.infinity,
          child: SizedBox(
            width: barWidth.cw,
            height: 50,
          ),
        ),
        Positioned(
          width: barWidth,
          child: Container(
            width: barWidth.cw,
            height: 50,
            decoration: const BoxDecoration(
              gradient: commonGradientReverse,
            ),
          ),
        ),
        Positioned(
          left: barWidth + 50.cw,
          height: 50,
          child: Align(
            alignment: Alignment.centerRight,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Text(
                Intl.message('text_vote_rank', args: [rank]).toString(),
                style: getTextStyle(AppTypo.caption12B, AppColors.point900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10.cw,
          top: 0,
          bottom: 0,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getLocaleTextFromJson(voteItem.title),
                  style: getTextStyle(
                    AppTypo.body14B,
                    AppColors.grey900,
                  ),
                ),
                Text(
                  getLocaleTextFromJson(voteItem.description),
                  style: getTextStyle(
                    AppTypo.caption10SB,
                    AppColors.grey00,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: barWidth - 25.cw,
          child: Container(
            width: 50.cw,
            height: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? goldGradient
                  : rank == 2
                      ? silverGradient
                      : bronzeGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Container(
              width: 42.cw,
              height: 42,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.grey00,
                  width: 1.cw,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
