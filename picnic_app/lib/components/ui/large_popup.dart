import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/ui/style.dart';

class LargePopupWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? footer;
  final Widget? closeButton;

  const LargePopupWidget(
      {super.key,
      required this.title,
      required this.content,
      this.footer,
      this.closeButton});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: double.infinity,
                margin:
                    footer != null ? const EdgeInsets.only(bottom: 24).r : null,
                padding: const EdgeInsets.only(
                        top: 64, left: 24, right: 24, bottom: 36)
                    .r,
                decoration: BoxDecoration(
                    color: AppColors.Gray00,
                    border: Border.all(
                      color: AppColors.Mint500,
                      width: 2.r,
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(120.r),
                        topRight: Radius.circular(120.r),
                        bottomLeft: Radius.circular(120.r),
                        bottomRight: Radius.circular(120.r))),
                child: content),
            if (closeButton != null)
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          //TODO i18n
                          Text('닫기',
                              style: getTextStyle(
                                  AppTypo.BODY14B, AppColors.Gray00)),
                          SizedBox(width: 4.w),
                          SvgPicture.asset(
                            'assets/icons/vote/close.svg',
                            width: 24.w,
                            height: 24.w,
                          ),
                        ],
                      ))),
          ],
        ),
        Positioned.fill(
            child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.symmetric(horizontal: 32).w,
                child: VoteCommonTitle(title: title))),
        Positioned.fill(
            child: Container(
                alignment: Alignment.bottomCenter,
                child: footer ?? Container())),
      ],
    );
  }
}
