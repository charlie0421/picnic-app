import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_push_token.dart';

void main() {
  group('UserPushToken', () {
    test('필수 파라미터만으로 생성', () {
      const token = UserPushToken(
        id: 1,
        userId: 'user-123',
      );
      expect(token.id, equals(1));
      expect(token.userId, equals('user-123'));
      expect(token.tokenIos, isNull);
      expect(token.tokenAndroid, isNull);
      expect(token.tokenWeb, isNull);
      expect(token.tokenMacos, isNull);
      expect(token.tokenWindows, isNull);
    });

    test('전체 파라미터로 생성', () {
      const token = UserPushToken(
        id: 1,
        userId: 'user-123',
        tokenIos: 'ios-token',
        tokenAndroid: 'android-token',
        tokenWeb: 'web-token',
        tokenMacos: 'macos-token',
        tokenWindows: 'windows-token',
      );
      expect(token.tokenIos, equals('ios-token'));
      expect(token.tokenAndroid, equals('android-token'));
      expect(token.tokenWeb, equals('web-token'));
      expect(token.tokenMacos, equals('macos-token'));
      expect(token.tokenWindows, equals('windows-token'));
    });

    test('copyWith - 단일 필드 변경', () {
      const original = UserPushToken(
        id: 1,
        userId: 'user-123',
        tokenIos: 'old-ios',
      );
      final copied = original.copyWith(tokenIos: 'new-ios');
      expect(copied.tokenIos, equals('new-ios'));
      expect(copied.id, equals(1));
      expect(copied.userId, equals('user-123'));
    });

    test('copyWith - 여러 필드 변경', () {
      const original = UserPushToken(
        id: 1,
        userId: 'user-123',
      );
      final copied = original.copyWith(
        tokenIos: 'ios-token',
        tokenAndroid: 'android-token',
      );
      expect(copied.tokenIos, equals('ios-token'));
      expect(copied.tokenAndroid, equals('android-token'));
      expect(copied.tokenWeb, isNull); // 기존 null 유지
    });

    test('copyWith - id와 userId 변경', () {
      const original = UserPushToken(
        id: 1,
        userId: 'user-123',
        tokenIos: 'ios-token',
      );
      final copied = original.copyWith(id: 99, userId: 'user-456');
      expect(copied.id, equals(99));
      expect(copied.userId, equals('user-456'));
      expect(copied.tokenIos, equals('ios-token')); // 기존 값 유지
    });

    test('copyWith - 파라미터 없이 호출 시 동일한 값 유지', () {
      const original = UserPushToken(
        id: 1,
        userId: 'user-123',
        tokenIos: 'ios-token',
        tokenAndroid: 'android-token',
      );
      final copied = original.copyWith();
      expect(copied.id, equals(original.id));
      expect(copied.userId, equals(original.userId));
      expect(copied.tokenIos, equals(original.tokenIos));
      expect(copied.tokenAndroid, equals(original.tokenAndroid));
      expect(copied.tokenWeb, equals(original.tokenWeb));
      expect(copied.tokenMacos, equals(original.tokenMacos));
      expect(copied.tokenWindows, equals(original.tokenWindows));
    });

    test('const 생성자 지원', () {
      const token = UserPushToken(id: 1, userId: 'test');
      expect(token, isA<UserPushToken>());
    });

    group('fromJson', () {
      test('전체 필드 역직렬화', () {
        final json = {
          'id': 1,
          'user_id': 'user-123',
          'token_ios': 'ios-token',
          'token_android': 'android-token',
          'token_web': 'web-token',
          'token_macos': 'macos-token',
          'token_windows': 'windows-token',
        };
        final token = UserPushToken.fromJson(json);
        expect(token.id, equals(1));
        expect(token.userId, equals('user-123'));
        expect(token.tokenIos, equals('ios-token'));
        expect(token.tokenAndroid, equals('android-token'));
        expect(token.tokenWeb, equals('web-token'));
        expect(token.tokenMacos, equals('macos-token'));
        expect(token.tokenWindows, equals('windows-token'));
      });

      test('필수 필드만으로 역직렬화 (optional 필드 null)', () {
        final json = {
          'id': 42,
          'user_id': 'user-abc',
        };
        final token = UserPushToken.fromJson(json);
        expect(token.id, equals(42));
        expect(token.userId, equals('user-abc'));
        expect(token.tokenIos, isNull);
        expect(token.tokenAndroid, isNull);
        expect(token.tokenWeb, isNull);
        expect(token.tokenMacos, isNull);
        expect(token.tokenWindows, isNull);
      });

      test('일부 optional 필드만 있는 JSON 역직렬화', () {
        final json = {
          'id': 5,
          'user_id': 'user-partial',
          'token_ios': 'ios-only',
        };
        final token = UserPushToken.fromJson(json);
        expect(token.id, equals(5));
        expect(token.tokenIos, equals('ios-only'));
        expect(token.tokenAndroid, isNull);
      });
    });

    group('toJson', () {
      test('전체 필드 직렬화', () {
        const token = UserPushToken(
          id: 1,
          userId: 'user-123',
          tokenIos: 'ios-token',
          tokenAndroid: 'android-token',
          tokenWeb: 'web-token',
          tokenMacos: 'macos-token',
          tokenWindows: 'windows-token',
        );
        final json = token.toJson();
        expect(json['id'], equals(1));
        expect(json['user_id'], equals('user-123'));
        expect(json['token_ios'], equals('ios-token'));
        expect(json['token_android'], equals('android-token'));
        expect(json['token_web'], equals('web-token'));
        expect(json['token_macos'], equals('macos-token'));
        expect(json['token_windows'], equals('windows-token'));
      });

      test('optional 필드가 null일 때 직렬화', () {
        const token = UserPushToken(
          id: 1,
          userId: 'user-123',
        );
        final json = token.toJson();
        expect(json['id'], equals(1));
        expect(json['user_id'], equals('user-123'));
        expect(json['token_ios'], isNull);
        expect(json['token_android'], isNull);
        expect(json['token_web'], isNull);
        expect(json['token_macos'], isNull);
        expect(json['token_windows'], isNull);
      });

      test('JSON 키 이름이 snake_case인지 확인', () {
        const token = UserPushToken(
          id: 1,
          userId: 'user-123',
          tokenIos: 'ios',
        );
        final json = token.toJson();
        expect(json.containsKey('user_id'), isTrue);
        expect(json.containsKey('token_ios'), isTrue);
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('tokenIos'), isFalse);
      });
    });

    group('fromJson/toJson 왕복', () {
      test('직렬화 후 역직렬화 시 동일한 값', () {
        const original = UserPushToken(
          id: 10,
          userId: 'roundtrip-user',
          tokenIos: 'ios-rt',
          tokenAndroid: 'android-rt',
          tokenWeb: 'web-rt',
          tokenMacos: 'macos-rt',
          tokenWindows: 'windows-rt',
        );
        final json = original.toJson();
        final restored = UserPushToken.fromJson(json);
        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.tokenIos, equals(original.tokenIos));
        expect(restored.tokenAndroid, equals(original.tokenAndroid));
        expect(restored.tokenWeb, equals(original.tokenWeb));
        expect(restored.tokenMacos, equals(original.tokenMacos));
        expect(restored.tokenWindows, equals(original.tokenWindows));
      });

      test('null optional 필드 왕복', () {
        const original = UserPushToken(
          id: 1,
          userId: 'null-test',
        );
        final json = original.toJson();
        final restored = UserPushToken.fromJson(json);
        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.tokenIos, isNull);
        expect(restored.tokenAndroid, isNull);
      });
    });
  });
}
