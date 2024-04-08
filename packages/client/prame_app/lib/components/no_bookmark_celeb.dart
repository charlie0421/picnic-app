import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/ui/style.dart';

class NoBookmarkCeleb extends StatelessWidget {
  const NoBookmarkCeleb({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 134.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/landing/no_celeb.svg',
              width: 60.w,
              height: 60.h,
              colorFilter:
                  const ColorFilter.mode(Color(0xFFB7B7B7), BlendMode.srcIn)),
          SizedBox(height: 8.h),
          Text(
            Intl.message('label_no_celeb'),
            style: getTextStyle(AppTypo.UI20, AppColors.Gray300),
          )
        ],
      ),
    );
  }
}
