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
    'sends the platform breakdown RPC contract and preserves exact values',
    () async {
      late Uri requestedUri;
      late Map<String, dynamic> requestedBody;
      final repository = AdminRepository(
        _clientFor(
          [
            {
              'key': 'google_play',
              'pay_cnt': '9007199254740993',
              'revenue_usd': '123456789.123456789',
            },
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
      expect(items.single.payCount, BigInt.parse('9007199254740993'));
      expect(items.single.revenueUsd, '123456789.123456789');
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
}
