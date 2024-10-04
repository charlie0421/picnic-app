import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class BottomSheetHeader extends StatelessWidget {
  BottomSheetHeader({super.key, required this.title});
  String title = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 16),
      color: AppColors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 5,
            width: 100.cw,
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
