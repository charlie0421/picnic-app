import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';

void main() {
  group('SocialLoginResult', () {
    test('모든 필드 null로 생성', () {
      const result = SocialLoginResult();
      expect(result.idToken, isNull);
      expect(result.accessToken, isNull);
      expect(result.userData, isNull);
    });

    test('idToken만 포함', () {
      const result = SocialLoginResult(
        idToken: 'test-id-token',
      );
      expect(result.idToken, equals('test-id-token'));
      expect(result.accessToken, isNull);
    });

    test('모든 필드 포함', () {
      const result = SocialLoginResult(
        idToken: 'id-token-123',
        accessToken: 'access-token-456',
        userData: {'email': 'test@example.com', 'name': 'Test User'},
      );
      expect(result.idToken, equals('id-token-123'));
      expect(result.accessToken, equals('access-token-456'));
      expect(result.userData!['email'], equals('test@example.com'));
    });

    test('Apple 로그인 시뮬레이션', () {
      const result = SocialLoginResult(
        idToken: 'apple-id-token',
        userData: {'sub': 'apple-user-id'},
      );
      expect(result.idToken, isNotNull);
      expect(result.accessToken, isNull);
      expect(result.userData!['sub'], equals('apple-user-id'));
    });

    test('Kakao 로그인 시뮬레이션', () {
      const result = SocialLoginResult(
        accessToken: 'kakao-access-token',
        userData: {
          'id': 12345,
          'kakao_account': {'email': 'user@kakao.com'},
        },
      );
      expect(result.accessToken, equals('kakao-access-token'));
      expect(result.userData!['id'], equals(12345));
    });
  });
}
