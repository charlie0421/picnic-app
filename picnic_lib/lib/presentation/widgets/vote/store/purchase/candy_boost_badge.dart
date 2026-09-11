import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_palette.dart';
import 'package:picnic_lib/ui/style.dart';

/// The compact event-bonus rate pill shown on a store product
/// while a candy boost event is running.
///
/// It deliberately takes the multiplier, not a caption: the campaign's own
/// `display_name` is internal copy (a test campaign name, or the machine code
/// it falls back to) and repeating it on every product row is what broke the
/// list. The campaign is named once, above the list; each row only carries the
/// number that changes what the user gets.
class CandyBoostBadge extends StatelessWidget {
  const CandyBoostBadge({super.key, required this.totalMultiplierTenths});

  /// Integer tenths of the **total** multiplier (20 -> 2x, 15 -> 1.5x).
  final int totalMultiplierTenths;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).candy_boost_total_multiplier(
      formatCandyBoostBonusPercent(totalMultiplierTenths),
    );
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [kCandyBoostPurple, kCandyBoostPink],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        // The pill lives in a row next to a product title that may be long and
        // in a slot that shrinks with the text scale. Scaling down keeps it one
        // legible line instead of wrapping into an overflow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: getTextStyle(AppTypo.caption10SB, Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Converts a total multiplier in tenths to the extra event-bonus percentage.
/// For example, 20 (2x total units) is presented as a 100% event bonus. This
/// avoids implying that star candy and bonus star candy have equal value.
String formatCandyBoostBonusPercent(int totalMultiplierTenths) =>
    '${(totalMultiplierTenths - 10) * 10}';
