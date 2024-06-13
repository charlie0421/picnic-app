import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/ui/style.dart';

class LargePopupWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? footer;
  final Widget? closeButton;

  const LargePopupWidget({
    super.key,
    required this.title,
    required this.content,
    this.footer,
    this.closeButton,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      double resizeFactor = isKeyboardVisible ? 0.5 : 1;
      return KeyboardDismissOnTap(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
                width: double.infinity,
                margin: closeButton != null && !isKeyboardVisible
                    ? EdgeInsets.only(bottom: 32.w)
                    : EdgeInsets.only(bottom: 0.w),
                padding: isKeyboardVisible
                    ? EdgeInsets.only(
                        top: 0.w, left: 24.w, right: 24.w, bottom: 18.w)
                    : EdgeInsets.only(
                        top: 40.w, left: 24.w, right: 24.w, bottom: 36.w),
                decoration: BoxDecoration(
                    color: AppColors.Grey00,
                    border: Border.all(
                      color: AppColors.Mint500,
                      width: 2.r,
                    ),
                    borderRadius: BorderRadius.circular(120.r)),
                child: content),
            if (closeButton != null && !isKeyboardVisible)
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('닫기',
                              style: getTextStyle(
                                  AppTypo.BODY14B, AppColors.Grey00)),
                          SizedBox(width: 4.w),
                          SvgPicture.asset(
                            'assets/icons/vote/close.svg',
                            width: 24.w,
                            height: 24.w,
                          ),
                        ],
                      ))),
            if (!isKeyboardVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 48.w,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 33).w,
                    child: VoteCommonTitle(title: title)),
              ),
          ],
        ),
      );
    });
  }
}
