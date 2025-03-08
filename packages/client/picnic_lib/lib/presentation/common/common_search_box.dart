import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

class CommonSearchBox extends StatelessWidget {
  const CommonSearchBox({
    super.key,
    required this.focusNode,
    required this.textEditingController,
    required this.hintText,
    this.onSubmitted,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final String hintText;
  final Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary500,
          width: 1.r,
        ),
        borderRadius: BorderRadius.circular(24.r),
        color: AppColors.grey00,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (textEditingController.text.isNotEmpty) {
                onSubmitted?.call(textEditingController.text);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/vote/search_icon.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: getTextStyle(AppTypo.body16R, AppColors.grey300),
                border: InputBorder.none,
                focusColor: AppColors.primary500,
                fillColor: AppColors.grey900,
              ),
              style: getTextStyle(AppTypo.body16R, AppColors.grey900),
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.done,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              textEditingController.clear();
              onSubmitted?.call('');
            },
            child: Padding(
              padding: EdgeInsets.only(left: 8.w, right: 16.w),
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/cancel_style=fill.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  textEditingController.text.isNotEmpty
                      ? AppColors.grey700
                      : AppColors.grey200,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
