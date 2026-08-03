import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/admin/payment_breakdown.dart';
import 'package:picnic_lib/data/repositories/admin_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _clientFor(
  Object response, {
  void Function(Uri uri, Map<String, dynamic> body)? onRequest,
}) {
  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
    httpClient: MockClient((request) async {
      onRequest?.call(
        request.url,
        jsonDecode(request.body) as Map<String, dynamic>,
      );
      return http.Response(
        jsonEncode(response),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

void main() {
  test(
    'sends the platform breakdown RPC contract and parses Supabase JSON numbers',
    () async {
      late Uri requestedUri;
      late Map<String, dynamic> requestedBody;
      final repository = AdminRepository(
        _clientFor(
          [
            {'key': 'google_play', 'pay_cnt': 12, 'revenue_usd': 32.5},
          ],
          onRequest: (uri, body) {
            requestedUri = uri;
            requestedBody = body;
          },
        ),
      );

      final items = await repository.getPaymentBreakdown(
        dimension: PaymentBreakdownDimension.platform,
      );

      expect(requestedUri.path, contains('/rpc/get_payment_breakdown'));
      expect(requestedBody, {
        'p_start': null,
        'p_end': null,
        'p_dimension': 'platform',
      });
      expect(items, hasLength(1));
      expect(items.single.key, 'google_play');
      expect(items.single.payCount, BigInt.from(12));
      expect(items.single.revenueUsd, '32.5');
    },
  );

  test(
    'preserves exact integer and decimal strings when already provided',
    () async {
      final repository = AdminRepository(
        _clientFor([
          {
            'key': 'google_play',
            'pay_cnt': '9007199254740993',
            'revenue_usd': '123456789.123456789',
          },
        ]),
      );

      final item = (await repository.getPaymentBreakdown(
        dimension: PaymentBreakdownDimension.platform,
      )).single;

      expect(item.payCount, BigInt.parse('9007199254740993'));
      expect(item.revenueUsd, '123456789.123456789');
    },
  );

  test(
    'sends the product dimension and rejects malformed breakdown rows',
    () async {
      late Map<String, dynamic> requestedBody;
      final repository = AdminRepository(
        _clientFor([
          {
            'key': 'star_candy_100',
            'pay_cnt': 'not-an-integer',
            'revenue_usd': '12.50',
          },
        ], onRequest: (_, body) => requestedBody = body),
      );

      await expectLater(
        repository.getPaymentBreakdown(
          dimension: PaymentBreakdownDimension.product,
        ),
        throwsFormatException,
      );
      expect(requestedBody, {
        'p_start': null,
        'p_end': null,
        'p_dimension': 'product',
      });
    },
  );

  for (final invalid in <({String name, Map<String, Object?> row})>[
    (
      name: 'a non-string key',
      row: {'key': 1, 'pay_cnt': 1, 'revenue_usd': 1.0},
    ),
    (name: 'an empty key', row: {'key': '', 'pay_cnt': 1, 'revenue_usd': 1.0}),
    (
      name: 'a fractional pay count',
      row: {'key': 'google_play', 'pay_cnt': 1.5, 'revenue_usd': 1.0},
    ),
    (
      name: 'a non-decimal revenue',
      row: {'key': 'google_play', 'pay_cnt': 1, 'revenue_usd': true},
    ),
    (
      name: 'an unexpected key',
      row: {
        'key': 'google_play',
        'pay_cnt': 1,
        'revenue_usd': 1.0,
        'unexpected': true,
      },
    ),
  ]) {
    test('rejects a payment breakdown row with ${invalid.name}', () async {
      final repository = AdminRepository(_clientFor([invalid.row]));

      await expectLater(
        repository.getPaymentBreakdown(
          dimension: PaymentBreakdownDimension.platform,
        ),
        throwsFormatException,
      );
    });
  }

  test('rejects non-finite numeric revenue before it reaches the UI', () {
    expect(
      () => PaymentBreakdownItem.fromJson({
        'key': 'google_play',
        'pay_cnt': 1,
        'revenue_usd': double.nan,
      }),
      throwsFormatException,
    );
    expect(
      () => PaymentBreakdownItem.fromJson({
        'key': 'google_play',
        'pay_cnt': 1,
        'revenue_usd': double.infinity,
      }),
      throwsFormatException,
    );
  });
}
