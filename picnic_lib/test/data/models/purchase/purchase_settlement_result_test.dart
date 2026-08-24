import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';

void main() {
  final cases =
      (jsonDecode(
                File(
                  'test/fixtures/wallet_contracts/purchase_results_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['cases']
          as List<dynamic>;

  test('canonical fixture parses every promotion state', () {
    final results = cases
        .map(
          (value) => PurchaseSettlementResultModel.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    expect(results.map((e) => e.promotion!.state), [
      PurchasePromotionState.pendingTime,
      PurchasePromotionState.ineligible,
      PurchasePromotionState.granted,
    ]);
    expect(results.last.promotion!.promoBonusAmount, BigInt.from(20));
  });

  test('canonical fixture preserves the replayed flag', () {
    final results = cases
        .map(
          (value) => PurchaseSettlementResultModel.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    expect(results.map((e) => e.replayed), [false, false, true]);
  });

  test('canonical parser rejects numeric amount and null promotion', () {
    final numeric = Map<String, dynamic>.from(cases.first as Map);
    numeric['base_star_amount'] = 100;
    expect(
      () => PurchaseSettlementResultModel.fromJson(numeric),
      throwsA(anything),
    );
    final absent = Map<String, dynamic>.from(cases.first as Map)
      ..['promotion'] = null;
    expect(
      () => PurchaseSettlementResultModel.fromJson(absent),
      throwsFormatException,
    );
  });

  test('legacy parser alone accepts null promotion', () {
    final legacy = Map<String, dynamic>.from(cases.first as Map)
      ..['promotion'] = null;
    expect(
      PurchaseSettlementResultModel.fromLegacyJson(legacy).promotion,
      isNull,
    );
  });

  test('promotion domain and amount invariants are strict', () {
    final pending = Map<String, dynamic>.from(cases.first as Map);
    pending['promotion'] = {
      ...Map<String, dynamic>.from(pending['promotion'] as Map),
      'domain_code': null,
    };
    expect(
      () => PurchaseSettlementResultModel.fromJson(pending),
      throwsFormatException,
    );

    final ineligible = Map<String, dynamic>.from(cases[1] as Map);
    ineligible['promotion'] = {
      ...Map<String, dynamic>.from(ineligible['promotion'] as Map),
      'promo_bonus_amount': '1',
    };
    expect(
      () => PurchaseSettlementResultModel.fromJson(ineligible),
      throwsFormatException,
    );
  });

  group('forward-compatible revenue keys (currency/value)', () {
    Map<String, dynamic> base() =>
        Map<String, dynamic>.from(cases.first as Map);

    test('7 canonical keys plus currency and value parse into the model', () {
      final json = base()
        ..['currency'] = 'USD'
        ..['value'] = '1.99';
      final result = PurchaseSettlementResultModel.fromJson(json);
      expect(result.currency, 'USD');
      expect(result.value, 1.99);
    });

    test('todays production shape (7 keys only) still parses, both null', () {
      final result = PurchaseSettlementResultModel.fromJson(base());
      expect(result.currency, isNull);
      expect(result.value, isNull);
    });

    test('currency without value is preserved asymmetrically (B-3)', () {
      final json = base()..['currency'] = 'KRW';
      final result = PurchaseSettlementResultModel.fromJson(json);
      expect(result.currency, 'KRW');
      expect(result.value, isNull);
    });

    test('explicit nulls are treated the same as absent keys', () {
      final json = base()
        ..['currency'] = null
        ..['value'] = null;
      final result = PurchaseSettlementResultModel.fromJson(json);
      expect(result.currency, isNull);
      expect(result.value, isNull);
    });

    test('value without currency parses; the value is only a candidate', () {
      final json = base()..['value'] = '1.99';
      final result = PurchaseSettlementResultModel.fromJson(json);
      expect(result.currency, isNull);
      expect(result.value, 1.99);
    });

    test('value must be a decimal string, never a JSON number', () {
      final json = base()
        ..['currency'] = 'USD'
        ..['value'] = 1.99;
      // Same convention as the numeric base_star_amount case above: the
      // converter throws, json_serializable's checked mode rewraps it.
      expect(
        () => PurchaseSettlementResultModel.fromJson(json),
        throwsA(anything),
      );
    });

    test('a third key outside the contract still fails drift detection', () {
      final json = base()
        ..['currency'] = 'USD'
        ..['foo'] = 'bar';
      expect(
        () => PurchaseSettlementResultModel.fromJson(json),
        throwsFormatException,
      );
    });

    test('a missing required key still throws', () {
      final json = base()
        ..['currency'] = 'USD'
        ..remove('operation_id');
      expect(
        () => PurchaseSettlementResultModel.fromJson(json),
        throwsFormatException,
      );
    });

    test('the legacy parser does not accept the optional revenue keys', () {
      final json = base()
        ..['promotion'] = null
        ..['currency'] = 'USD';
      expect(
        () => PurchaseSettlementResultModel.fromLegacyJson(json),
        throwsFormatException,
      );
    });
  });
}
