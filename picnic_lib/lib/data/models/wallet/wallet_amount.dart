import 'package:freezed_annotation/freezed_annotation.dart';

enum WalletCurrency { starCandy, bonusStarCandy, cottonCandy }

extension WalletCurrencyWire on WalletCurrency {
  String get wireValue => switch (this) {
    WalletCurrency.starCandy => 'STAR_CANDY',
    WalletCurrency.bonusStarCandy => 'BONUS_STAR_CANDY',
    WalletCurrency.cottonCandy => 'COTTON_CANDY',
  };

  static WalletCurrency parse(String value) => switch (value) {
    'STAR_CANDY' => WalletCurrency.starCandy,
    'BONUS_STAR_CANDY' => WalletCurrency.bonusStarCandy,
    'COTTON_CANDY' => WalletCurrency.cottonCandy,
    _ => throw FormatException('Unknown wallet currency: $value'),
  };
}

class WalletCurrencyConverter implements JsonConverter<WalletCurrency, String> {
  const WalletCurrencyConverter();

  @override
  WalletCurrency fromJson(String value) => WalletCurrencyWire.parse(value);

  @override
  String toJson(WalletCurrency value) => value.wireValue;
}

class WalletAmountConverter implements JsonConverter<BigInt, Object?> {
  const WalletAmountConverter();

  @override
  BigInt fromJson(Object? value) {
    if (value is! String || !RegExp(r'^-?[0-9]+$').hasMatch(value)) {
      throw const FormatException('Wallet amount must be a decimal string');
    }
    return BigInt.parse(value);
  }

  @override
  Object toJson(BigInt value) => value.toString();
}

Map<String, dynamic> requireExactContractKeys(
  Map<String, dynamic> json,
  Set<String> expected,
) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException(
      'Contract keys differ: expected $expected, got $actual',
    );
  }
  return json;
}

/// Like [requireExactContractKeys], but with a named set of optional keys.
///
/// Drift detection is unchanged for everything that is not named: a missing
/// required key or any key outside `required ∪ optional` still throws. The one
/// thing that is allowed is a key the caller declared optional up front.
///
/// The returned map always contains every allowed key, so callers (and the
/// generated `fromJson` code) can treat "absent" and "explicitly null" as the
/// same thing.
Map<String, dynamic> requireContractKeys(
  Map<String, dynamic> json, {
  required Set<String> required,
  required Set<String> optional,
}) {
  final actual = json.keys.toSet();
  final allowed = {...required, ...optional};
  if (!actual.containsAll(required) || !allowed.containsAll(actual)) {
    throw FormatException(
      'Contract keys differ: required $required, optional $optional, '
      'got $actual',
    );
  }
  return {for (final key in allowed) key: json[key]};
}

String formatWalletAmount(BigInt amount) {
  final negative = amount.isNegative;
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return negative ? '-$grouped' : grouped;
}
