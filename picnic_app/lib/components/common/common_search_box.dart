import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
          Padding(
            padding: EdgeInsets.only(left: 16.cw, right: 8.cw),
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
                hintStyle: getTextStyle(AppTypo.body16R, AppColors.grey300),
                border: InputBorder.none,
                focusColor: AppColors.primary500,
                fillColor: AppColors.grey900,
              ),
              style: getTextStyle(AppTypo.body16R, AppColors.grey900),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _textEditingController.clear(),
            child: Padding(
              padding: EdgeInsets.only(left: 8.cw, right: 16.cw),
              child: SvgPicture.asset(
                'assets/icons/cancle_style=fill.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  _textEditingController.text.isNotEmpty
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
