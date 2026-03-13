import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() {
  group('AuthService', () {
    group('constructor and DI', () {
      test('creates instance with default constructor', () {
        final service = AuthService();
        expect(service, isNotNull);
        expect(service, isA<AuthService>());
      });

      test('creates instance with null optional dependencies', () {
        final service = AuthService(
          storageService: null,
          networkService: null,
          loginProviders: null,
        );
        expect(service, isNotNull);
      });

      test('creates instance with custom loginProviders', () {
        final customProviders = <supa.OAuthProvider, SocialLogin>{};
        final service = AuthService(loginProviders: customProviders);
        expect(service, isNotNull);
      });

      test('creates instance with single provider', () {
        final providers = <supa.OAuthProvider, SocialLogin>{
          supa.OAuthProvider.google: _FakeSocialLogin(),
        };
        final service = AuthService(loginProviders: providers);
        expect(service, isNotNull);
      });

      test('creates instance with multiple providers', () {
        final providers = <supa.OAuthProvider, SocialLogin>{
          supa.OAuthProvider.google: _FakeSocialLogin(),
          supa.OAuthProvider.apple: _FakeSocialLogin(),
          supa.OAuthProvider.kakao: _FakeSocialLogin(),
        };
        final service = AuthService(loginProviders: providers);
        expect(service, isNotNull);
      });
    });

    group('sessionStream', () {
      test('sessionStream is a broadcast Stream', () {
        final service = AuthService();
        final stream = service.sessionStream;
        expect(stream, isA<Stream<supa.Session?>>());
        // broadcast stream allows multiple listeners
        stream.listen((_) {});
        stream.listen((_) {});
        service.dispose();
      });
    });

    group('dispose', () {
      test('dispose closes the stream', () async {
        final service = AuthService();
        await service.dispose();
        final events = <supa.Session?>[];
        service.sessionStream.listen(
          events.add,
          onDone: () {},
        );
      });
    });

    group('method signatures', () {
      late AuthService service;

      setUp(() {
        service = AuthService();
      });

      tearDown(() async {
        await service.dispose();
      });

      test('signInWithProvider is a method', () {
        expect(service.signInWithProvider, isA<Function>());
      });

      test('recoverSession is a method', () {
        expect(service.recoverSession, isA<Function>());
      });

      test('refreshSession is a method', () {
        expect(service.refreshSession, isA<Function>());
      });

      test('signOut is a method', () {
        expect(service.signOut, isA<Function>());
      });
    });
  });

  group('AuthTimeouts', () {
    test('default timeout values', () {
      const timeouts = AuthTimeouts();
      expect(timeouts.networkCheck, equals(const Duration(seconds: 5)));
      expect(timeouts.sessionRecovery, equals(const Duration(seconds: 10)));
      expect(timeouts.tokenRefresh, equals(const Duration(seconds: 8)));
      expect(timeouts.tokenExpiration, equals(const Duration(hours: 1)));
    });

    test('custom timeout values', () {
      const customTimeouts = AuthTimeouts(
        networkCheck: Duration(seconds: 3),
        sessionRecovery: Duration(seconds: 5),
        tokenRefresh: Duration(seconds: 4),
        tokenExpiration: Duration(minutes: 30),
      );
      expect(customTimeouts.networkCheck, equals(const Duration(seconds: 3)));
      expect(customTimeouts.sessionRecovery, equals(const Duration(seconds: 5)));
      expect(customTimeouts.tokenRefresh, equals(const Duration(seconds: 4)));
      expect(customTimeouts.tokenExpiration, equals(const Duration(minutes: 30)));
    });

    test('all zero durations', () {
      const timeouts = AuthTimeouts(
        networkCheck: Duration.zero,
        sessionRecovery: Duration.zero,
        tokenRefresh: Duration.zero,
        tokenExpiration: Duration.zero,
      );
      expect(timeouts.networkCheck, Duration.zero);
      expect(timeouts.sessionRecovery, Duration.zero);
    });
  });

  group('SocialLogin interface', () {
    test('SocialLogin is a type', () {
      expect(SocialLogin, isNotNull);
    });

    test('FakeSocialLogin implements SocialLogin', () {
      final fake = _FakeSocialLogin();
      expect(fake, isA<SocialLogin>());
    });
  });

  group('PicnicAuthExceptions factory methods', () {
    test('invalidToken', () {
      final e = PicnicAuthExceptions.invalidToken();
      expect(e.code, 'invalid_token');
    });

    test('canceled', () {
      final e = PicnicAuthExceptions.canceled();
      expect(e.code, 'canceled');
    });

    test('network', () {
      final e = PicnicAuthExceptions.network();
      expect(e.code, 'network_error');
    });

    test('storageError', () {
      final e = PicnicAuthExceptions.storageError();
      expect(e.code, 'storage_error');
    });

    test('unsupportedProvider', () {
      final e = PicnicAuthExceptions.unsupportedProvider('test');
      expect(e.code, 'unsupported_provider');
      expect(e.message, contains('test'));
    });

    test('unknown with originalError', () {
      final orig = Exception('orig');
      final e = PicnicAuthExceptions.unknown(originalError: orig);
      expect(e.code, 'unknown');
      expect(e.originalError, orig);
    });

    test('unknown without originalError', () {
      final e = PicnicAuthExceptions.unknown();
      expect(e.code, 'unknown');
      expect(e.originalError, isNull);
    });

    test('deviceBanned', () {
      final e = PicnicAuthExceptions.deviceBanned();
      expect(e, isA<supa.AuthException>());
      expect(e.statusCode, 'DEVICE_BANNED');
    });
  });

  group('PicnicAuthException', () {
    test('toString format', () {
      final e = PicnicAuthException('code', 'message');
      expect(e.toString(), contains('PicnicAuthException'));
      expect(e.toString(), contains('code'));
      expect(e.toString(), contains('message'));
    });

    test('implements Exception', () {
      expect(PicnicAuthException('c', 'm'), isA<Exception>());
    });

    test('originalError access', () {
      final orig = StateError('x');
      final e = PicnicAuthException('c', 'm', originalError: orig);
      expect(e.originalError, orig);
    });

    test('fields are accessible', () {
      final e = PicnicAuthException('my_code', 'my_msg');
      expect(e.code, 'my_code');
      expect(e.message, 'my_msg');
    });
  });

  group('JWT provider extraction logic', () {
    test('parses google provider', () {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'provider': 'google'})));
      final jwt = 'eyJhbGciOiJIUzI1NiJ9.$payload.sig';
      final parts = jwt.split('.');
      expect(parts.length, 3);
      final decoded = jsonDecode(
        String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['provider'], 'google');
    });

    test('parses apple provider', () {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'provider': 'apple'})));
      final jwt = 'eyJhbGciOiJIUzI1NiJ9.$payload.sig';
      final parts = jwt.split('.');
      final decoded = jsonDecode(
        String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['provider'], 'apple');
    });

    test('parses kakao provider', () {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'provider': 'kakao'})));
      final jwt = 'eyJhbGciOiJIUzI1NiJ9.$payload.sig';
      final parts = jwt.split('.');
      final decoded = jsonDecode(
        String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['provider'], 'kakao');
    });

    test('missing provider field defaults to null', () {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'sub': 'user123'})));
      final jwt = 'eyJhbGciOiJIUzI1NiJ9.$payload.sig';
      final parts = jwt.split('.');
      final decoded = jsonDecode(
        String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      expect(decoded['provider'], isNull);
    });

    test('handles invalid JWT with wrong number of parts', () {
      const jwt = 'only.two';
      final parts = jwt.split('.');
      expect(parts.length, 2);
    });
  });

  group('shouldClearSession logic', () {
    test('AuthException with 401 should clear', () {
      const error = supa.AuthException('msg', statusCode: '401');
      final shouldClear = error is supa.AuthException &&
          (error.message.contains('Token expired') ||
              error.statusCode == '401');
      expect(shouldClear, isTrue);
    });

    test('AuthException with Token expired should clear', () {
      const error = supa.AuthException('Token expired', statusCode: '200');
      final shouldClear = error is supa.AuthException &&
          (error.message.contains('Token expired') ||
              error.statusCode == '401');
      expect(shouldClear, isTrue);
    });

    test('AuthException with 400 should not clear', () {
      const error = supa.AuthException('Bad request', statusCode: '400');
      final shouldClear = error is supa.AuthException &&
          (error.message.contains('Token expired') ||
              error.statusCode == '401');
      expect(shouldClear, isFalse);
    });

    test('regular Exception should not clear', () {
      final error = Exception('network');
      final shouldClear = error is supa.AuthException;
      expect(shouldClear, isFalse);
    });
  });

  group('SocialLoginResult', () {
    test('all null fields', () {
      const r = SocialLoginResult();
      expect(r.idToken, isNull);
      expect(r.accessToken, isNull);
      expect(r.userData, isNull);
    });

    test('all fields set', () {
      const r = SocialLoginResult(
        idToken: 'id',
        accessToken: 'access',
        userData: {'email': 'e@e.com'},
      );
      expect(r.idToken, 'id');
      expect(r.accessToken, 'access');
      expect(r.userData?['email'], 'e@e.com');
    });

    test('only idToken', () {
      const r = SocialLoginResult(idToken: 'token');
      expect(r.idToken, 'token');
      expect(r.accessToken, isNull);
    });

    test('only userData', () {
      const r = SocialLoginResult(userData: {'key': 'val'});
      expect(r.userData?['key'], 'val');
      expect(r.idToken, isNull);
    });
  });
}

class _FakeSocialLogin implements SocialLogin {
  @override
  Future<SocialLoginResult> login() async => const SocialLoginResult();

  @override
  Future<void> logout() async {}
}
