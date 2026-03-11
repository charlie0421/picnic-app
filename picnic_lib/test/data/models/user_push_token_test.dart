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

    test('const 생성자 지원', () {
      const token = UserPushToken(id: 1, userId: 'test');
      expect(token, isA<UserPushToken>());
    });
  });
}
