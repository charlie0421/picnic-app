import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

void main() {
  test(
    'thread cursor query orders and filters by created_at then id',
    () async {
      late Uri requestUri;
      final client = SupabaseClient(
        'https://example.invalid',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            jsonEncode(<Object>[]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await QnaRepository(client: client).getQaThreadList(
        userId: 'user-a',
        lastId: 42,
        lastCreatedAt: DateTime.utc(2026, 9, 13, 1, 2, 3),
        limit: 20,
      );

      expect(requestUri.queryParameters['user_id'], 'eq.user-a');
      expect(requestUri.queryParameters['limit'], '20');
      expect(
        requestUri.queryParameters['order'],
        'created_at.desc.nullslast,id.desc.nullslast',
      );
      expect(requestUri.queryParameters['or'], contains('created_at.lt.'));
      expect(requestUri.queryParameters['or'], contains('id.lt.42'));
    },
  );
}
