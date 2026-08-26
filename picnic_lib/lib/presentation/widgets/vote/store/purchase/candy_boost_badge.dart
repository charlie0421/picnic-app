import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class CandyBoostBadge extends StatelessWidget {
  const CandyBoostBadge({
    super.key,
    required this.displayName,
    required this.bonusLabel,
  });
  final String displayName;
  final String bonusLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: displayName,
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
              displayName,
              style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
            ),
            Text(
              bonusLabel,
              style: getTextStyle(AppTypo.caption10R, AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Integer-tenths multiplier (e.g. 15 -> "1.5") shown verbatim in the UI —
/// never the raw bps value it is derived from.
String formatCandyBoostMultiplierTenths(int tenths) {
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  return frac == 0 ? '$whole' : '$whole.$frac';
}
