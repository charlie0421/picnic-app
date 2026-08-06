import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

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
    this.badge,
    this.flexibleHeight = false,
  });

  final Image icon;
  final Text title;
  final Widget? subtitle;
  final String buttonText;
  final VoidCallback? buttonOnPressed; // 여기를 VoidCallback?로 변경
  final bool isLoading;
  final int? index;
  final double? buttonScale;
  final Widget? badge;
  final bool flexibleHeight;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        icon,
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center로 변경
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: title),
                  if (badge != null) ...[SizedBox(width: 6.w), badge!],
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4), // 간격 추가
                subtitle!,
              ],
            ],
          ),
        ),
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: isLoading ? null : buttonOnPressed,
            child: isLoading
                ? SizedBox(
                    width: 16.w,
                    height: 16,
                    child: const SmallPulseLoadingIndicator(),
                  )
                : Text(buttonText, style: getTextStyle(AppTypo.body14B)),
          ),
        ),
      ],
    );

    if (flexibleHeight) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: subtitle != null ? 64 : 48),
        child: SizedBox(width: buttonScale, child: content),
      );
    }

    return SizedBox(
      height: subtitle != null ? 64 : 48,
      width: buttonScale,
      child: content,
    );
  }
}
