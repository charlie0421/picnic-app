import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

void main() {
  const pageKeys = {'items', 'total_count', 'next_cursor', 'snapshot_at'};
  const itemKeys = {
    'id',
    'currency',
    'event_type',
    'origin',
    'delta',
    'balance_effect',
    'expires_at',
    'purchase_id',
    'refund_id',
    'grant_id',
    'operation_id',
    'created_at',
  };

  Map<String, dynamic> fixture(String name) =>
      jsonDecode(
            File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('parses canonical empty and mixed history pages', () {
    final empty = CurrencyHistoryPageModel.fromJson(
      fixture('currency_history_empty_v1.json'),
    );
    final mixedJson = fixture('currency_history_mixed_v1.json');
    final mixed = CurrencyHistoryPageModel.fromJson(mixedJson);

    expect(empty.items, isEmpty);
    expect(empty.totalCount, BigInt.zero);
    expect(mixed.totalCount, BigInt.from(2));
    expect(mixed.items, hasLength(2));
    expect(mixed.items.first.currency, WalletCurrency.starCandy);
    expect(mixed.items.first.delta, BigInt.from(100));
    expect(mixed.items.last.currency, WalletCurrency.cottonCandy);
    expect(mixed.items.last.delta, BigInt.from(-5));
    expect(mixed.snapshotAt, DateTime.utc(2026, 7, 21));
  });

  test('requires exact page and item key sets', () {
    final json = fixture('currency_history_mixed_v1.json');
    final items = json['items'] as List<dynamic>;

    expect(json.keys.toSet(), pageKeys);
    for (final item in items.cast<Map<String, dynamic>>()) {
      expect(item.keys.toSet(), itemKeys);
    }
    expect(
      () => CurrencyHistoryPageModel.fromJson({...json, 'star_balance': '1'}),
      throwsFormatException,
    );

    final itemWithAlias = Map<String, dynamic>.from(
      items.first as Map<String, dynamic>,
    )..['cotton_balance'] = '1';
    expect(
      () => CurrencyHistoryItemModel.fromJson(itemWithAlias),
      throwsFormatException,
    );
  });

  test('does not treat nullable reference keys as optional', () {
    final json = fixture('currency_history_mixed_v1.json');
    final item = Map<String, dynamic>.from(
      (json['items'] as List<dynamic>).first as Map<String, dynamic>,
    );

    for (final key in ['expires_at', 'purchase_id', 'refund_id', 'grant_id']) {
      expect(
        () => CurrencyHistoryItemModel.fromJson(
          Map<String, dynamic>.from(item)..remove(key),
        ),
        throwsFormatException,
        reason: '$key must remain present even when nullable',
      );
    }
  });

  test('rejects JSON numbers at all decimal-string boundaries', () {
    final json = fixture('currency_history_mixed_v1.json');
    final item = Map<String, dynamic>.from(
      (json['items'] as List<dynamic>).first as Map<String, dynamic>,
    )..['delta'] = 42;
    expect(() => CurrencyHistoryItemModel.fromJson(item), throwsA(anything));
    expect(
      () => CurrencyHistoryPageModel.fromJson({...json, 'total_count': 2}),
      throwsA(anything),
    );
  });
}
