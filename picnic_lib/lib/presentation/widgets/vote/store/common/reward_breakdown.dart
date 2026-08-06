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

    // WidgetSpan(아이콘+숫자 Row)은 줄임표로 잘리지 않는 단일 블록이라,
    // 긴 숫자·큰 글자 배율에서 타일 폭을 넘으면 Row 가 그대로 오버플로한다
    // (Terra 리뷰 권고로 추가한 테스트에서 실측 재현). 넘칠 때는 줄이
    // 아니라 전체를 축소해 항상 한 줄에 들어가게 한다.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(TextSpan(children: children), maxLines: 1),
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
