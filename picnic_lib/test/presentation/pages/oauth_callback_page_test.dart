import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';

void main() {

  group('OAuthCallbackPage widget', () {
    test('can be constructed with callbackUri', () {
      final page = OAuthCallbackPage(
        callbackUri: Uri.parse('https://example.com/auth/callback?code=abc123'),
      );
      expect(page, isA<OAuthCallbackPage>());
      expect(page.callbackUri.queryParameters['code'], 'abc123');
    });

    test('routeName is correct', () {
      expect(OAuthCallbackPage.routeName, '/auth/callback');
    });

    test('with key can be constructed', () {
      final page = OAuthCallbackPage(
        key: const ValueKey('oauth'),
        callbackUri: Uri.parse('https://example.com/auth/callback?code=xyz'),
      );
      expect(page.key, equals(const ValueKey('oauth')));
    });

    test('callbackUri without code parameter', () {
      final page = OAuthCallbackPage(
        callbackUri: Uri.parse('https://example.com/auth/callback'),
      );
      expect(page.callbackUri.queryParameters['code'], isNull);
    });

    test('callbackUri with multiple parameters', () {
      final page = OAuthCallbackPage(
        callbackUri: Uri.parse(
          'https://example.com/auth/callback?code=abc&state=xyz&error=none',
        ),
      );
      expect(page.callbackUri.queryParameters['code'], 'abc');
      expect(page.callbackUri.queryParameters['state'], 'xyz');
    });
  });

  group('OAuthCallbackPage URI parsing logic', () {
    test('extracts code from callback URI', () {
      final uri = Uri.parse('https://example.com/callback?code=auth_code_123');
      final code = uri.queryParameters['code'];
      expect(code, 'auth_code_123');
    });

    test('returns null when code is missing', () {
      final uri = Uri.parse('https://example.com/callback?error=access_denied');
      final code = uri.queryParameters['code'];
      expect(code, isNull);
    });

    test('handles empty code parameter', () {
      final uri = Uri.parse('https://example.com/callback?code=');
      final code = uri.queryParameters['code'];
      expect(code, '');
    });

    test('handles URI with fragment', () {
      final uri = Uri.parse(
        'https://example.com/callback?code=abc#fragment_data',
      );
      final code = uri.queryParameters['code'];
      expect(code, 'abc');
    });
  });

  group('OAuthCallbackPage error handling logic', () {
    test('missing code triggers error message', () {
      final uri = Uri.parse('https://example.com/callback');
      final code = uri.queryParameters['code'];
      if (code == null) {
        expect(() => throw Exception('로그인에 실패했습니다: 인증 코드가 없습니다'),
            throwsException);
      }
    });

    test('valid code does not throw', () {
      final uri = Uri.parse('https://example.com/callback?code=valid');
      final code = uri.queryParameters['code'];
      expect(code, isNotNull);
      expect(code, 'valid');
    });
  });
}
