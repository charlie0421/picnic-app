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

  /// The bar the reward label is drawn on. Exposed so tests can check the
  /// label stays on it: above the bar it is white text on a white card.
  @visibleForTesting
  static const barKey = ValueKey('vote_card_column_achieve.bar');

  /// The slot the "achieved!" label is fitted into.
  @visibleForTesting
  static const achievedLabelKey = ValueKey(
    'vote_card_column_achieve.achieved_label',
  );

  /// Width the "achieved!" label may use: the 50px bar plus a share of the
  /// gaps. Five bars stand in a 321px row, so each has about 64px before it
  /// reaches its neighbour's label.
  static const double _achievedLabelWidth = 64;

  /// Gap between the bar's foot and the reward label.
  static const double _rewardLabelBottom = 10;

  @override
  Widget build(BuildContext context) {
    const width = 50.0;
    final isAchieve = voteItem.voteTotal! >= rank.amount;
    final barHeight = isAchieve ? rank.order * 20.0 + 60 : 60.0;
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: width, height: barHeight),
        Positioned(
          bottom: 0,
          width: width,
          height: barHeight,
          child: Container(
            key: barKey,
            decoration: BoxDecoration(gradient: commonGradient),
          ),
        ),
        Positioned(
          bottom: (barHeight + width * .7),
          child: FadeTransition(
            opacity: opacityAnimation,
            // One line, fitted to the bar's share of the row. Unbounded, the
            // English label was 104px at 1.0x and ran over the next bars
            // (PICNIC-2738).
            child: SizedBox(
              key: achievedLabelKey,
              width: _achievedLabelWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isAchieve ? '${AppLocalizations.of(context).achieve}!' : '',
                  maxLines: 1,
                  style: getTextStyle(AppTypo.caption12B, AppColors.point900),
                  textAlign: TextAlign.center,
                ),
              ),
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
                border: Border.all(color: AppColors.grey00, width: 1.w),
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
                        width: 45,
                        height: 45,
                        cdnVariant: PicnicCdnImageVariant.avatar,
                        lazyLoadingStrategy: LazyLoadingStrategy.none,
                        priority: ImagePriority.high,
                      ),
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
          bottom: _rewardLabelBottom,
          child: FadeTransition(
            opacity: opacityAnimation,
            // The label wraps inside the bar's width and keeps to the space
            // between the bar's foot and the thumbnail that overlaps its top.
            // Only when the wrapped text is taller than that is it scaled
            // down; left alone it grew up past the bar at 2.0x, where white
            // text on a white card simply disappears (PICNIC-2738).
            child: SizedBox(
              width: width,
              height: barHeight - width * .4 - _rewardLabelBottom,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: width,
                    child: Text(
                      '${AppLocalizations.of(context).reward} ${rank.order}',
                      style: getTextStyle(
                        AppTypo.caption10SB,
                        AppColors.grey00,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
