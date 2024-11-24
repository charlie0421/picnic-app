import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityTipCard extends StatelessWidget {
  const CompatibilityTipCard({
    super.key,
    required this.tip,
    required this.index,
  });

  final String tip;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey500,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: Text(
              index.toString(),
              style: getTextStyle(
                AppTypo.caption12B,
                AppColors.grey00,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: getTextStyle(
                AppTypo.body14R,
                AppColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
