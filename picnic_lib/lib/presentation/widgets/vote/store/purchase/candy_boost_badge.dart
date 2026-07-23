import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

class CandyBoostBadge extends StatelessWidget {
  const CandyBoostBadge({super.key, required this.campaign});
  final ActivePromotionCampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final name = campaign.localizedDisplayName(locale);
    return Semantics(
      label: name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
            ),
            Text(
              campaign.extraBonusBps == 10000
                  ? AppLocalizations.of(context).candy_boost_exact_double
                  : AppLocalizations.of(context).candy_boost_extra_bonus,
              style: getTextStyle(AppTypo.caption10R, AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}
