import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

/// Displays the separate currencies granted by a purchase product.
class RewardBreakdown extends StatelessWidget {
  const RewardBreakdown({
    super.key,
    required this.baseAmount,
    required this.bonusAmount,
    this.iconSize = 18,
  });

  final int baseAmount;
  final int bonusAmount;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final children = <InlineSpan>[
      _currency(baseAmount, 'assets/icons/store/currency_star_candy.png'),
    ];
    if (bonusAmount > 0) {
      children
        ..add(
          TextSpan(
            text: '  +  ',
            style: getTextStyle(AppTypo.caption12B, AppColors.grey600),
          ),
        )
        ..add(
          _currency(
            bonusAmount,
            'assets/icons/store/currency_bonus_star_candy.png',
          ),
        );
    }

    return Text.rich(
      TextSpan(children: children),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  InlineSpan _currency(int amount, String assetPath) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            package: 'picnic_lib',
            width: iconSize,
            height: iconSize,
          ),
          const SizedBox(width: 3),
          Text(
            '$amount',
            style: getTextStyle(AppTypo.caption12B, AppColors.point900),
          ),
        ],
      ),
    );
  }
}
