import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
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
            _ArtistImage(item: item),
            SizedBox(width: 12.w),
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

class _ArtistImage extends StatelessWidget {
  const _ArtistImage({required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: PicnicCachedNetworkImage(
        imageUrl: item.voteItem.artist?.image ?? '',
        width: 40,
        height: 40,
        errorWidget: Image.asset(
          'assets/icons/avatar.png',
          package: 'picnic_lib',
          width: 40,
          height: 40,
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
        Text(
          '${getLocaleTextFromJson(item.voteItem.artist?.name ?? {})} ${getLocaleTextFromJson(item.voteItem.artist?.artistGroup?.name ?? {})}',
          style: getTextStyle(
            AppTypo.caption12R,
            AppColors.grey900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VoteUsage extends StatelessWidget {
  const _VoteUsage({required this.item});

  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    final isPartnership = item.vote.isPartnership ?? false;
    return Row(
      children: [
        if (isPartnership) ...[
          SizedBox(width: 12.w),
          Image.asset(
            'assets/icons/store/${item.vote.partner}.png',
            package: 'picnic_lib',
            width: 18,
            height: 18,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          SizedBox(width: 8.w),
        ] else
          Image.asset(
            'assets/icons/store/star_100.png',
            package: 'picnic_lib',
            width: 36,
            height: 36,
          ),
        Text(
          formatNumberWithComma(item.starCandyUsage ?? 0),
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        ),
        const Text(' + '),
        Image.asset(
          'assets/icons/store/bonus.png',
          package: 'picnic_lib',
          width: 20,
          height: 20,
        ),
        SizedBox(width: 8.w),
        Text(
          formatNumberWithComma(item.starCandyBonusUsage ?? 0),
          style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        ),
      ],
    );
  }
}
