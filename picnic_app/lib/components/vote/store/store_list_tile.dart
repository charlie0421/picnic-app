import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/ui/style.dart';

class StoreListTile extends StatelessWidget {
  const StoreListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.buttonOnPressed,
    this.isLoading = false,
    this.buttonScale,
  });

  final Image icon;
  final Text title;
  final Text? subtitle;
  final String buttonText;
  final Function buttonOnPressed;
  final bool? isLoading;
  final double? buttonScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon,
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, subtitle ?? Container()],
            ),
          ),
          SizedBox(
            height: 32.w,
            child: ElevatedButton(
              onPressed: isLoading == null || buttonOnPressed == null
                  ? null
                  : () => buttonOnPressed(),
              child: isLoading == true
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.Primary500,
                      ),
                    )
                  : Text(
                      buttonText,
                      style:
                          getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
