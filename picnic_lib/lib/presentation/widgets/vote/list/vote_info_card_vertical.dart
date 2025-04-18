import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteCardColumnVertical extends StatelessWidget {
  const VoteCardColumnVertical({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
    this.status,
  });

  final VoteItemModel voteItem;
  final int rank;
  final Animation<double> opacityAnimation;
  final VoteStatus? status;

  @override
  Widget build(BuildContext context) {
    const width = 80.0;
    final barHeight = (rank == 1
        ? 220 * .65
        : rank == 2
            ? 220 * .50
            : 220 * .40);

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
        // 득표수 표시 (종료된 투표에만 표시)
        if (status == VoteStatus.end)
          Positioned(
            bottom: (barHeight + width * .7) + 20,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Column(
                children: [
                  Text(
                    NumberFormat('#,###').format(voteItem.voteTotal),
                    style:
                        getTextStyle(AppTypo.caption12M, AppColors.primary500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: (barHeight + width * .7),
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Text(
              t('text_vote_rank', [rank.toString()]),
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
              gradient: rank == 1
                  ? goldGradient
                  : rank == 2
                      ? silverGradient
                      : bronzeGradient,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Container(
              width: width * .9,
              height: width * .9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.grey200.withValues(alpha: 0.5),
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: PicnicCachedNetworkImage(
                      imageUrl: (voteItem.artist.id != 0
                              ? voteItem.artist.image
                              : voteItem.artistGroup.image) ??
                          '',
                      width: 100,
                      height: 100),
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
              child: Column(
                children: voteItem.artist.id != 0
                    ? [
                        Text(
                          getLocaleTextFromJson(voteItem.artist.name),
                          style: getTextStyle(
                            AppTypo.body14B,
                            AppColors.grey900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          getLocaleTextFromJson(
                              voteItem.artist.artistGroup!.name),
                          style: getTextStyle(
                            AppTypo.caption10SB,
                            AppColors.grey00,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ]
                    : voteItem.artistGroup.id != 0
                        ? [
                            Text(
                              getLocaleTextFromJson(voteItem.artistGroup.name),
                              style: getTextStyle(
                                AppTypo.body14B,
                                AppColors.grey900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]
                        : [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
