import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/auth_token_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('AuthTokenInfo 모델 테스트', () {
    late AuthTokenInfo testTokenInfo;
    late DateTime testExpiresAt;
    late Map<String, dynamic> testJson;

    setUp(() {
      testExpiresAt = DateTime.parse('2030-12-31T23:59:59.000Z');

      testTokenInfo = AuthTokenInfo(
        accessToken: 'test-access-token-123',
        refreshToken: 'test-refresh-token-456',
        expiresAt: testExpiresAt,
        provider: supabase.OAuthProvider.google,
      );

      testJson = {
        'accessToken': 'test-access-token-123',
        'refreshToken': 'test-refresh-token-456',
        'expiresAt': '2030-12-31T23:59:59.000Z',
        'provider': 'google',
      };
    });

    group('생성자 테스트', () {
      test('모든 필드가 올바르게 할당되어야 한다', () {
        expect(testTokenInfo.accessToken, equals('test-access-token-123'));
        expect(testTokenInfo.refreshToken, equals('test-refresh-token-456'));
        expect(testTokenInfo.expiresAt, equals(testExpiresAt));
        expect(testTokenInfo.provider, equals(supabase.OAuthProvider.google));
      });

      test('refreshToken이 null일 수 있어야 한다', () {
        final tokenInfo = AuthTokenInfo(
          accessToken: 'test-token',
          refreshToken: null,
          expiresAt: testExpiresAt,
          provider: supabase.OAuthProvider.apple,
        );

        expect(tokenInfo.refreshToken, isNull);
        expect(tokenInfo.accessToken, equals('test-token'));
      });
    });

    group('isExpired 테스트', () {
      test('만료 시간이 미래인 경우 false를 반환해야 한다', () {
        final futureToken = AuthTokenInfo(
          accessToken: 'token',
          refreshToken: null,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          provider: supabase.OAuthProvider.google,
        );

        expect(futureToken.isExpired, isFalse);
      });

      test('만료 시간이 과거인 경우 true를 반환해야 한다', () {
        final expiredToken = AuthTokenInfo(
          accessToken: 'token',
          refreshToken: null,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          provider: supabase.OAuthProvider.google,
        );

        expect(expiredToken.isExpired, isTrue);
      });
    });

    group('toJson 테스트', () {
      test('올바른 Map을 생성해야 한다', () {
        final json = testTokenInfo.toJson();

        expect(json['accessToken'], equals('test-access-token-123'));
        expect(json['refreshToken'], equals('test-refresh-token-456'));
        expect(json['expiresAt'], equals('2030-12-31T23:59:59.000Z'));
        expect(json['provider'], equals('google'));
      });

      test('refreshToken이 null인 경우 null 값을 포함해야 한다', () {
        final tokenInfo = AuthTokenInfo(
          accessToken: 'token',
          refreshToken: null,
          expiresAt: testExpiresAt,
          provider: supabase.OAuthProvider.kakao,
        );

        final json = tokenInfo.toJson();
        expect(json['refreshToken'], isNull);
        expect(json['provider'], equals('kakao'));
      });
    });

    group('fromJson 테스트', () {
      test('JSON에서 올바른 객체를 생성해야 한다', () {
        final tokenInfo = AuthTokenInfo.fromJson(testJson);

        expect(tokenInfo.accessToken, equals('test-access-token-123'));
        expect(tokenInfo.refreshToken, equals('test-refresh-token-456'));
        expect(
          tokenInfo.expiresAt,
          equals(DateTime.parse('2030-12-31T23:59:59.000Z')),
        );
        expect(tokenInfo.provider, equals(supabase.OAuthProvider.google));
      });

      test('다양한 provider 값을 올바르게 파싱해야 한다', () {
        final appleJson = Map<String, dynamic>.from(testJson);
        appleJson['provider'] = 'apple';

        final tokenInfo = AuthTokenInfo.fromJson(appleJson);
        expect(tokenInfo.provider, equals(supabase.OAuthProvider.apple));
      });
    });

    group('toJson/fromJson 라운드트립 테스트', () {
      test('toJson 후 fromJson으로 동일한 데이터를 복원해야 한다', () {
        final json = testTokenInfo.toJson();
        final restored = AuthTokenInfo.fromJson(json);

        expect(restored.accessToken, equals(testTokenInfo.accessToken));
        expect(restored.refreshToken, equals(testTokenInfo.refreshToken));
        expect(restored.expiresAt, equals(testTokenInfo.expiresAt));
        expect(restored.provider, equals(testTokenInfo.provider));
      });

      test('kakao provider로 라운드트립이 정상 동작해야 한다', () {
        final kakaoToken = AuthTokenInfo(
          accessToken: 'kakao-token',
          refreshToken: 'kakao-refresh',
          expiresAt: DateTime.parse('2030-06-15T12:00:00.000Z'),
          provider: supabase.OAuthProvider.kakao,
        );

        final json = kakaoToken.toJson();
        final restored = AuthTokenInfo.fromJson(json);

        expect(restored.accessToken, equals('kakao-token'));
        expect(restored.refreshToken, equals('kakao-refresh'));
        expect(restored.provider, equals(supabase.OAuthProvider.kakao));
      });
    });
  });
}
