import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_palette.dart';
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
    if (flexibleHeight && isPromoted) {
      return _buildPromotedPurchaseCard(context);
    }

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
                  children: [title, ?badge],
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

  Widget _buildPromotedPurchaseCard(BuildContext context) {
    return Container(
      key: const Key('candy-boost-purchase-card'),
      width: buttonScale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kCandyBoostPurple.withValues(alpha: .34),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kCandyBoostPurple.withValues(alpha: .11),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const Key('candy-boost-promo-ribbon'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kCandyBoostPurple, kCandyBoostPink],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: badge ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kCandyBoostPurple.withValues(alpha: .16),
                              kCandyBoostPink.withValues(alpha: .12),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kCandyBoostPurple.withValues(alpha: .25),
                          ),
                        ),
                        child: FittedBox(child: icon),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: getTextStyle(
                            AppTypo.body16B,
                            AppColors.grey900,
                          ),
                          child: title,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPurchaseCta(),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    subtitle!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCta() {
    final enabled = !isLoading && buttonOnPressed != null;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Container(
        key: const Key('purchase-price-cta'),
        width: 88,
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kCandyBoostPurple, kCandyBoostPink],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: kCandyBoostPurple.withValues(alpha: .24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : buttonOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 16.w,
                  height: 16,
                  child: const SmallPulseLoadingIndicator(),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    style: getTextStyle(AppTypo.body14B, Colors.white),
                  ),
                ),
        ),
      ),
    );
  }
}
