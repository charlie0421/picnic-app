import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Map<String, dynamic> fixture(String name) =>
      jsonDecode(
            File('test/fixtures/wallet_contracts/$name').readAsStringSync(),
          )
          as Map<String, dynamic>;

  test(
    'getSummary calls the wallet summary RPC and parses its response',
    () async {
      late Uri requestedUri;
      late String requestedMethod;
      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          requestedMethod = request.method;
          return http.Response(
            jsonEncode(fixture('wallet_summary_v1.json')),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final summary = await WalletRepository(client).getSummary();

      expect(requestedMethod, 'POST');
      expect(requestedUri.path, contains('/rpc/get_wallet_summary'));
      expect(summary, isA<WalletSummaryModel>());
      expect(summary.cotton, BigInt.from(40));
    },
  );

  test(
    'getHistory sends the exact currency, cursor, and limit parameters',
    () async {
      late Uri requestedUri;
      late Map<String, dynamic> requestedBody;
      final client = SupabaseClient(
        'http://localhost:54321',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(fixture('currency_history_mixed_v1.json')),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

      final page = await WalletRepository(
        client,
      ).getHistory(currency: WalletCurrency.cottonCandy);

      expect(requestedUri.path, contains('/rpc/get_currency_history'));
      expect(requestedBody, {
        'p_currency': 'COTTON_CANDY',
        'p_cursor': null,
        'p_limit': 20,
      });
      expect(page.items, hasLength(2));
    },
  );

  test('getSummary returns an empty wallet while signed out', () async {
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'code': 'P0001',
            'message': 'WALLET_UNAUTHENTICATED',
            'details': 'Bad Request',
            'hint': null,
          }),
          400,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final summary = await WalletRepository(client).getSummary();

    expect(summary.star, BigInt.zero);
    expect(summary.bonus, BigInt.zero);
    expect(summary.cotton, BigInt.zero);
  });
}
