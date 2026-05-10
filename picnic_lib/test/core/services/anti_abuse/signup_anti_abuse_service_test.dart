import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/services/anti_abuse/signup_anti_abuse_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client(http.Client httpClient) => SupabaseClient(
      'http://localhost:54321',
      'test-anon-key',
      httpClient: httpClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runPrecheck', () {
    test('returns SignupHint on 200 with sig payload', () async {
      final mock = MockClient((req) async {
        if (req.url.path.contains('/functions/v1/anti-abuse-signup-precheck')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'ip_hash': 'abc123',
                'sig': 'sig_xyz',
                'exp': 1234567890,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });
      final svc = SignupAntiAbuseService(_client(mock));

      final hint = await svc.runPrecheck();
      expect(hint, isNotNull);
      expect(hint!.ipHash, 'abc123');
      expect(hint.sig, 'sig_xyz');
      expect(hint.exp, 1234567890);
    });

    test('returns null on 200 with skipped flag', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'ip_hash': 'unknown',
              'sig': null,
              'exp': null,
              'skipped': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final svc = SignupAntiAbuseService(_client(mock));

      expect(await svc.runPrecheck(), isNull);
    });

    test('throws AntiAbuseException(signup) on 429 RATE_LIMITED', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'RATE_LIMITED',
              'details': {'reason': 'signup_ip_quota'},
            },
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });
      final svc = SignupAntiAbuseService(_client(mock));

      expect(
        () => svc.runPrecheck(),
        throwsA(
          isA<AntiAbuseException>().having(
            (e) => e.channel,
            'channel',
            'signup',
          ),
        ),
      );
    });

    test('returns null on network failure (silent fallback)', () async {
      final mock = MockClient((req) async {
        throw Exception('network down');
      });
      final svc = SignupAntiAbuseService(_client(mock));

      expect(await svc.runPrecheck(), isNull);
    });

    test('returns null on malformed response (no data field)', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final svc = SignupAntiAbuseService(_client(mock));

      expect(await svc.runPrecheck(), isNull);
    });

    test('returns null when sig type is wrong (best-effort skip)', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'ip_hash': 'h', 'sig': 123, 'exp': 'oops'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final svc = SignupAntiAbuseService(_client(mock));

      expect(await svc.runPrecheck(), isNull);
    });
  });

  group('runVerify', () {
    const hint = SignupHint(ipHash: 'abc', sig: 's', exp: 1);

    test('200 success — completes without throwing', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'success': true, 'data': {'verified': true}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      await SignupAntiAbuseService(_client(mock)).runVerify(hint);
    });

    test('422 sig invalid — swallowed silently (server marks unverified)',
        () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'SIG_INVALID', 'message': 'bad'},
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });
      // Should not throw.
      await SignupAntiAbuseService(_client(mock)).runVerify(hint);
    });

    test('401 unauthorized — swallowed silently', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'success': false, 'error': {'code': 'UNAUTHORIZED'}}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      await SignupAntiAbuseService(_client(mock)).runVerify(hint);
    });

    test('network failure — swallowed silently', () async {
      final mock = MockClient((req) async {
        throw Exception('boom');
      });
      await SignupAntiAbuseService(_client(mock)).runVerify(hint);
    });

    test('sends ip_hash, sig, exp in body', () async {
      Map<String, dynamic>? capturedBody;
      final mock = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      await SignupAntiAbuseService(_client(mock)).runVerify(hint);
      expect(capturedBody, {
        'ip_hash': 'abc',
        'sig': 's',
        'exp': 1,
      });
    });
  });
}
