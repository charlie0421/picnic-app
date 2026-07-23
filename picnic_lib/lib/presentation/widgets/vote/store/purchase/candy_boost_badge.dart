import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/ui/style.dart';

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
        child: Text(
          campaign.extraBonusBps == 10000 ? '$name · 2X' : name,
          style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
        ),
      ),
    );
  }
}
