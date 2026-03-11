import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

void main() {
  group('MultilangJsonConverter', () {
    const converter = MultilangJsonConverter();

    test('Map<String, dynamic> 입력 시 그대로 반환', () {
      final input = {'ko': '안녕', 'en': 'hello'};
      expect(converter.fromJson(input), equals(input));
    });

    test('일반 문자열 입력 시 ko/en 맵 생성', () {
      final result = converter.fromJson('안녕하세요');
      expect(result, equals({'ko': '안녕하세요', 'en': '안녕하세요'}));
    });

    test('JSON 문자열 입력 시 파싱', () {
      final result = converter.fromJson('{"ko": "한국어", "en": "English"}');
      expect(result['ko'], equals('한국어'));
      expect(result['en'], equals('English'));
    });

    test('잘못된 JSON 문자열은 일반 문자열로 처리', () {
      final result = converter.fromJson('{invalid json}');
      expect(result, equals({'ko': '{invalid json}', 'en': '{invalid json}'}));
    });

    test('null 입력 시 빈 ko/en 맵 반환', () {
      final result = converter.fromJson(null);
      expect(result, equals({'ko': '', 'en': ''}));
    });

    test('toJson은 입력 그대로 반환', () {
      final input = {'ko': '테스트', 'en': 'test'};
      expect(converter.toJson(input), equals(input));
    });
  });

  group('UserNotification', () {
    test('기본값 생성', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
      );
      expect(notification.id, equals(1));
      expect(notification.type, equals('default'));
      expect(notification.isRead, isFalse);
      expect(notification.userId, isNull);
      expect(notification.data, isNull);
      expect(notification.actionUrl, isNull);
      expect(notification.createdAt, isNull);
      expect(notification.readAt, isNull);
    });

    test('전체 파라미터 생성', () {
      const notification = UserNotification(
        id: 1,
        userId: 'user-123',
        title: {'ko': '제목', 'en': 'Title'},
        body: {'ko': '내용', 'en': 'Body'},
        data: {'key': 'value'},
        actionUrl: 'picnic://vote/1',
        type: 'vote',
        isRead: true,
        createdAt: '2024-01-01T00:00:00Z',
        readAt: '2024-01-01T01:00:00Z',
      );
      expect(notification.userId, equals('user-123'));
      expect(notification.type, equals('vote'));
      expect(notification.isRead, isTrue);
      expect(notification.actionUrl, equals('picnic://vote/1'));
    });

    test('copyWith - 단일 필드 변경', () {
      const original = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
      );
      final copied = original.copyWith(isRead: true);
      expect(copied.isRead, isTrue);
      expect(copied.id, equals(1)); // 기존 값 유지
    });

    test('copyWith - 여러 필드 변경', () {
      const original = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
        type: 'default',
      );
      final copied = original.copyWith(
        type: 'vote',
        readAt: '2024-01-01T00:00:00Z',
        isRead: true,
      );
      expect(copied.type, equals('vote'));
      expect(copied.readAt, equals('2024-01-01T00:00:00Z'));
      expect(copied.isRead, isTrue);
      expect(copied.title, equals({'ko': '제목'})); // 유지
    });

    test('getLocalizedTitleWithLocale - ko', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '한국어 제목', 'en': 'English Title'},
        body: {'ko': '내용'},
      );
      expect(notification.getLocalizedTitleWithLocale('ko'),
          equals('한국어 제목'));
    });

    test('getLocalizedTitleWithLocale - en', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '한국어 제목', 'en': 'English Title'},
        body: {'ko': '내용'},
      );
      expect(notification.getLocalizedTitleWithLocale('en'),
          equals('English Title'));
    });

    test('getLocalizedBodyWithLocale', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '한국어 내용', 'en': 'English Body'},
      );
      expect(notification.getLocalizedBodyWithLocale('ko'),
          equals('한국어 내용'));
      expect(notification.getLocalizedBodyWithLocale('en'),
          equals('English Body'));
    });

    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 'user-abc',
        'title': {'ko': '알림 제목', 'en': 'Notification Title'},
        'body': {'ko': '알림 내용', 'en': 'Notification Body'},
        'data': {'key': 'value'},
        'action_url': 'https://example.com',
        'type': 'event',
        'is_read': false,
        'created_at': '2025-01-01T00:00:00.000Z',
        'read_at': null,
      };
      final notification = UserNotification.fromJson(json);
      expect(notification.id, equals(1));
      expect(notification.userId, equals('user-abc'));
      expect(notification.title['ko'], equals('알림 제목'));
      expect(notification.body['en'], equals('Notification Body'));
      expect(notification.type, equals('event'));
      expect(notification.isRead, isFalse);

      final output = notification.toJson();
      expect(output['id'], equals(1));
      expect(output['type'], equals('event'));
    });

    test('fromJson 문자열 title/body (MultilangJsonConverter)', () {
      final json = {
        'id': 3,
        'title': '간단한 제목',
        'body': '간단한 내용',
      };
      final notification = UserNotification.fromJson(json);
      expect(notification.title['ko'], equals('간단한 제목'));
      expect(notification.body['ko'], equals('간단한 내용'));
    });

    test('getLocalizedTitleWithLocale 없는 언어는 en으로 폴백', () {
      const notification = UserNotification(
        id: 2,
        title: {'en': 'Title'},
        body: {'en': 'Body'},
      );
      expect(notification.getLocalizedTitleWithLocale('fr'), equals('Title'));
    });

    test('배열 JSON 문자열은 일반 문자열로 처리', () {
      const converter = MultilangJsonConverter();
      final result = converter.fromJson('[1, 2, 3]');
      expect(result['ko'], equals('[1, 2, 3]'));
    });
  });
}
