import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaCategoryChip extends StatelessWidget {
  final String label;

  const QnaCategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.point500,
                AppColors.point500.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.point500.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: getTextStyle(AppTypo.caption12B, Colors.white),
          ),
        ),
      ),
    );
  }
}
