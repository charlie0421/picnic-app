import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

void main() {
  Map<String, dynamic> fixture(String name) =>
      jsonDecode(
            File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('pending fixture has the exact canonical keys and null grant', () {
    final json = fixture('ad_reward_pending_v1.json');
    expect(json.keys.toSet(), {
      'reference',
      'state',
      'grant',
      'wallet',
      'snapshot_at',
    });
    expect(json['grant'], isNull);
    expect(AdRewardStatusModel.fromJson(json).state, AdRewardState.pending);
  });

  test('granted fixture parses decimal strings and nested wallet', () {
    final json = fixture('ad_reward_granted_v1.json');
    final status = AdRewardStatusModel.fromJson(json);
    expect((json['grant'] as Map).keys.toSet(), {
      'id',
      'currency',
      'amount',
      'granted_at',
      'expires_at',
    });
    expect(status.state, AdRewardState.granted);
    expect(status.grant!.currency, WalletCurrency.cottonCandy);
    expect(status.grant!.amount, BigInt.from(3));
    expect(status.wallet.cotton, BigInt.from(8));
  });

  test('rejects aliases, missing nullable keys, and numeric amounts', () {
    final valid = fixture('ad_reward_granted_v1.json');
    final cases = <Map<String, dynamic>>[
      {...valid}..['status'] = (Map.of(valid)..remove('state'))['state'],
      {...valid}..remove('grant'),
      {...valid, 'grant_amount': '3'},
      {...valid, 'wallet_cotton': '8'},
      {
        ...valid,
        'grant': {...valid['grant'] as Map, 'amount': 3},
      },
      {
        ...valid,
        'wallet': {...valid['wallet'] as Map, 'cotton': 8},
      },
    ];
    for (final value in cases) {
      expect(() => AdRewardStatusModel.fromJson(value), throwsFormatException);
    }
  });

  test('page rejects numeric total_count and omitted next_cursor', () {
    final item = fixture('ad_reward_pending_v1.json');
    final base = {
      'items': [item],
      'total_count': '1',
      'next_cursor': null,
      'snapshot_at': '2026-07-21T00:00:00.000Z',
    };
    expect(AdRewardPageModel.fromJson(base).totalCount, BigInt.one);
    expect(
      () => AdRewardPageModel.fromJson({...base, 'total_count': 1}),
      throwsFormatException,
    );
    expect(
      () => AdRewardPageModel.fromJson({...base}..remove('next_cursor')),
      throwsFormatException,
    );
  });

  test('wrong primitive/container and unknown states are FormatException', () {
    final valid = fixture('ad_reward_pending_v1.json');
    final cases = <Map<String, dynamic>>[
      {...valid, 'reference': 'not-a-map'},
      {
        ...valid,
        'reference': {'type': 'UNKNOWN', 'id': 'id'},
      },
      {...valid, 'state': 'UNKNOWN'},
      {...valid, 'wallet': []},
      {...valid, 'snapshot_at': 123},
    ];
    for (final value in cases) {
      expect(() => AdRewardStatusModel.fromJson(value), throwsFormatException);
    }
  });

  test('shortform wrong primitive/container values are FormatException', () {
    final valid = <String, dynamic>{
      'ok': true,
      'reward_added': 3,
      'impression_id': '00000000-0000-4000-8000-000000000402',
      'new_bonus': 9,
    };
    for (final value in <Map<String, dynamic>>[
      {...valid, 'ok': 'true'},
      {...valid, 'reward_added': '3'},
      {...valid, 'new_bonus': '9'},
      {...valid, 'reward': []},
    ]) {
      expect(
        () => InternalShortformViewResponse.fromJson(value),
        throwsFormatException,
      );
    }
  });
}
