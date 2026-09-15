import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';

/// Shared height policy for the voting popups (PICNIC-2694).
///
/// The popups used to decide what to pin from the keyboard flag and a screen
/// ratio, so a short or landscape parent — a Flip in flex mode, a folded
/// foldable, a phone in landscape, a tablet split view — laid the artist
/// portrait, the names and the balance out first and pushed the amount input
/// and the vote button below the fold with no keyboard involved at all.
///
/// The policy here inverts that: the controls a vote cannot happen without are
/// laid out before any decoration, and whatever is left over goes to the
/// decoration, which scrolls when it does not fit.

/// The widest the voting capsule may get.
///
/// [defaultLargePopupWidth] is `345.w`, and `.w` is the *width* factor, so a
/// 851 wide landscape viewport turns a 345 card into a 747 one — wide enough
/// that the decoration inside it (also authored in `.w`) grows past the height
/// the controls need. The cap keeps the popup a popup on a wide window; it is
/// a new constant, not one of the design sizes.
const double kVoteDialogMaxWidth = 560;

/// The wider cap is considered only for the general dialog's two-column
/// candidate. The one-column path continues to use [kVoteDialogMaxWidth].
const double kVoteDialogColumnsMaxWidth = 800;

/// Local logical-pixel geometry for the two-column candidate.
const double kVoteDialogColumnGap = 16;
const double kVoteDialogColumnsHorizontalPadding = 16;
const double kVoteDialogColumnsVerticalPadding = 16;

/// How the popup body arranges its bands inside the height the route left it.
enum VoteDialogLayoutMode {
  /// The action group (use all + amount input + submit) is laid out first and
  /// never scrolls; the decoration around it yields and scrolls instead.
  actionsPinned,

  /// Not even the action group fits the body, so everything scrolls — with the
  /// actions first, so the input is what the popup opens on.
  allScroll,
}

/// [VoteDialogLayoutMode.actionsPinned] while the body can hold the action
/// group whole, and [VoteDialogLayoutMode.allScroll] below that.
///
/// [essentialHeight] is measured from the real controls (scaled text, borders,
/// the 48 clear button inside the field), not from a nominal row height: at
/// 200% text the amount input outgrows its 48 minimum, and a policy that
/// assumed 48 pinned a group it could not actually fit.
VoteDialogLayoutMode selectVoteDialogLayout({
  required double bodyHeight,
  required double essentialHeight,
}) => essentialHeight <= bodyHeight
    ? VoteDialogLayoutMode.actionsPinned
    : VoteDialogLayoutMode.allScroll;

/// The width both the outer `SizedBox` and [LargePopupWidget] should use.
double resolveVoteDialogWidth() =>
    math.min(defaultLargePopupWidth(), kVoteDialogMaxWidth);

/// A decoration extent authored in design pixels, scaled but never inflated.
///
/// Portraits and logos are square boxes written as `80.w` / `60.w` / `100.w`,
/// which is fine while the viewport is narrower than the 393 design width and
/// wrong the moment it is wider: the *vertical* side then grows with the
/// viewport width. Scaling down is still allowed — a 320 phone should keep its
/// smaller portrait — so this is a cap, not a freeze.
double voteDialogDecorationExtent(double designExtent) =>
    math.min(designExtent.w, designExtent);

/// A horizontal extent inside the capsule, shrunk by the same factor the card
/// itself was capped by.
///
/// Returns exactly `designExtent.w` while the card is under [kVoteDialogMaxWidth],
/// so nothing moves on the phones the design was drawn for.
double voteDialogCardExtent(double designExtent) {
  final full = defaultLargePopupWidth();
  if (full <= 0) return designExtent.w;
  return designExtent.w * (resolveVoteDialogWidth() / full);
}

/// The smallest the artist portrait may shrink to before the decoration band
/// gives up on showing it whole.
const double kVoteDialogMinimumPortrait = 32;

/// The portrait side that fits [availableHeight] once [reservedHeight] — the
/// rest of the decoration band — has taken its share.
///
/// Never grows past [preferredSide] and never shrinks past
/// [kVoteDialogMinimumPortrait]: a 12px disc is not a portrait, it is noise.
double resolveVoteDialogPortraitSide({
  required double preferredSide,
  required double availableHeight,
  required double reservedHeight,
}) {
  if (!availableHeight.isFinite) return preferredSide;
  return math.min(
    preferredSide,
    math.max(kVoteDialogMinimumPortrait, availableHeight - reservedHeight),
  );
}

/// The smallest gap the popup keeps between the capsule and the top and bottom
/// edges of the window.
///
/// 40 (JMA) and 24 (vote) are the designed margins and they stay whenever the
/// route can still hand the capsule its controls. On a 280 high window the JMA
/// margin alone was 80 of the 280 — 29% of the screen spent on empty margin
/// while the vote button hung below the capsule's bottom edge — so on a window
/// that short the margin is what yields, not the button.
///
/// 8 is chosen against the plan's smallest acceptance size: 280x280 with a
/// validation message showing needs 230 of body, and anything above 8 leaves
/// less than that. It still reads as a margin — the capsule never touches the
/// window edge.
const double kVoteDialogMinimumVerticalInset = 8;

/// What the capsule needs the route to leave it to open with its controls
/// whole: the controls themselves, the popup's own chrome, and enough left over
/// for the decoration band to show the portrait at its floor rather than a
/// sliver of it.
double voteDialogRequiredRouteHeight(double essentialHeight) =>
    essentialHeight +
    largePopupHiddenChromeHeight() +
    kVoteDialogMinimumPortrait;

/// The vertical inset the dialog route should use.
///
/// [availableHeight] is the height the window really offers — the screen less
/// the keyboard and the system bars — and [requiredBodyHeight] is
/// [voteDialogRequiredRouteHeight]. Returns [preferredInset] whenever both fit,
/// and otherwise the largest inset that still leaves [requiredBodyHeight],
/// floored at [kVoteDialogMinimumVerticalInset]: past that the window is simply
/// too short and the body falls back to scrolling.
double resolveVoteDialogVerticalInset({
  required double preferredInset,
  required double availableHeight,
  required double requiredBodyHeight,
}) {
  if (!availableHeight.isFinite || availableHeight <= 0) return preferredInset;
  final affordable = (availableHeight - requiredBodyHeight) / 2;
  if (affordable >= preferredInset) return preferredInset;
  return math.max(kVoteDialogMinimumVerticalInset, affordable.floorToDouble());
}

/// The capsule radius, clamped so a short card's corners cannot eat the
/// controls pinned against its edges.
///
/// The default `120.r` is a quarter of a comfortable popup's height; on a
/// 190 high body it is most of it, and `Clip.antiAlias` really does cut there.
double voteDialogCardRadius(double bodyHeight) =>
    math.min(120.r, math.max(0.0, bodyHeight) / 4);

/// How much vertical room a full-width control [horizontalInset] from the
/// card's side needs before a [radius] corner stops cutting it.
///
/// A rectangular containment check does not see this: the control's bounding
/// box is inside the card's box while the arc has already taken a bite out of
/// its top left. Solving the corner circle for the control's x gives the exact
/// clearance.
double voteDialogCornerClearance({
  required double radius,
  required double horizontalInset,
}) {
  if (radius <= 0 || horizontalInset >= radius) return 0;
  final dx = radius - horizontalInset;
  return radius - math.sqrt(math.max(0.0, radius * radius - dx * dx));
}

/// The layout mode and the card radius, decided together.
///
/// They cannot be decided apart: the corner the card clips with is part of
/// whether the controls fit, and what to do about it differs by mode. Pinned
/// keeps the designed corner and is only chosen when the decoration band above
/// the controls is at least as tall as the clearance, so the arc lands on the
/// decoration. When everything scrolls, the controls sit against the card's own
/// top edge and there is no height to spare, so the corner is clamped to where
/// it can no longer reach them instead.
class VoteDialogShape {
  const VoteDialogShape({required this.mode, required this.cardBorderRadius});

  final VoteDialogLayoutMode mode;
  final BorderRadius cardBorderRadius;
}

/// A fully resolved two-column candidate.
///
/// It is deliberately immutable and derived only from the route constraints,
/// neutral content measurements and current text/locale metrics. Input value,
/// validation and loading state never feed back into this result.
class VoteDialogColumnsLayout {
  const VoteDialogColumnsLayout({
    required this.cardWidth,
    required this.bodyHeight,
    required this.leftWidth,
    required this.rightWidth,
    required this.topInset,
    required this.bottomInset,
    required this.showTopClose,
    required this.shape,
  });

  final double cardWidth;
  final double bodyHeight;
  final double leftWidth;
  final double rightWidth;
  final double topInset;
  final double bottomInset;
  final bool showTopClose;
  final VoteDialogShape shape;
}

/// Resolves the general dialog's optional two-column presentation.
///
/// This contains no orientation, aspect-ratio or device branch. Columns are
/// selected only when the neutral one-column candidate is under vertical
/// pressure, the uncapped route width can hold both measured columns, and the
/// actual column heights fit. The visible-close candidate is tried first; the
/// hidden-close candidate is used only when the extra 24px chrome does not fit.
VoteDialogColumnsLayout? resolveVoteDialogColumnsLayout({
  required double routeAvailableWidth,
  required double popupAvailableHeight,
  required double singleEssentialHeight,
  required double singleDecorationComfortHeight,
  required double singleTailLogoHeight,
  required double singleHorizontalContentInset,
  required double leftMinimumWidth,
  required double rightMinimumWidth,
  required double Function(double width) leftMinimumHeightForWidth,
  required double Function(double width) rightMinimumHeightForWidth,
  required bool keyboardVisible,
}) {
  if (keyboardVisible ||
      !routeAvailableWidth.isFinite ||
      !popupAvailableHeight.isFinite ||
      routeAvailableWidth <= 0 ||
      popupAvailableHeight <= 0) {
    return null;
  }

  final singleWidth = math.min(routeAvailableWidth, resolveVoteDialogWidth());
  if (singleWidth <= 0) return null;

  final singleCanShowTopClose =
      popupAvailableHeight - largePopupTopCloseChromeHeight() >=
      singleEssentialHeight + singleDecorationComfortHeight;
  final singleBodyHeight = math.max(
    0.0,
    popupAvailableHeight -
        (singleCanShowTopClose
            ? largePopupTopCloseChromeHeight()
            : largePopupHiddenChromeHeight()),
  );
  final singleRadius = voteDialogCardRadius(singleBodyHeight);
  final singleCornerClearance = voteDialogCornerClearance(
    radius: singleRadius,
    horizontalInset: singleHorizontalContentInset,
  );
  final singleIsUnderPressure =
      singleEssentialHeight + singleCornerClearance > singleBodyHeight ||
      singleEssentialHeight +
              singleDecorationComfortHeight +
              singleTailLogoHeight >
          singleBodyHeight;
  if (!singleIsUnderPressure) return null;

  final cardWidth = math.min(routeAvailableWidth, kVoteDialogColumnsMaxWidth);
  final fixedHorizontal =
      largePopupCardBorderWidth() * 2 +
      kVoteDialogColumnsHorizontalPadding * 2 +
      kVoteDialogColumnGap;
  final columnSpace = cardWidth - fixedHorizontal;
  if (columnSpace < leftMinimumWidth + rightMinimumWidth) return null;

  final leftUpperBound = columnSpace - rightMinimumWidth;
  final leftWidth = (columnSpace * 0.4)
      .clamp(leftMinimumWidth, leftUpperBound)
      .toDouble();
  final rightWidth = columnSpace - leftWidth;

  VoteDialogColumnsLayout? candidate({
    required bool showTopClose,
    bool allowRadiusClamp = false,
  }) {
    final bodyHeight = math.max(
      0.0,
      popupAvailableHeight -
          (showTopClose
              ? largePopupTopCloseChromeHeight()
              : largePopupHiddenChromeHeight()),
    );
    if (bodyHeight <= 0) return null;

    final horizontalInset =
        largePopupCardBorderWidth() + kVoteDialogColumnsHorizontalPadding;
    final preferredRadius = voteDialogCardRadius(bodyHeight);
    final cornerClearance = voteDialogCornerClearance(
      radius: preferredRadius,
      horizontalInset: horizontalInset,
    );
    final topInset = math.max(
      kVoteDialogColumnsVerticalPadding,
      cornerClearance,
    );
    final bottomInset = math.max(
      kVoteDialogColumnsVerticalPadding,
      cornerClearance,
    );
    final leftHeight = leftMinimumHeightForWidth(leftWidth);
    final rightHeight = rightMinimumHeightForWidth(rightWidth);
    final columnHeight = math.max(leftHeight, rightHeight);
    final requiredHeight = topInset + columnHeight + bottomInset;
    if (columnHeight + kVoteDialogColumnsVerticalPadding * 2 > bodyHeight) {
      return null;
    }
    if (!allowRadiusClamp && requiredHeight > bodyHeight) return null;

    // resolveVoteDialogShape performs the authoritative radius/mode solve. Its
    // internal corner clearance plus this essential value equals the
    // symmetric top/bottom clearance checked above. If neither chrome variant
    // can keep the preferred radius, the hidden-close candidate may accept
    // the solver's smaller radius rather than clip a control.
    final shape = resolveVoteDialogShape(
      bodyHeight: bodyHeight,
      essentialHeight: columnHeight + topInset + bottomInset - cornerClearance,
      horizontalContentInset: horizontalInset,
    );
    if (!allowRadiusClamp && shape.mode != VoteDialogLayoutMode.actionsPinned) {
      return null;
    }

    final resolvedRadius = shape.cardBorderRadius.topLeft.x;
    final resolvedTopInset = math.max(
      kVoteDialogColumnsVerticalPadding,
      voteDialogCornerClearance(
        radius: resolvedRadius,
        horizontalInset: horizontalInset,
      ),
    );
    final resolvedBottomInset = math.max(
      kVoteDialogColumnsVerticalPadding,
      voteDialogCornerClearance(
        radius: resolvedRadius,
        horizontalInset: horizontalInset,
      ),
    );
    if (resolvedTopInset + columnHeight + resolvedBottomInset > bodyHeight) {
      return null;
    }

    return VoteDialogColumnsLayout(
      cardWidth: cardWidth,
      bodyHeight: bodyHeight,
      leftWidth: leftWidth,
      rightWidth: rightWidth,
      topInset: resolvedTopInset,
      bottomInset: resolvedBottomInset,
      showTopClose: showTopClose,
      shape: shape,
    );
  }

  return candidate(showTopClose: true) ??
      candidate(showTopClose: false) ??
      candidate(showTopClose: false, allowRadiusClamp: true);
}

VoteDialogShape resolveVoteDialogShape({
  required double bodyHeight,
  required double essentialHeight,
  required double horizontalContentInset,
}) {
  final preferred = voteDialogCardRadius(bodyHeight);
  final clearance = voteDialogCornerClearance(
    radius: preferred,
    horizontalInset: horizontalContentInset,
  );
  final mode = selectVoteDialogLayout(
    bodyHeight: bodyHeight - clearance,
    essentialHeight: essentialHeight,
  );
  return VoteDialogShape(
    mode: mode,
    cardBorderRadius: BorderRadius.circular(
      mode == VoteDialogLayoutMode.actionsPinned
          ? preferred
          : math.min(preferred, horizontalContentInset),
    ),
  );
}

/// The popup body as bands with an explicit yielding order.
///
/// Visual order is unchanged from before this policy existed:
/// decoration → [actions] → [submit] → [tail]. What changed is which of them
/// may shrink. [actions], [submit] and [tail] are laid out first at their
/// natural height; the decoration is a `Flexible.loose` scroll view that takes
/// whatever is left, so it scrolls instead of pushing the controls out.
///
/// The decoration is built through [decorationBuilder] rather than passed as a
/// widget because it is handed the height it actually got: the portrait can
/// then shrink toward [kVoteDialogMinimumPortrait] instead of leaving a sliver
/// of itself on a very short body. The height a `Flexible` hands out depends
/// only on the non-flexible siblings, so measuring it cannot feed back into
/// itself.
class VoteDialogBands extends StatelessWidget {
  const VoteDialogBands({
    super.key,
    required this.mode,
    required this.decorationBuilder,
    required this.actions,
    required this.submit,
    required this.tail,
  });

  /// Which arrangement to use, from [selectVoteDialogLayout].
  final VoteDialogLayoutMode mode;

  /// Portrait, names, balance and the informational panels — everything that
  /// may scroll out of the first screen. Receives the height available to it,
  /// or [double.infinity] when the whole body scrolls.
  final Widget Function(BuildContext context, double availableHeight)
  decorationBuilder;

  /// Use all + amount input + the validation line under it.
  final Widget actions;

  /// The vote button.
  final Widget submit;

  /// The logo under the button when it fits, and the body's bottom padding.
  final Widget tail;

  @override
  Widget build(BuildContext context) {
    if (mode == VoteDialogLayoutMode.allScroll) {
      // Nothing can be promised a fixed place, so the order becomes the
      // priority order and the input is what the popup opens on.
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            actions,
            submit,
            decorationBuilder(context, double.infinity),
            tail,
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: decorationBuilder(
                context,
                constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : double.infinity,
              ),
            ),
          ),
        ),
        actions,
        submit,
        tail,
      ],
    );
  }
}

/// Two independently scrolling columns with the critical content first.
///
/// The caller measures the identity/balance block and the complete action
/// block before selecting this widget, so all of those controls are visible at
/// offset zero. Optional details may continue below them inside their own
/// column without changing the other column's geometry.
class VoteDialogColumns extends StatelessWidget {
  const VoteDialogColumns({
    super.key,
    required this.layout,
    required this.left,
    required this.right,
  });

  final VoteDialogColumnsLayout layout;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.bodyHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          kVoteDialogColumnsHorizontalPadding,
          layout.topInset,
          kVoteDialogColumnsHorizontalPadding,
          layout.bottomInset,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: layout.leftWidth,
              height: double.infinity,
              child: SingleChildScrollView(child: left),
            ),
            const SizedBox(width: kVoteDialogColumnGap),
            SizedBox(
              width: layout.rightWidth,
              height: double.infinity,
              child: SingleChildScrollView(child: right),
            ),
          ],
        ),
      ),
    );
  }
}
