import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/pic/artist_vote.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

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
        ? 240.w
        : rank == 2
            ? 200.w
            : 160.w;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: AppColors.Grey00,
          width: double.infinity,
          child: SizedBox(
            width: barWidth.w,
            height: 50.w,
          ),
        ),
        Positioned(
          width: barWidth,
          child: Container(
            width: barWidth.w,
            height: 50.w,
            decoration: const BoxDecoration(
              gradient: commonGradientReverse,
            ),
          ),
        ),
        Positioned(
          left: barWidth + 50.w,
          height: 50.w,
          child: Align(
            alignment: Alignment.centerRight,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Text(
                Intl.message('text_vote_rank', args: [rank]).toString(),
                style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10.w,
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
                    AppTypo.BODY14B,
                    AppColors.Grey900,
                  ),
                ),
                Text(
                  getLocaleTextFromJson(voteItem.description),
                  style: getTextStyle(
                    AppTypo.CAPTION10SB,
                    AppColors.Grey00,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: barWidth - 25.w,
          child: Container(
            width: 50.w,
            height: 50.w,
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
              width: 42.w,
              height: 42.w,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppColors.Grey200,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.Grey00,
                  width: 1.w,
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
