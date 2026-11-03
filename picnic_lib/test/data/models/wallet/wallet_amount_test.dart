import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

void main() {
  group('WalletAmountConverter', () {
    test('parses decimal strings beyond JavaScript safe integer range', () {
      expect(
        const WalletAmountConverter().fromJson('9007199254740993'),
        BigInt.parse('9007199254740993'),
      );
    });

    test('rejects JSON numbers and non-decimal strings', () {
      expect(
        () => const WalletAmountConverter().fromJson(42),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => const WalletAmountConverter().fromJson('1.5'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('wallet currency uses stable wire values', () {
    expect(WalletCurrency.starCandy.wireValue, 'STAR_CANDY');
    expect(
      WalletCurrencyWire.parse('BONUS_STAR_CANDY'),
      WalletCurrency.bonusStarCandy,
    );
    expect(
      WalletCurrencyWire.parse('COTTON_CANDY'),
      WalletCurrency.cottonCandy,
    );
    expect(
      () => WalletCurrencyWire.parse('STAR'),
      throwsA(isA<FormatException>()),
    );
  });

  test('formats wallet amounts with thousands separators', () {
    expect(formatWalletAmount(BigInt.zero), '0');
    expect(
      formatWalletAmount(BigInt.parse('9007199254740993')),
      '9,007,199,254,740,993',
    );
    expect(formatWalletAmount(BigInt.from(-1234567)), '-1,234,567');
  });

  group('requireContractKeys', () {
    const required = {'a', 'b'};
    const optional = {'c'};

    test('accepts exactly the required keys and normalises optionals to null', () {
      final result = requireContractKeys(
        {'a': 1, 'b': 2},
        required: required,
        optional: optional,
      );
      expect(result.keys.toSet(), {'a', 'b', 'c'});
      expect(result['c'], isNull);
    });

    test('accepts required plus a named optional key', () {
      final result = requireContractKeys(
        {'a': 1, 'b': 2, 'c': 3},
        required: required,
        optional: optional,
      );
      expect(result['c'], 3);
    });

    test('treats an explicit null optional the same as an absent one', () {
      final result = requireContractKeys(
        {'a': 1, 'b': 2, 'c': null},
        required: required,
        optional: optional,
      );
      expect(result['c'], isNull);
    });

    test('still rejects a missing required key', () {
      expect(
        () => requireContractKeys(
          {'a': 1, 'c': 3},
          required: required,
          optional: optional,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('still rejects an unnamed extra key', () {
      expect(
        () => requireContractKeys(
          {'a': 1, 'b': 2, 'z': 9},
          required: required,
          optional: optional,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('does not loosen requireExactContractKeys', () {
      expect(
        () => requireExactContractKeys({'a': 1, 'b': 2, 'c': 3}, required),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
