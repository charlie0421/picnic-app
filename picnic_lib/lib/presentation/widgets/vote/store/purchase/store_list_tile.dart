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
    this.isPromoted = false,
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
  final bool isPromoted;
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
              if (flexibleHeight)
                // Let each item use its natural width. Two equal flex slots
                // split long product IDs even when the badge is much shorter.
                // A promoted row can grow if its badge needs the next line.
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    title,
                    if (badge != null)
                      KeyedSubtree(
                        key: const Key('candy-boost-inline-badge'),
                        child: badge!,
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    Flexible(child: title),
                    if (badge != null) ...[
                      SizedBox(width: 6.w),
                      Flexible(child: badge!),
                    ],
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
            key: const Key('purchase-price-cta'),
            onPressed: isLoading ? null : buttonOnPressed,
            child: isLoading
                ? SizedBox(
                    width: 16.w,
                    height: 16,
                    child: const SmallPulseLoadingIndicator(),
                  )
                // The button box is a fixed 32px by design, so a large text
                // scale used to push the label past it (a debug-only overflow
                // report; release clipped the glyphs). Scaling the label down
                // keeps it whole without changing any tile's geometry.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      buttonText,
                      style: getTextStyle(AppTypo.body14B),
                    ),
                  ),
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
