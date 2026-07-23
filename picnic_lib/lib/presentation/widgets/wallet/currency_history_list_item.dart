import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class CurrencyHistoryListItem extends StatelessWidget {
  const CurrencyHistoryListItem({super.key, required this.item});

  final CurrencyHistoryItemModel item;

  @override
  Widget build(BuildContext context) {
    final delta = item.delta;
    final signedDelta = delta > BigInt.zero ? '+$delta' : delta.toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_currencyLabel(context)} · ${item.eventType}',
                  style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                ),
              ),
              Text(
                signedDelta,
                style: getTextStyle(
                  AppTypo.body16B,
                  delta < BigInt.zero
                      ? AppColors.statusError
                      : AppColors.point900,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            item.origin,
            style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
          ),
          SizedBox(height: 4.h),
          Text(
            formatLocalDateTime(item.createdAt, format: 'yyyy.MM.dd HH:mm:ss'),
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
          if (item.expiresAt != null) ...[
            SizedBox(height: 2.h),
            Text(
              'Expires: ${formatLocalDateTime(item.expiresAt, format: 'yyyy.MM.dd HH:mm:ss')}',
              style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
            ),
          ],
          SizedBox(height: 8.h),
          InkWell(
            onTap: () =>
                Clipboard.setData(ClipboardData(text: item.operationId)),
            child: Row(
              children: [
                Expanded(
                  child: SelectionArea(
                    child: Text(
                      'Support: ${item.operationId}',
                      style: getTextStyle(
                        AppTypo.caption12R,
                        AppColors.grey600,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.copy, size: 16.w, color: AppColors.grey500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currencyLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (item.currency) {
      WalletCurrency.starCandy => l10n.wallet_star_candy,
      WalletCurrency.bonusStarCandy => l10n.wallet_bonus_star_candy,
      WalletCurrency.cottonCandy => l10n.wallet_cotton_candy,
    };
  }
}
