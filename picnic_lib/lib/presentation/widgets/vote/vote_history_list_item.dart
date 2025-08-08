import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteHistoryListItem extends StatelessWidget {
  const VoteHistoryListItem({super.key, required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.grey100,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VoteHistoryHeader(item: item),
                  _VoteInfo(item: item),
                  SizedBox(height: 4.h),
                  _VoteUsage(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _VoteHistoryHeader extends StatelessWidget {
  const _VoteHistoryHeader({required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    final isPartnership = item.vote.isPartnership ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('yyyy.MM.dd HH:mm:ss').format(item.createdAt!),
          style: getTextStyle(
            AppTypo.caption12R,
            AppColors.grey900,
          ),
        ),
        if (isPartnership)
          Image.asset(
            'assets/icons/store/${item.vote.partner}.png',
            package: 'picnic_lib',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/app_icon_128.png',
              width: 24,
              height: 24,
            ),
          )
        else
          Image.asset(
            'assets/app_icon_128.png',
            width: 24,
            height: 24,
          ),
      ],
    );
  }
}

class _VoteInfo extends StatelessWidget {
  const _VoteInfo({required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    final artistName = getLocaleTextFromJson(item.voteItem.artist?.name ?? {});
    final groupName =
        getLocaleTextFromJson(item.voteItem.artist?.artistGroup?.name ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getLocaleTextFromJson(item.vote.title),
          style: getTextStyle(
            AppTypo.body14M,
            AppColors.grey900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (artistName.isNotEmpty) ...[
          SizedBox(height: 2.h),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: artistName,
                  style: getTextStyle(
                    AppTypo.body16B,
                    AppColors.grey900,
                  ),
                ),
                if (groupName.isNotEmpty)
                  TextSpan(
                    text: ' ($groupName)',
                    style: getTextStyle(
                      AppTypo.body16M,
                      AppColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}

class _VoteUsage extends StatelessWidget {
  const _VoteUsage({required this.item});

  final VotePickModel item;

  Widget _buildStarIcon(BuildContext context, bool isPartnership) {
    const double iconContainerSize = 36.0;
    if (isPartnership) {
      return SizedBox(
        width: iconContainerSize,
        height: iconContainerSize,
        child: Center(
          child: Image.asset(
            'assets/icons/store/${item.vote.partner}.png',
            package: 'picnic_lib',
            width: 18,
            height: 18,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    } else {
      return Image.asset(
        'assets/icons/store/star_100.png',
        package: 'picnic_lib',
        width: iconContainerSize,
        height: iconContainerSize,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPartnership = item.vote.isPartnership ?? false;
    final starUsage = item.starCandyUsage ?? 0;
    final bonusUsage = item.starCandyBonusUsage ?? 0;

    if (starUsage == 0 && bonusUsage == 0) {
      return const SizedBox.shrink();
    }

    final numberStyle = getTextStyle(AppTypo.body14B, AppColors.grey900);
    final List<Widget> children = [];

    // Star candy part
    if (starUsage > 0) {
      children.add(_buildStarIcon(context, isPartnership));
      children.add(SizedBox(width: 2.w));
      children.add(Text(formatNumberWithComma(starUsage), style: numberStyle));
    }

    // Bonus candy part
    if (bonusUsage > 0) {
      if (starUsage > 0) {
        children.add(SizedBox(width: 8.w));
      }

      // Wrap bonus icon in a fixed-size container to ensure alignment
      children.add(
        SizedBox(
          width: 36.0,
          height: 36.0,
          child: Center(
            child: Image.asset(
              'assets/icons/store/bonus.png',
              package: 'picnic_lib',
              width: 20,
              height: 20,
            ),
          ),
        ),
      );
      children.add(SizedBox(width: 2.w));
      children.add(Text(formatNumberWithComma(bonusUsage), style: numberStyle));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}
