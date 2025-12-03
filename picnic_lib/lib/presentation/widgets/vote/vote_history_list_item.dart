import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteHistoryListItem extends StatelessWidget {
  const VoteHistoryListItem({super.key, required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VoteHistoryHeader(item: item),
          SizedBox(height: 8.h),
          _VoteInfo(item: item),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(color: AppColors.grey200, height: 1.h),
          ),
          _VoteUsage(item: item),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          formatLocalDateTime(
            item.createdAt,
            format: 'yyyy.MM.dd HH:mm:ss',
          ),
          style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
        ),
        if (isPartnership)
          Image.asset(
            'assets/icons/store/${item.vote.partner}.png',
            package: 'picnic_lib',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/app_icon_128.png', width: 24, height: 24),
          )
        else
          Image.asset('assets/app_icon_128.png', width: 24, height: 24),
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
    final groupName = getLocaleTextFromJson(
      item.voteItem.artist?.artistGroup?.name ?? {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getLocaleTextFromJson(item.vote.title),
          style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (artistName.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.point500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    artistName,
                    style: getTextStyle(AppTypo.caption12B, AppColors.point900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (groupName.isNotEmpty) ...[
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    groupName,
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.grey100.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}
