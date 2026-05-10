import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/services/anti_abuse/ip_hash_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client(http.Client httpClient) => SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetchAndCache returns ip_hash from track-country and caches', () async {
    var invokeCount = 0;
    final mock = MockClient((req) async {
      if (req.url.path.contains('/functions/v1/track-country')) {
        invokeCount++;
        return http.Response(
          jsonEncode({'ip_hash': 'abc123', 'country': 'KR'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });
    final service = IpHashService(_client(mock));

    expect(await service.fetchAndCache(), 'abc123');
    expect(service.current, 'abc123');
    expect(invokeCount, 1);

    // Second call hits the in-memory cache — no extra invocation.
    expect(await service.fetchAndCache(), 'abc123');
    expect(invokeCount, 1);
  });

  test('fetchAndCache returns null on server error (silent fallback)', () async {
    final mock = MockClient((req) async {
      return http.Response(jsonEncode({'error': 'boom'}), 500);
    });
    final service = IpHashService(_client(mock));

    expect(await service.fetchAndCache(), null);
    expect(service.current, null);
  });

  test('fetchAndCache returns null on network exception (silent fallback)',
      () async {
    final mock = MockClient((req) async {
      throw Exception('network down');
    });
    final service = IpHashService(_client(mock));

    expect(await service.fetchAndCache(), null);
    expect(service.current, null);
  });

  test("ip_hash 'unknown' is treated as missing — not cached", () async {
    final mock = MockClient((req) async {
      return http.Response(
        jsonEncode({'ip_hash': 'unknown'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = IpHashService(_client(mock));

    expect(await service.fetchAndCache(), null);
    expect(service.current, null);
  });

  test('force=true bypasses cache and re-invokes', () async {
    var invokeCount = 0;
    final mock = MockClient((req) async {
      invokeCount++;
      return http.Response(
        jsonEncode({'ip_hash': 'h$invokeCount'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = IpHashService(_client(mock));

    expect(await service.fetchAndCache(), 'h1');
    expect(await service.fetchAndCache(force: true), 'h2');
    expect(invokeCount, 2);
  });

  test('clearCache resets internal state', () async {
    var invokeCount = 0;
    final mock = MockClient((req) async {
      invokeCount++;
      return http.Response(
        jsonEncode({'ip_hash': 'h$invokeCount'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = IpHashService(_client(mock));

    await service.fetchAndCache();
    expect(service.current, 'h1');
    service.clearCache();
    expect(service.current, null);
    await service.fetchAndCache();
    expect(invokeCount, 2);
  });
}
