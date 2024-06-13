import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';

class ListItem extends StatelessWidget {
  final String leading;
  final String assetPath;
  final VoidCallback? onTap;
  final Widget? tailing;
  final Widget? title;

  const ListItem({
    super.key,
    required this.leading,
    required this.assetPath,
    this.onTap,
    this.tailing,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(leading, style: getTextStyle(AppTypo.BODY16M)),
            Expanded(child: title ?? const SizedBox.shrink()),
            tailing ??
                SvgPicture.asset(
                  assetPath,
                  width: 20.w,
                  height: 20.h,
                  colorFilter: const ColorFilter.mode(
                    AppColors.Grey900,
                    BlendMode.srcIn,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
