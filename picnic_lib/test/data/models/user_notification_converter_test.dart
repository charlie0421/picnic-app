import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

void main() {
  const converter = MultilangJsonConverter();

  group('MultilangJsonConverter.fromJson', () {
    test('passes through Map<String, dynamic> as-is', () {
      final input = <String, dynamic>{'ko': '제목', 'en': 'title'};
      final result = converter.fromJson(input);
      expect(result, equals(input));
    });

    test('wraps plain string in ko/en map', () {
      const input = 'hello';
      final result = converter.fromJson(input);
      expect(result, equals({'ko': 'hello', 'en': 'hello'}));
    });

    test('parses JSON string into map', () {
      const input = '{"ko":"제목","en":"title"}';
      final result = converter.fromJson(input);
      expect(result, equals({'ko': '제목', 'en': 'title'}));
    });

    test('falls back to ko/en wrap for malformed JSON starting with {', () {
      const input = '{this is not valid json';
      final result = converter.fromJson(input);
      expect(result, equals({'ko': input, 'en': input}));
    });

    test('returns empty ko/en for null input', () {
      final result = converter.fromJson(null);
      expect(result, equals({'ko': '', 'en': ''}));
    });

    test('returns empty ko/en for int input', () {
      final result = converter.fromJson(42);
      expect(result, equals({'ko': '', 'en': ''}));
    });
  });

  group('MultilangJsonConverter.toJson', () {
    test('returns the map as-is', () {
      final input = <String, dynamic>{'ko': '제목', 'en': 'title'};
      final result = converter.toJson(input);
      expect(result, equals(input));
    });
  });

  group('UserNotification.copyWith', () {
    final notification = UserNotification(
      id: 1,
      userId: 'user-1',
      title: {'ko': '제목', 'en': 'title'},
      body: {'ko': '본문', 'en': 'body'},
      type: 'default',
      isRead: false,
      actionUrl: 'https://example.com',
      createdAt: '2024-01-01T00:00:00Z',
    );

    test('returns identical notification when no arguments provided', () {
      final copy = notification.copyWith();
      expect(copy.id, equals(notification.id));
      expect(copy.userId, equals(notification.userId));
      expect(copy.title, equals(notification.title));
      expect(copy.body, equals(notification.body));
      expect(copy.type, equals(notification.type));
      expect(copy.isRead, equals(notification.isRead));
      expect(copy.actionUrl, equals(notification.actionUrl));
      expect(copy.createdAt, equals(notification.createdAt));
    });

    test('overrides specified fields', () {
      final copy = notification.copyWith(
        id: 99,
        isRead: true,
        title: {'ko': '새 제목', 'en': 'new title'},
      );
      expect(copy.id, equals(99));
      expect(copy.isRead, isTrue);
      expect(copy.title, equals({'ko': '새 제목', 'en': 'new title'}));
      // unchanged fields
      expect(copy.userId, equals('user-1'));
      expect(copy.body, equals({'ko': '본문', 'en': 'body'}));
    });
  });

  group('UserNotification.getLocalizedTitleWithLocale', () {
    final notification = UserNotification(
      id: 1,
      title: {'ko': '한국어 제목', 'en': 'English title'},
      body: {'ko': '본문', 'en': 'body'},
    );

    test('returns Korean title for ko locale', () {
      expect(
        notification.getLocalizedTitleWithLocale('ko'),
        equals('한국어 제목'),
      );
    });

    test('returns English title for en locale', () {
      expect(
        notification.getLocalizedTitleWithLocale('en'),
        equals('English title'),
      );
    });

    test('falls back to en for unsupported locale', () {
      expect(
        notification.getLocalizedTitleWithLocale('fr'),
        equals('English title'),
      );
    });
  });

  group('UserNotification.getLocalizedBodyWithLocale', () {
    final notification = UserNotification(
      id: 1,
      title: {'ko': '제목', 'en': 'title'},
      body: {'ko': '한국어 본문', 'en': 'English body'},
    );

    test('returns Korean body for ko locale', () {
      expect(
        notification.getLocalizedBodyWithLocale('ko'),
        equals('한국어 본문'),
      );
    });

    test('returns English body for en locale', () {
      expect(
        notification.getLocalizedBodyWithLocale('en'),
        equals('English body'),
      );
    });

    test('falls back to en for unsupported locale', () {
      expect(
        notification.getLocalizedBodyWithLocale('ja'),
        equals('English body'),
      );
    });
  });
}
