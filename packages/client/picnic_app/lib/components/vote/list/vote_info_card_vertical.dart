import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';

class VoteCardColumnVertical extends StatelessWidget {
  const VoteCardColumnVertical({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
  });

  final VoteItemModel voteItem;
  final int rank;
  final Animation<double> opacityAnimation;

  @override
  Widget build(
    BuildContext context,
  ) {
    final width = kIsWeb
        ? webDesignSize.width / 4.5
        : MediaQuery.of(context).size.width / 5.5;
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
              Intl.message('text_vote_rank', args: [rank]).toString(),
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
                  color: AppColors.grey00,
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: PicnicCachedNetworkImage(
                      imageUrl: voteItem.artist.image,
                      useScreenUtil: true,
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
                children: [
                  Text(
                    getLocaleTextFromJson(voteItem.artist.name),
                    style: getTextStyle(
                      AppTypo.body14B,
                      AppColors.grey900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    getLocaleTextFromJson(voteItem.artist.artist_group.name),
                    style: getTextStyle(
                      AppTypo.caption10SB,
                      AppColors.grey00,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
