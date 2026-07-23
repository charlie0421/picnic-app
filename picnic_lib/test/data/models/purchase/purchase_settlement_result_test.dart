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
}
