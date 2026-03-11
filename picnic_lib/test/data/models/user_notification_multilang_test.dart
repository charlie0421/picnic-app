import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

void main() {
  group('MultilangJsonConverter', () {
    const converter = MultilangJsonConverter();

    test('fromJson handles Map<String, dynamic>', () {
      final input = {'ko': '제목', 'en': 'Title'};
      expect(converter.fromJson(input), equals(input));
    });

    test('fromJson handles plain String', () {
      final result = converter.fromJson('hello');
      expect(result, {'ko': 'hello', 'en': 'hello'});
    });

    test('fromJson handles JSON string', () {
      final result = converter.fromJson('{"ko": "제목", "en": "Title"}');
      expect(result['ko'], '제목');
      expect(result['en'], 'Title');
    });

    test('fromJson handles invalid JSON string as plain string', () {
      final result = converter.fromJson('{invalid json}');
      expect(result, {'ko': '{invalid json}', 'en': '{invalid json}'});
    });

    test('fromJson handles null as empty strings', () {
      final result = converter.fromJson(null);
      expect(result, {'ko': '', 'en': ''});
    });

    test('fromJson handles non-string/non-map type as empty', () {
      final result = converter.fromJson(123);
      expect(result, {'ko': '', 'en': ''});
    });

    test('toJson returns map as-is', () {
      final input = {'ko': '제목', 'en': 'Title'};
      expect(converter.toJson(input), equals(input));
    });
  });

  group('UserNotification', () {
    test('creates from constructor', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목', 'en': 'Title'},
        body: {'ko': '내용', 'en': 'Body'},
        type: 'vote',
      );
      expect(notification.id, 1);
      expect(notification.type, 'vote');
      expect(notification.isRead, isFalse);
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'title': {'ko': '제목', 'en': 'Title'},
        'body': {'ko': '내용', 'en': 'Body'},
        'data': {'vote_id': 123},
        'action_url': 'https://example.com',
        'type': 'vote',
        'is_read': true,
        'created_at': '2025-01-01T00:00:00Z',
        'read_at': '2025-01-02T00:00:00Z',
      };
      final notification = UserNotification.fromJson(json);
      expect(notification.id, 1);
      expect(notification.userId, 'user-1');
      expect(notification.type, 'vote');
      expect(notification.isRead, isTrue);
      expect(notification.actionUrl, 'https://example.com');
    });

    test('creates from JSON with string title', () {
      final json = {
        'id': 1,
        'title': '문자열 제목',
        'body': '문자열 내용',
        'type': 'default',
        'is_read': false,
      };
      final notification = UserNotification.fromJson(json);
      expect(notification.title, {'ko': '문자열 제목', 'en': '문자열 제목'});
    });

    test('toJson roundtrip', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
        type: 'vote',
      );
      final json = notification.toJson();
      expect(json['id'], 1);
      expect(json['type'], 'vote');
    });

    test('copyWith updates fields', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
      );
      final updated = notification.copyWith(isRead: true, type: 'vote');
      expect(updated.isRead, isTrue);
      expect(updated.type, 'vote');
      expect(updated.id, 1);
    });

    test('copyWith preserves unchanged fields', () {
      const notification = UserNotification(
        id: 1,
        userId: 'user-1',
        title: {'ko': '제목'},
        body: {'ko': '내용'},
        type: 'vote',
        actionUrl: 'https://example.com',
      );
      final updated = notification.copyWith(isRead: true);
      expect(updated.userId, 'user-1');
      expect(updated.actionUrl, 'https://example.com');
      expect(updated.type, 'vote');
    });

    test('getLocalizedTitleWithLocale returns correct locale', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '한국어 제목', 'en': 'English Title'},
        body: {'ko': '내용'},
      );
      expect(notification.getLocalizedTitleWithLocale('ko'), '한국어 제목');
      expect(notification.getLocalizedTitleWithLocale('en'), 'English Title');
    });

    test('getLocalizedBodyWithLocale returns correct locale', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '한국어 내용', 'en': 'English Body'},
      );
      expect(notification.getLocalizedBodyWithLocale('ko'), '한국어 내용');
      expect(notification.getLocalizedBodyWithLocale('en'), 'English Body');
    });

    test('getLocalizedTitleWithLocale falls back to en', () {
      const notification = UserNotification(
        id: 1,
        title: {'en': 'English Title'},
        body: {'en': 'Body'},
      );
      expect(notification.getLocalizedTitleWithLocale('ja'), 'English Title');
    });

    test('default values', () {
      const notification = UserNotification(
        id: 1,
        title: {'ko': '제목'},
        body: {'ko': '내용'},
      );
      expect(notification.type, 'default');
      expect(notification.isRead, isFalse);
      expect(notification.userId, isNull);
      expect(notification.data, isNull);
      expect(notification.actionUrl, isNull);
      expect(notification.createdAt, isNull);
      expect(notification.readAt, isNull);
    });
  });
}
