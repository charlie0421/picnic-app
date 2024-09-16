import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class StoreListTile extends StatelessWidget {
  const StoreListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.buttonOnPressed,
    this.isLoading = false,
    this.index,
    this.buttonScale,
  });

  final Image icon;
  final Text title;
  final Text? subtitle;
  final String buttonText;
  final VoidCallback? buttonOnPressed; // 여기를 VoidCallback?로 변경
  final bool isLoading;
  final int? index;
  final double? buttonScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: buttonScale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon,
          SizedBox(width: 16.cw),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, if (subtitle != null) subtitle!],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: isLoading ? null : buttonOnPressed,
              child: isLoading
                  ? SizedBox(
                      width: 16.cw,
                      height: 16,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary500),
                      ),
                    )
                  : Text(
                      buttonText,
                      style:
                          getTextStyle(AppTypo.body14B, AppColors.primary500),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
