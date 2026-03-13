import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/auth_service_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() {
  group('AuthServiceHelper', () {
    group('isSessionExpired', () {
      test('returns true for past timestamp', () {
        // 1 hour ago
        final pastSeconds =
            (DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch / 1000).floor();
        expect(AuthServiceHelper.isSessionExpired(pastSeconds), isTrue);
      });

      test('returns false for future timestamp', () {
        // 1 hour from now
        final futureSeconds =
            (DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch / 1000).floor();
        expect(AuthServiceHelper.isSessionExpired(futureSeconds), isFalse);
      });

      test('returns true for timestamp just passed', () {
        // 1 second ago
        final justPastSeconds =
            (DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch / 1000).floor();
        expect(AuthServiceHelper.isSessionExpired(justPastSeconds), isTrue);
      });

      test('returns false for far future timestamp', () {
        // 1 year from now
        final farFuture =
            (DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch / 1000).floor();
        expect(AuthServiceHelper.isSessionExpired(farFuture), isFalse);
      });

      test('returns true for epoch zero', () {
        expect(AuthServiceHelper.isSessionExpired(0), isTrue);
      });
    });

    group('shouldClearSession', () {
      test('returns true for AuthException with 401 status', () {
        const error = supa.AuthException('msg', statusCode: '401');
        expect(AuthServiceHelper.shouldClearSession(error), isTrue);
      });

      test('returns true for AuthException with Token expired message', () {
        const error =
            supa.AuthException('Token expired', statusCode: '200');
        expect(AuthServiceHelper.shouldClearSession(error), isTrue);
      });

      test('returns true for AuthException with Token expired in longer message', () {
        const error = supa.AuthException(
          'Session Token expired please re-authenticate',
          statusCode: '200',
        );
        expect(AuthServiceHelper.shouldClearSession(error), isTrue);
      });

      test('returns false for AuthException with 400 status', () {
        const error =
            supa.AuthException('Bad request', statusCode: '400');
        expect(AuthServiceHelper.shouldClearSession(error), isFalse);
      });

      test('returns false for AuthException with 500 status', () {
        const error =
            supa.AuthException('Server error', statusCode: '500');
        expect(AuthServiceHelper.shouldClearSession(error), isFalse);
      });

      test('returns false for regular Exception', () {
        final error = Exception('network error');
        expect(AuthServiceHelper.shouldClearSession(error), isFalse);
      });

      test('returns false for TimeoutException', () {
        final error = TimeoutException('timed out');
        expect(AuthServiceHelper.shouldClearSession(error), isFalse);
      });

      test('returns false for String error', () {
        expect(AuthServiceHelper.shouldClearSession('error'), isFalse);
      });

      test('returns false for null', () {
        expect(AuthServiceHelper.shouldClearSession(null), isFalse);
      });
    });

    group('parseProvider', () {
      test('returns google for "google"', () {
        expect(
          AuthServiceHelper.parseProvider('google'),
          supa.OAuthProvider.google,
        );
      });

      test('returns apple for "apple"', () {
        expect(
          AuthServiceHelper.parseProvider('apple'),
          supa.OAuthProvider.apple,
        );
      });

      test('returns kakao for "kakao"', () {
        expect(
          AuthServiceHelper.parseProvider('kakao'),
          supa.OAuthProvider.kakao,
        );
      });

      test('returns google for "GOOGLE" (case insensitive)', () {
        expect(
          AuthServiceHelper.parseProvider('GOOGLE'),
          supa.OAuthProvider.google,
        );
      });

      test('returns apple for "Apple" (case insensitive)', () {
        expect(
          AuthServiceHelper.parseProvider('Apple'),
          supa.OAuthProvider.apple,
        );
      });

      test('returns kakao for "KAKAO" (case insensitive)', () {
        expect(
          AuthServiceHelper.parseProvider('KAKAO'),
          supa.OAuthProvider.kakao,
        );
      });

      test('returns google for null (default)', () {
        expect(
          AuthServiceHelper.parseProvider(null),
          supa.OAuthProvider.google,
        );
      });

      test('returns google for unknown provider', () {
        expect(
          AuthServiceHelper.parseProvider('facebook'),
          supa.OAuthProvider.google,
        );
      });

      test('returns google for empty string', () {
        expect(
          AuthServiceHelper.parseProvider(''),
          supa.OAuthProvider.google,
        );
      });
    });

    group('extractProviderFromJwt', () {
      String makeJwt(Map<String, dynamic> payload) {
        final encoded =
            base64Url.encode(utf8.encode(jsonEncode(payload)));
        return 'eyJhbGciOiJIUzI1NiJ9.$encoded.signature';
      }

      test('extracts google provider', () {
        final jwt = makeJwt({'provider': 'google'});
        expect(AuthServiceHelper.extractProviderFromJwt(jwt), 'google');
      });

      test('extracts apple provider', () {
        final jwt = makeJwt({'provider': 'apple'});
        expect(AuthServiceHelper.extractProviderFromJwt(jwt), 'apple');
      });

      test('extracts kakao provider', () {
        final jwt = makeJwt({'provider': 'kakao'});
        expect(AuthServiceHelper.extractProviderFromJwt(jwt), 'kakao');
      });

      test('returns null when provider field missing', () {
        final jwt = makeJwt({'sub': 'user123', 'email': 'test@test.com'});
        expect(AuthServiceHelper.extractProviderFromJwt(jwt), isNull);
      });

      test('returns null for JWT with wrong number of parts', () {
        expect(AuthServiceHelper.extractProviderFromJwt('only.two'), isNull);
      });

      test('returns null for JWT with one part', () {
        expect(AuthServiceHelper.extractProviderFromJwt('onlyone'), isNull);
      });

      test('returns null for empty string', () {
        expect(AuthServiceHelper.extractProviderFromJwt(''), isNull);
      });

      test('returns null for invalid base64 payload', () {
        expect(
          AuthServiceHelper.extractProviderFromJwt('a.!!!invalid!!!.c'),
          isNull,
        );
      });
    });

    group('getProviderFromJwt', () {
      String makeJwt(Map<String, dynamic> payload) {
        final encoded =
            base64Url.encode(utf8.encode(jsonEncode(payload)));
        return 'eyJhbGciOiJIUzI1NiJ9.$encoded.signature';
      }

      test('returns google for google provider JWT', () {
        final jwt = makeJwt({'provider': 'google'});
        expect(
          AuthServiceHelper.getProviderFromJwt(jwt),
          supa.OAuthProvider.google,
        );
      });

      test('returns apple for apple provider JWT', () {
        final jwt = makeJwt({'provider': 'apple'});
        expect(
          AuthServiceHelper.getProviderFromJwt(jwt),
          supa.OAuthProvider.apple,
        );
      });

      test('returns kakao for kakao provider JWT', () {
        final jwt = makeJwt({'provider': 'kakao'});
        expect(
          AuthServiceHelper.getProviderFromJwt(jwt),
          supa.OAuthProvider.kakao,
        );
      });

      test('returns google for JWT without provider', () {
        final jwt = makeJwt({'sub': 'user'});
        expect(
          AuthServiceHelper.getProviderFromJwt(jwt),
          supa.OAuthProvider.google,
        );
      });

      test('returns google for invalid JWT', () {
        expect(
          AuthServiceHelper.getProviderFromJwt('invalid'),
          supa.OAuthProvider.google,
        );
      });
    });

    group('isRefreshTokenValid', () {
      test('returns true for non-empty string', () {
        expect(AuthServiceHelper.isRefreshTokenValid('some-token'), isTrue);
      });

      test('returns false for null', () {
        expect(AuthServiceHelper.isRefreshTokenValid(null), isFalse);
      });

      test('returns false for empty string', () {
        expect(AuthServiceHelper.isRefreshTokenValid(''), isFalse);
      });

      test('returns true for whitespace-only string', () {
        // Whitespace is technically non-empty
        expect(AuthServiceHelper.isRefreshTokenValid('  '), isTrue);
      });
    });

    group('isMissingSessionError', () {
      test('returns true for AuthException with 400 status', () {
        const error = supa.AuthException('msg', statusCode: '400');
        expect(AuthServiceHelper.isMissingSessionError(error), isTrue);
      });

      test('returns false for AuthException with 401 status', () {
        const error = supa.AuthException('msg', statusCode: '401');
        expect(AuthServiceHelper.isMissingSessionError(error), isFalse);
      });

      test('returns false for regular Exception', () {
        expect(
          AuthServiceHelper.isMissingSessionError(Exception('err')),
          isFalse,
        );
      });

      test('returns false for null', () {
        expect(AuthServiceHelper.isMissingSessionError(null), isFalse);
      });

      test('returns false for AuthException with 500', () {
        const error = supa.AuthException('msg', statusCode: '500');
        expect(AuthServiceHelper.isMissingSessionError(error), isFalse);
      });
    });
  });
}
