import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

class ShareSection extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;
  final String saveButtonText;
  final String shareButtonText;
  final double? buttonWidth;
  final double? buttonHeight;

  const ShareSection({
    super.key,
    required this.onSave,
    required this.onShare,
    this.saveButtonText = 'save',
    this.shareButtonText = 'share',
    this.buttonWidth,
    this.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shadowColor: AppColors.primary500,
              padding: EdgeInsets.zero,
              minimumSize: Size(buttonWidth ?? 120.w, buttonHeight ?? 32),
              maximumSize: Size(buttonWidth ?? 120.w, buttonHeight ?? 32),
            ),
            // Both buttons are one fixed size (minimumSize == maximumSize), so
            // the label and icon have to fit the box rather than the other way
            // round. scaleDown shrinks only a label that is too wide for it —
            // Spanish, Bengali, Thai and others at larger text scales — and
            // leaves any label that already fits exactly as it was.
            //
            // The outer Row keeps the old geometry: it takes the button's full
            // width and centres its content, exactly as the single Row did, so
            // a label that fits lands on the same pixels. A bare FittedBox
            // would shrink-wrap instead and let the button settle at its
            // minimum width, 8px narrower under desktop visual density.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          saveButtonText,
                          style: getTextStyle(
                            AppTypo.body14B,
                            AppColors.grey00,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(width: 8.w),
                        SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/save_gallery.svg',
                          width: 16.w,
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          ElevatedButton(
            onPressed: onShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shadowColor: AppColors.primary500,
              padding: EdgeInsets.zero,
              minimumSize: Size(buttonWidth ?? 120.w, buttonHeight ?? 32),
              maximumSize: Size(buttonWidth ?? 120.w, buttonHeight ?? 32),
            ),
            // Both buttons are one fixed size (minimumSize == maximumSize), so
            // the label and icon have to fit the box rather than the other way
            // round. scaleDown shrinks only a label that is too wide for it —
            // Spanish, Bengali, Thai and others at larger text scales — and
            // leaves any label that already fits exactly as it was.
            //
            // The outer Row keeps the old geometry: it takes the button's full
            // width and centres its content, exactly as the single Row did, so
            // a label that fits lands on the same pixels. A bare FittedBox
            // would shrink-wrap instead and let the button settle at its
            // minimum width, 8px narrower under desktop visual density.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shareButtonText,
                          style: getTextStyle(
                            AppTypo.body14B,
                            AppColors.grey00,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/twitter_style=fill.svg',
                          width: 16.w,
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
