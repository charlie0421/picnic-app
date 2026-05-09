import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapToAntiAbuseException', () {
    test('PostgrestException P0001 RATE_LIMITED:signup → AntiAbuseException', () {
      const ex = PostgrestException(
        message: 'RATE_LIMITED:signup',
        code: 'P0001',
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbuseException>());
      expect((mapped as AntiAbuseException).channel, 'signup');
      expect(mapped.rawCode, 'P0001');
    });

    test('PostgrestException P0001 RATE_LIMITED:artist_request', () {
      const ex = PostgrestException(
        message: 'RATE_LIMITED:artist_request',
        code: 'P0001',
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbuseException>());
      expect((mapped as AntiAbuseException).channel, 'artist_request');
    });

    test('PostgrestException 42501 → AntiAbusePermissionException with key', () {
      const ex = PostgrestException(
        message: 'permission denied: anti_abuse.admin',
        code: '42501',
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbusePermissionException>());
      expect((mapped as AntiAbusePermissionException).requiredKey,
          'anti_abuse.admin');
    });

    test('PostgrestException 42501 with unknown message still classifies as permission', () {
      const ex = PostgrestException(
        message: 'permission denied for table foo',
        code: '42501',
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbusePermissionException>());
      expect((mapped as AntiAbusePermissionException).requiredKey, isNull);
    });

    test('FunctionException 429 RATE_LIMITED ad_watch', () {
      const ex = FunctionException(
        status: 429,
        details: {'code': 'RATE_LIMITED', 'reason': 'ad_watch_ip_quota'},
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbuseException>());
      expect((mapped as AntiAbuseException).channel, 'ad_watch');
    });

    test('FunctionException 429 with non-RATE_LIMITED body returns null', () {
      const ex = FunctionException(
        status: 429,
        details: {'error': 'too many requests'},
      );
      expect(mapToAntiAbuseException(ex), isNull);
    });

    test('FunctionException with non-429 status returns null', () {
      const ex = FunctionException(
        status: 500,
        details: {'code': 'RATE_LIMITED', 'reason': 'ad_watch_ip_quota'},
      );
      expect(mapToAntiAbuseException(ex), isNull);
    });

    test('PostgrestException with unrelated code returns null', () {
      const ex = PostgrestException(
        message: 'duplicate key',
        code: '23505',
      );
      expect(mapToAntiAbuseException(ex), isNull);
    });

    test('arbitrary Exception returns null', () {
      expect(mapToAntiAbuseException(Exception('whatever')), isNull);
      expect(mapToAntiAbuseException(null), isNull);
    });

    test("RATE_LIMITED: with empty channel still returns AntiAbuseException", () {
      const ex = PostgrestException(
        message: 'RATE_LIMITED:',
        code: 'P0001',
      );
      final mapped = mapToAntiAbuseException(ex);
      expect(mapped, isA<AntiAbuseException>());
      expect((mapped as AntiAbuseException).channel, '');
    });
  });
}
