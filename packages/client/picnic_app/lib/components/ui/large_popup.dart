import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';

class LargePopupWidget extends StatelessWidget {
  final String? title;
  final Widget content;
  final Widget? closeButton;
  final Color? backgroundColor;
  final double? width;
  final showCloseButton;

  const LargePopupWidget({
    super.key,
    this.title,
    required this.content,
    this.closeButton,
    this.backgroundColor,
    this.width,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
                width: width ?? 345.w,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.Grey00,
                  border: Border.all(
                    color: AppColors.Mint500,
                    width: 2.r,
                  ),
                  borderRadius: BorderRadius.circular(120.r),
                ),
                child: content),
            if (title != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 48.w,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 33).w,
                    child: VoteCommonTitle(title: title!)),
              ),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (closeButton != null) {
              Navigator.pop(context);
            }
          },
          child: Container(
              height: 24.h,
              padding: EdgeInsets.only(right: 16.w),
              child: closeButton != null
                  ? closeButton!
                  : showCloseButton
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(S.of(context).label_button_close,
                                style: getTextStyle(
                                    AppTypo.BODY14B, AppColors.Grey00)),
                            SizedBox(width: 4.w),
                            SvgPicture.asset(
                              'assets/icons/cancle_style=line.svg',
                              width: 24.w,
                              height: 24.w,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.Grey00, BlendMode.srcIn),
                            ),
                          ],
                        )
                      : const SizedBox.shrink()),
        ),
      ],
    ));
  }
}
