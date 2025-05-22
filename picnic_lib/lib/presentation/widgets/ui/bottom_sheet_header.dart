import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';

class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 5,
            width: 100.w,
            color: AppColors.grey300,
          ),
          Text(
            title,
            style: getTextStyle(AppTypo.body14B, AppColors.primary500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
