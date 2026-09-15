import 'dart:math' as math;

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

/// How far the overlaid top close sits in from the card's top and right edges.
///
/// The card clips to a rounded rect ([Clip.antiAlias]) whose radius PICNIC-2694
/// resolves per body height, so a constant inset either floats in mid-card on a
/// small radius or gets its corner bitten off on a 120 one. Solving the corner
/// circle for the box's nearest point gives the exact edge distance that keeps
/// a [PicnicUi.minimumTapTarget] box whole: the box corner is inside the arc
/// only while `inset >= radius * (1 - 1/sqrt(2))`.
double largePopupTopCloseInset(BorderRadius? cardBorderRadius) {
  final radius = (cardBorderRadius ?? BorderRadius.circular(120.r)).topRight.x;
  return math.max(8.0, radius * (1 - 1 / math.sqrt2));
}

/// The vertical room the overlaid top close covers, measured from the card's
/// inner top edge.
///
/// A caller whose content puts anything interactive along the card's top right
/// — the balance row's recharge button does exactly that once the decoration
/// scrolls — has to keep it out of this band. The overlay wins the hit test
/// (it is the later [Stack] child), so a control left underneath would close
/// the popup instead of doing its own job.
double largePopupTopCloseOverlayExtent(BorderRadius? cardBorderRadius) =>
    largePopupTopCloseInset(cardBorderRadius) + PicnicUi.minimumTapTarget;

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

/// The same budget for [LargePopupCloseButtonPlacement.topRight].
///
/// The top close control is *overlaid on* the card's own top-right corner, not
/// stacked above it, so it costs the body nothing: the chrome is the card
/// border plus the same hidden strip every other popup pays. Laying it out as
/// its own row instead took 24 more than the hidden strip, and PICNIC-2694 had
/// already yielded the route margin down to its floor — that 24 came straight
/// out of the body and broke four of its viewport guarantees.
double largePopupTopCloseChromeHeight() => largePopupHiddenChromeHeight();

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
    this.closeButtonPlacement = LargePopupCloseButtonPlacement.bottom,
    this.closeButtonEnabled = true,
    this.onClose,

    this.cardBorderRadius,
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
            borderRadius: cardBorderRadius ?? BorderRadius.circular(120.r),
          ),
          child: content,
        ),
        if (titleWidget != null) _buildTitleOverlay(),
        if (_usesTopClose) _buildTopCloseOverlay(context),
      ],
    );

    return KeyboardDismissOnTap(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [card, _buildCloseAffordance(context)],
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

  /// The X, laid over the card's own top-right corner.
  ///
  /// [Positioned] inside the card [Stack] rather than a sibling row: the
  /// control has to be reachable without taking height from the body, which on
  /// the shortest viewports is the whole margin the controls live on. The card
  /// corner it covers is decoration — the portrait is centred and the names sit
  /// below it — so nothing readable goes under it.
  Widget _buildTopCloseOverlay(BuildContext context) {
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

    return Positioned(
      top: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.all(largePopupTopCloseInset(cardBorderRadius)),
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
    // With the overlaid top close showing, the trailing row is not an
    // affordance at all — it stays as the hidden strip so the card keeps the
    // exact chrome every other popup budgets for.
    if (_usesTopClose) {
      return const SizedBox(height: kLargePopupHiddenCloseStripHeight);
    }
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
