import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteHistoryListItem extends StatelessWidget {
  const VoteHistoryListItem({super.key, required this.item});
  final VotePickModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 107,
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.grey300, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy.MM.dd HH:mm:ss').format(item.createdAt!),
                style: getTextStyle(
                  AppTypo.caption12R,
                  AppColors.grey900,
                ),
              ),
               ((item.vote.isPartnership ?? false )&& item.vote.partner == 'jma') ?
                Image.asset(
                  'assets/icons/store/${item.vote.partner}.png',
                  package: 'picnic_lib',
                  width: 24,
                  height: 24,
                )
              : Image.asset(
                  'assets/app_icon_128.png',
                  width: 24,
                  height: 24,
                ),

            ],
          ),
          Text(
            '${formatNumberWithComma(item.amount)} ${AppLocalizations.of(context).text_star_candy}',
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: getLocaleTextFromJson(item.vote.title),
                  style: getTextStyle(
                    AppTypo.body14M,
                    AppColors.grey900,
                  ),
                ),
                TextSpan(
                  text: ' ',
                  style: getTextStyle(
                    AppTypo.body14M,
                    AppColors.grey900,
                  ),
                ),
                (item.voteItem.artist?.id ?? 0) != 0
                    ? TextSpan(
                        text:
                            '${getLocaleTextFromJson(item.voteItem.artist?.name ?? {})}_${getLocaleTextFromJson(item.voteItem.artist?.artistGroup?.name ?? {})}',
                        style: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey900,
                        ),
                      )
                    : TextSpan(
                        text: getLocaleTextFromJson(
                          item.voteItem.artistGroup?.name ?? {},
                        ),
                        style: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey900,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

