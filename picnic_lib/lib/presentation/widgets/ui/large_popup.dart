import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

/// The extent the trailing strip keeps when the popup shows no close
/// affordance.
///
/// voting_complete renders this popup inside a capture RepaintBoundary, so the
/// empty strip is part of every shared vote image and must not grow. It is
/// public because a caller that has to size the dialog body itself has to
/// budget for it too.
const double kLargePopupHiddenCloseStripHeight = 24;

/// The popup card's default width.
///
/// Exposed so a caller that bounds the dialog above [LargePopupWidget] can use
/// the same width the card will take, instead of re-deriving it.
double defaultLargePopupWidth() => 345.w;

/// The card border, which the decoration adds to the card's own height on both
/// edges.
double largePopupCardBorderWidth() => 2.r;

/// Everything [LargePopupWidget] adds around its content box when it shows no
/// close affordance: the card border on both edges plus the hidden strip.
///
/// A caller that has to bound the body from outside the popup has to subtract
/// this from the height the route left it, or the popup overflows by exactly
/// this much.
double largePopupHiddenChromeHeight() =>
    kLargePopupHiddenCloseStripHeight + largePopupCardBorderWidth() * 2;

class LargePopupWidget extends StatelessWidget {
  final Widget? titleWidget;
  final Widget content;
  final Widget? closeButton;
  final Color? backgroundColor;
  final double? width;
  final bool showCloseButton;

  /// The card's corner radius.
  ///
  /// Defaults to the design's `120.r` capsule. A caller that pins controls
  /// against the card edges on a short body passes a smaller radius, because
  /// the card really does clip ([Clip.antiAlias]) and a 120 radius on a 200
  /// high card is most of its height.
  final BorderRadius? cardBorderRadius;

  const LargePopupWidget({
    super.key,
    this.titleWidget,
    required this.content,
    this.closeButton,
    this.backgroundColor,
    this.width,
    this.showCloseButton = true,
    this.cardBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: width ?? defaultLargePopupWidth(),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.grey00,
                  border: Border.all(
                    color: AppColors.secondary500,
                    width: largePopupCardBorderWidth(),
                  ),
                  borderRadius:
                      cardBorderRadius ?? BorderRadius.circular(120.r),
                ),
                child: content,
              ),
              if (titleWidget != null) _buildTitleOverlay(),
            ],
          ),
          _buildCloseAffordance(context),
        ],
      ),
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        // A fixed 48 height cropped long titles and every title at a large
        // text scale. The minimum keeps the untouched single-line geometry
        // and lets a taller title grow into the popup's own padding.
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 33.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Expanded(child: titleWidget!)],
        ),
      ),
    );
  }

  Widget _buildCloseAffordance(BuildContext context) {
    final custom = closeButton;
    // `showCloseButton` is the flag that makes this strip an affordance at
    // all — the tap handler below pops only for it, so a hidden strip is never
    // interactive no matter what widget it holds. voting_complete passes
    // `closeButton: _isSaving ? Container() : null` on the hidden branch: that
    // is a capture placeholder, not a control, and letting it claim the 48
    // minimum grew the captured strip from 24 to 48 for exactly the frames
    // that end up in the shared vote image. A custom button on the *visible*
    // branch still gets the full tap target.
    final hasAffordance = showCloseButton;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (showCloseButton) {
          Navigator.pop(context);
        }
      },
      child: Container(
        constraints: hasAffordance
            ? const BoxConstraints(minHeight: PicnicUi.minimumTapTarget)
            : const BoxConstraints.tightFor(
                height: kLargePopupHiddenCloseStripHeight,
              ),
        padding: EdgeInsets.only(right: 16.w),
        child:
            custom ??
            (showCloseButton
                ? _buildDefaultCloseRow(context)
                : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildDefaultCloseRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context).label_button_close,
            style: PicnicUi.text(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.grey00,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        SizedBox(width: PicnicUi.horizontal(4)),
        SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/cancel_style=line.svg',
          width: 24.w,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColors.grey00,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}
