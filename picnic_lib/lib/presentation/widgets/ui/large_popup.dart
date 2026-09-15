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

/// The extent the *leading* strip takes in
/// [LargePopupCloseButtonPlacement.topRight], which is one full tap target and
/// nothing else. It is public for the same reason the hidden strip is: a caller
/// that bounds the body itself has to budget for it.
const double kLargePopupTopCloseStripHeight = PicnicUi.minimumTapTarget;

/// Identifies the top-right close control so a caller's regression test can
/// measure and tap exactly it, instead of guessing at an icon or a label that
/// the localized bottom row also carries.
const Key kLargePopupTopCloseKey = ValueKey('largePopupTopClose');

/// Where [LargePopupWidget] puts its close affordance.
enum LargePopupCloseButtonPlacement {
  /// The historical row under the card: trailing "닫기" text plus the cancel
  /// icon. Every existing caller keeps this.
  bottom,

  /// A single 48x48 X in a strip above the card, for popups the user has to be
  /// able to leave while an input inside them holds the keyboard.
  topRight,
}

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

/// The same budget for [LargePopupCloseButtonPlacement.topRight]: the card
/// border on both edges plus the 48 close strip, which replaces the trailing
/// strip rather than adding to it.
double largePopupTopCloseChromeHeight() =>
    kLargePopupTopCloseStripHeight + largePopupCardBorderWidth() * 2;

class LargePopupWidget extends StatelessWidget {
  final Widget? titleWidget;
  final Widget content;
  final Widget? closeButton;
  final Color? backgroundColor;
  final double? width;
  final bool showCloseButton;

  /// Which side of the card the close affordance sits on. Defaults to the
  /// historical [LargePopupCloseButtonPlacement.bottom] row.
  final LargePopupCloseButtonPlacement closeButtonPlacement;

  /// Whether the close affordance may actually be used. A disabled affordance
  /// keeps its geometry — the popup must not jump when it locks — but stops
  /// being interactive at all, so no ancestor can pop in its place.
  final bool closeButtonEnabled;

  /// Runs *instead of* this widget's own `Navigator.pop`, so a caller that has
  /// to check its own state before leaving (a vote in flight, for instance)
  /// owns the whole decision. Exactly one of the two ever runs.
  final VoidCallback? onClose;

  const LargePopupWidget({
    super.key,
    this.titleWidget,
    required this.content,
    this.closeButton,
    this.backgroundColor,
    this.width,
    this.showCloseButton = true,
    this.closeButtonPlacement = LargePopupCloseButtonPlacement.bottom,
    this.closeButtonEnabled = true,
    this.onClose,
  });

  bool get _usesTopClose =>
      showCloseButton &&
      closeButtonPlacement == LargePopupCloseButtonPlacement.topRight;

  @override
  Widget build(BuildContext context) {
    final card = Stack(
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
            borderRadius: BorderRadius.circular(120.r),
          ),
          child: content,
        ),
        if (titleWidget != null) _buildTitleOverlay(),
      ],
    );

    return KeyboardDismissOnTap(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: _usesTopClose
            // One strip, above the card. Keeping the trailing strip as well
            // would spend 72 of the body's budget on chrome.
            ? [_buildTopCloseStrip(context), card]
            : [card, _buildCloseAffordance(context)],
      ),
    );
  }

  /// Runs the caller's [onClose] when it has one, and this widget's own pop
  /// otherwise — never both.
  void _handleClose(BuildContext context) {
    final callback = onClose;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.pop(context);
  }

  Widget _buildTopCloseStrip(BuildContext context) {
    final icon = SvgPicture.asset(
      package: 'picnic_lib',
      'assets/icons/cancel_style=line.svg',
      width: 24.w,
      height: 24,
      colorFilter: ColorFilter.mode(
        closeButtonEnabled
            ? AppColors.grey00
            : AppColors.grey00.withValues(alpha: 0.4),
        BlendMode.srcIn,
      ),
    );

    return SizedBox(
      width: width ?? defaultLargePopupWidth(),
      height: kLargePopupTopCloseStripHeight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Semantics(
            button: true,
            enabled: closeButtonEnabled,
            label: MaterialLocalizations.of(context).closeButtonLabel,
            child: GestureDetector(
              key: kLargePopupTopCloseKey,
              behavior: HitTestBehavior.opaque,
              // Disabled means *not interactive*, not "interactive but
              // ignored": with no handler this detector never enters the
              // gesture arena, so nothing behind it inherits the dismissal.
              onTap: closeButtonEnabled ? () => _handleClose(context) : null,
              child: SizedBox(
                width: PicnicUi.minimumTapTarget,
                height: PicnicUi.minimumTapTarget,
                // A caller-supplied child is decoration inside the slot; the
                // strip owns the interaction so a nested handler can never add
                // a second pop.
                child: IgnorePointer(child: Center(child: closeButton ?? icon)),
              ),
            ),
          ),
        ),
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
    final interactive = showCloseButton && closeButtonEnabled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive ? () => _handleClose(context) : null,
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
