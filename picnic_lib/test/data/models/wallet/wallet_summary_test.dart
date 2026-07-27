import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

void main() {
  late Map<String, dynamic> json;

  setUp(() {
    json =
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/wallet_summary_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
  });

  test('parses the canonical wallet.v1 summary fixture', () {
    final summary = WalletSummaryModel.fromJson(json);

    expect(summary.contractVersion, 'wallet.v1');
    expect(summary.star, BigInt.parse('9007199254740993'));
    expect(summary.bonus, BigInt.from(250));
    expect(summary.cotton, BigInt.from(40));
    expect(summary.cottonExpiringAmount, BigInt.from(10));
    expect(summary.cottonNextExpiresAt, DateTime.utc(2026, 7, 22));
    expect(summary.snapshotAt, DateTime.utc(2026, 7, 21));
  });

  test('requires exactly the canonical summary keys', () {
    expect(json.keys.toSet(), {
      'contract_version',
      'star',
      'bonus',
      'cotton',
      'cotton_expiring_amount',
      'cotton_next_expires_at',
      'snapshot_at',
    });
    expect(
      () => WalletSummaryModel.fromJson({...json, 'star_balance': '1'}),
      throwsFormatException,
    );
    expect(
      () => WalletSummaryModel.fromJson(
        Map<String, dynamic>.from(json)..remove('cotton_next_expires_at'),
      ),
      throwsFormatException,
    );
  });
}
