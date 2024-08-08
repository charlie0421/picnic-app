import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';

class CommonSearchBox extends StatelessWidget {
  const CommonSearchBox({
    super.key,
    required FocusNode focusNode,
    required TextEditingController textEditingController,
    required String hintText,
  })  : _focusNode = focusNode,
        _textEditingController = textEditingController,
        _hintText = hintText;

  final FocusNode _focusNode;
  final TextEditingController _textEditingController;
  final String _hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.Primary500,
          width: 1.r,
        ),
        borderRadius: BorderRadius.circular(24.r),
        color: AppColors.Grey00,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 8.w),
            child: SvgPicture.asset(
              'assets/icons/vote/search_icon.svg',
              width: 20,
              height: 20,
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: _hintText,
                hintStyle: getTextStyle(AppTypo.BODY16R, AppColors.Grey300),
                border: InputBorder.none,
                focusColor: AppColors.Primary500,
                fillColor: AppColors.Grey900,
              ),
              style: getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _textEditingController.clear(),
            child: Padding(
              padding: EdgeInsets.only(left: 8.w, right: 16.w),
              child: SvgPicture.asset(
                'assets/icons/cancle_style=fill.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  _textEditingController.text.isNotEmpty
                      ? AppColors.Grey700
                      : AppColors.Grey200,
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
