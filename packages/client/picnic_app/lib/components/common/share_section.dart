import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
              minimumSize: Size(buttonWidth ?? 120.cw, buttonHeight ?? 32),
              maximumSize: Size(buttonWidth ?? 120.cw, buttonHeight ?? 32),
            ),
            child: Row(
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
                SizedBox(width: 8.cw),
                SvgPicture.asset(
                  'assets/icons/save_gallery.svg',
                  width: 16.cw,
                  height: 16,
                ),
              ],
            ),
          ),
          SizedBox(width: 16.cw),
          ElevatedButton(
            onPressed: onShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shadowColor: AppColors.primary500,
              padding: EdgeInsets.zero,
              minimumSize: Size(buttonWidth ?? 120.cw, buttonHeight ?? 32),
              maximumSize: Size(buttonWidth ?? 120.cw, buttonHeight ?? 32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shareButtonText,
                  style: getTextStyle(
                    AppTypo.body14B,
                    AppColors.grey00,
                  ),
                ),
                SizedBox(width: 8.cw),
                SvgPicture.asset(
                  'assets/icons/twitter_style=fill.svg',
                  width: 16.cw,
                  height: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
