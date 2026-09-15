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

/// The capsule radius, clamped so a short card's corners cannot eat the
/// controls pinned against its edges.
///
/// The default `120.r` is a quarter of a comfortable popup's height; on a
/// 190 high body it is most of it, and `Clip.antiAlias` really does cut there.
BorderRadius voteDialogCardBorderRadius(double bodyHeight) =>
    BorderRadius.circular(math.min(120.r, math.max(0.0, bodyHeight) / 4));

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
