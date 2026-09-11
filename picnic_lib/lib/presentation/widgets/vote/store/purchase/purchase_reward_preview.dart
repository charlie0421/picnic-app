import 'package:flutter/foundation.dart' show immutable;

/// The multiplier range the V2 settlement path can actually honor (1.1x-3.0x).
///
/// A record outside it is malformed for display purposes: previewing a bonus
/// from it would advertise candy the purchase path will not grant.
const int kMinCandyBoostMultiplierTenths = 11;
const int kMaxCandyBoostMultiplierTenths = 30;

/// The candy a purchase is expected to grant, split into the three parts the
/// user is shown: the catalog base, the catalog bonus, and the promotion's
/// extra bonus.
///
/// Pure and exact (BigInt throughout) so the product card, the purchase
/// confirmation and any future surface all quote the *same* number. The server
/// stays authoritative — this is a preview computed from the same rules, not a
/// promise — so every surface that renders it must label it as an estimate.
@immutable
class PurchaseRewardPreview {
  /// [multiplierTenths] is the exact V2 record (integer tenths);
  /// [extraBonusBps] the legacy V1 basis-point record. Passing neither (or a
  /// malformed value) previews the catalog reward with no event bonus - a
  /// missing campaign must never invent one.
  factory PurchaseRewardPreview({
    required BigInt base,
    required BigInt productBonus,
    int? multiplierTenths,
    int? extraBonusBps,
  }) {
    // A negative catalog amount is malformed input, not a debt to display.
    final safeBase = base > BigInt.zero ? base : BigInt.zero;
    final safeProductBonus = productBonus > BigInt.zero
        ? productBonus
        : BigInt.zero;
    final eventBonus = _eventBonus(
      safeBase + safeProductBonus,
      multiplierTenths,
      extraBonusBps,
    );
    return PurchaseRewardPreview._(
      base: safeBase,
      productBonus: safeProductBonus,
      eventBonus: eventBonus,
      totalMultiplierTenths: eventBonus > BigInt.zero
          ? _advertisableTenths(multiplierTenths, extraBonusBps)
          : null,
    );
  }

  const PurchaseRewardPreview._({
    required this.base,
    required this.productBonus,
    required this.eventBonus,
    required this.totalMultiplierTenths,
  });

  /// Star candy the catalog row grants.
  final BigInt base;

  /// Bonus star candy the catalog row grants, before any promotion.
  final BigInt productBonus;

  /// Extra bonus star candy the promotion is expected to add.
  final BigInt eventBonus;

  /// What the promotion multiplies: the whole catalog reward, not just [base].
  BigInt get baseTotal => base + productBonus;

  BigInt get expectedTotal => baseTotal + eventBonus;

  bool get hasEventBonus => eventBonus > BigInt.zero;

  bool get hasProductBonus => productBonus > BigInt.zero;

  /// The *total* multiplier a compact pill may advertise, in integer tenths
  /// (20 -> "2", 15 -> "1.5"), or null when no pill can state this campaign
  /// truthfully. See [_advertisableTenths].
  final int? totalMultiplierTenths;
}

/// The total multiplier that may be advertised for a campaign record.
///
/// Read from the **record**, never derived from the previewed amounts.
/// Deriving it has to round, and rounding a multiplier overstates the payout:
/// V1 1500bps pays 115 on a 100-candy product (1.15x), which one decimal
/// rounds to "1.2x" - candy the settlement will not grant. The same
/// derivation inflates V2's minimum-increment case, where 1 candy at 1.1x
/// pays 2 and would advertise a 2x campaign that does not exist.
///
/// So: an exact V2 record states itself, a V1 record states itself only when
/// its total lands exactly on a tenth, and anything else shows no pill at all
/// (the explicit +amount is still there, and it is always exact).
int? _advertisableTenths(int? multiplierTenths, int? extraBonusBps) {
  if (multiplierTenths != null) {
    // Integer tenths already, validated against the range settlement honors.
    return (multiplierTenths >= kMinCandyBoostMultiplierTenths &&
            multiplierTenths <= kMaxCandyBoostMultiplierTenths)
        ? multiplierTenths
        : null;
  }
  if (extraBonusBps == null || extraBonusBps <= 0) return null;
  // 10000 + bps is the total multiplier in basis points: 10000 -> 2.0x and
  // 5000 -> 1.5x land on a tenth; 1500 -> 1.15x does not.
  final totalBps = 10000 + extraBonusBps;
  if (totalBps % 1000 != 0) return null;
  final tenths = totalBps ~/ 1000;
  return tenths > 10 ? tenths : null;
}

BigInt _eventBonus(
  BigInt baseTotal,
  int? multiplierTenths,
  int? extraBonusBps,
) {
  if (baseTotal <= BigInt.zero) return BigInt.zero;
  if (multiplierTenths != null) {
    if (multiplierTenths < kMinCandyBoostMultiplierTenths ||
        multiplierTenths > kMaxCandyBoostMultiplierTenths) {
      return BigInt.zero;
    }
    // V2 settlement math, mirrored exactly:
    //   gross = max(baseTotal + 1, floor(baseTotal * tenths / 10))
    // The floor can swallow the whole bonus on tiny amounts, so V2 guarantees
    // at least one extra candy.
    final scaled = baseTotal * BigInt.from(multiplierTenths) ~/ BigInt.from(10);
    final atLeastOneMore = baseTotal + BigInt.one;
    final gross = scaled > atLeastOneMore ? scaled : atLeastOneMore;
    return gross - baseTotal;
  }
  if (extraBonusBps != null && extraBonusBps > 0) {
    // V1 math: floor(baseTotal * bps / 10000). No minimum - a bps small
    // enough to floor to zero grants nothing, and the preview says so.
    return baseTotal * BigInt.from(extraBonusBps) ~/ BigInt.from(10000);
  }
  return BigInt.zero;
}

/// Reads a server catalog row into a preview.
///
/// Supabase `products` uses `star_candy_bonus`; older/web catalog payloads use
/// `bonus_star_candy`. Anything that is not a whole positive number reads as
/// zero: a malformed row must degrade to "no bonus", never to a crash inside a
/// list item builder.
PurchaseRewardPreview purchaseRewardPreviewForProduct(
  Map<String, dynamic> serverProduct, {
  required int? multiplierTenths,
  required int? extraBonusBps,
}) => PurchaseRewardPreview(
  base: _catalogAmount(serverProduct['star_candy']),
  productBonus: _catalogAmount(
    serverProduct['star_candy_bonus'] ?? serverProduct['bonus_star_candy'],
  ),
  multiplierTenths: multiplierTenths,
  extraBonusBps: extraBonusBps,
);

BigInt _catalogAmount(Object? value) {
  if (value is int) return BigInt.from(value);
  if (value is num) {
    // Floating-point catalog values must be whole and inside the safe integer
    // range. Otherwise truncation/clamping can advertise an invented amount.
    // Larger exact amounts must arrive as integer strings, handled below.
    if (!value.isFinite ||
        value.abs() > 9007199254740991 ||
        value != value.truncateToDouble()) {
      return BigInt.zero;
    }
    return BigInt.from(value.toInt());
  }
  if (value is String) return BigInt.tryParse(value.trim()) ?? BigInt.zero;
  return BigInt.zero;
}
