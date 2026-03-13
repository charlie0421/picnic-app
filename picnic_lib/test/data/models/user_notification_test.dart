import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

void main() {
  group('MultilangJsonConverter', () {
    const converter = MultilangJsonConverter();

    group('fromJson', () {
      test('Map<String, dynamic> 입력 시 그대로 반환', () {
        final input = {'ko': '안녕', 'en': 'hello'};
        expect(converter.fromJson(input), equals(input));
      });

      test('빈 Map 입력 시 그대로 반환', () {
        final input = <String, dynamic>{};
        expect(converter.fromJson(input), equals(input));
      });

      test('여러 언어가 포함된 Map 그대로 반환', () {
        final input = {
          'ko': '한국어',
          'en': 'English',
          'ja': '日本語',
          'zh': '中文',
        };
        final result = converter.fromJson(input);
        expect(result, equals(input));
        expect(result.length, equals(4));
      });

      test('일반 문자열 입력 시 ko/en 맵 생성', () {
        final result = converter.fromJson('안녕하세요');
        expect(result, equals({'ko': '안녕하세요', 'en': '안녕하세요'}));
      });

      test('빈 문자열 입력 시 ko/en 맵 생성', () {
        final result = converter.fromJson('');
        expect(result, equals({'ko': '', 'en': ''}));
      });

      test('공백만 있는 문자열 입력 시 ko/en 맵 생성', () {
        final result = converter.fromJson('   ');
        expect(result, equals({'ko': '   ', 'en': '   '}));
      });

      test('JSON 문자열 입력 시 파싱하여 Map 반환', () {
        final result = converter.fromJson('{"ko": "한국어", "en": "English"}');
        expect(result['ko'], equals('한국어'));
        expect(result['en'], equals('English'));
        expect(result, isA<Map<String, dynamic>>());
      });

      test('중첩 JSON 문자열 입력 시 파싱', () {
        final jsonStr = jsonEncode({
          'ko': '한국어',
          'en': 'English',
          'meta': {'version': 1},
        });
        final result = converter.fromJson(jsonStr);
        expect(result['ko'], equals('한국어'));
        expect(result['en'], equals('English'));
        expect(result['meta'], isA<Map>());
      });

      test('JSON 문자열 앞뒤 공백 처리', () {
        final result =
            converter.fromJson('  {"ko": "한국어", "en": "English"}  ');
        expect(result['ko'], equals('한국어'));
        expect(result['en'], equals('English'));
      });

      test('잘못된 JSON 문자열은 일반 문자열로 처리 (중괄호로 시작)', () {
        final input = '{invalid json}';
        final result = converter.fromJson(input);
        expect(result, equals({'ko': input, 'en': input}));
      });

      test('잘못된 JSON 문자열은 일반 문자열로 처리 (대괄호로 시작하지만 파싱 실패)', () {
        final input = '[invalid array';
        final result = converter.fromJson(input);
        expect(result, equals({'ko': input, 'en': input}));
      });

      test('배열 JSON 문자열은 일반 문자열로 처리 (List는 Map이 아님)', () {
        final input = '[1, 2, 3]';
        final result = converter.fromJson(input);
        expect(result, equals({'ko': input, 'en': input}));
      });

      test('배열 of objects JSON 문자열도 일반 문자열로 처리', () {
        final input = '[{"key": "value"}]';
        final result = converter.fromJson(input);
        expect(result, equals({'ko': input, 'en': input}));
      });

      test('null 입력 시 빈 ko/en 맵 반환', () {
        final result = converter.fromJson(null);
        expect(result, equals({'ko': '', 'en': ''}));
      });

      test('정수 입력 시 빈 ko/en 맵 반환', () {
        final result = converter.fromJson(42);
        expect(result, equals({'ko': '', 'en': ''}));
      });

      test('boolean 입력 시 빈 ko/en 맵 반환', () {
        final result = converter.fromJson(true);
        expect(result, equals({'ko': '', 'en': ''}));
      });

      test('double 입력 시 빈 ko/en 맵 반환', () {
        final result = converter.fromJson(3.14);
        expect(result, equals({'ko': '', 'en': ''}));
      });

      test('List 입력 시 빈 ko/en 맵 반환', () {
        final result = converter.fromJson([1, 2, 3]);
        expect(result, equals({'ko': '', 'en': ''}));
      });
    });

    group('toJson', () {
      test('입력 그대로 반환', () {
        final input = {'ko': '테스트', 'en': 'test'};
        expect(converter.toJson(input), equals(input));
      });

      test('빈 맵 그대로 반환', () {
        final input = <String, dynamic>{};
        expect(converter.toJson(input), equals(input));
      });

      test('복잡한 값이 포함된 맵도 그대로 반환', () {
        final input = <String, dynamic>{
          'ko': '한국어',
          'en': 'English',
          'nested': {'key': 'value'},
          'list': [1, 2, 3],
        };
        final result = converter.toJson(input);
        expect(result, equals(input));
        expect(identical(result, input), isTrue);
      });
    });
  });

  group('UserNotification', () {
    group('Constructor', () {
      test('필수 필드만으로 생성 (기본값 확인)', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '제목'},
          body: {'ko': '내용'},
        );
        expect(notification.id, equals(1));
        expect(notification.title, equals({'ko': '제목'}));
        expect(notification.body, equals({'ko': '내용'}));
        expect(notification.type, equals('default'));
        expect(notification.isRead, isFalse);
        expect(notification.userId, isNull);
        expect(notification.data, isNull);
        expect(notification.actionUrl, isNull);
        expect(notification.createdAt, isNull);
        expect(notification.readAt, isNull);
      });

      test('전체 파라미터로 생성', () {
        const notification = UserNotification(
          id: 42,
          userId: 'user-123',
          title: {'ko': '제목', 'en': 'Title'},
          body: {'ko': '내용', 'en': 'Body'},
          data: {'key': 'value', 'nested': true},
          actionUrl: 'picnic://vote/1',
          type: 'vote',
          isRead: true,
          createdAt: '2024-01-01T00:00:00Z',
          readAt: '2024-01-01T01:00:00Z',
        );
        expect(notification.id, equals(42));
        expect(notification.userId, equals('user-123'));
        expect(notification.title['ko'], equals('제목'));
        expect(notification.title['en'], equals('Title'));
        expect(notification.body['ko'], equals('내용'));
        expect(notification.body['en'], equals('Body'));
        expect(notification.data, equals({'key': 'value', 'nested': true}));
        expect(notification.actionUrl, equals('picnic://vote/1'));
        expect(notification.type, equals('vote'));
        expect(notification.isRead, isTrue);
        expect(notification.createdAt, equals('2024-01-01T00:00:00Z'));
        expect(notification.readAt, equals('2024-01-01T01:00:00Z'));
      });
    });

    group('fromJson / toJson', () {
      test('전체 필드 roundtrip', () {
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
        expect(notification.title['en'], equals('Notification Title'));
        expect(notification.body['ko'], equals('알림 내용'));
        expect(notification.body['en'], equals('Notification Body'));
        expect(notification.data, equals({'key': 'value'}));
        expect(notification.actionUrl, equals('https://example.com'));
        expect(notification.type, equals('event'));
        expect(notification.isRead, isFalse);
        expect(notification.createdAt, equals('2025-01-01T00:00:00.000Z'));
        expect(notification.readAt, isNull);

        final output = notification.toJson();
        expect(output['id'], equals(1));
        expect(output['user_id'], equals('user-abc'));
        expect(output['type'], equals('event'));
        expect(output['is_read'], isFalse);
        expect(output['action_url'], equals('https://example.com'));
        expect(output['created_at'], equals('2025-01-01T00:00:00.000Z'));
        expect(output['read_at'], isNull);
      });

      test('최소 필드 fromJson (기본값 적용)', () {
        final json = {
          'id': 5,
          'title': {'ko': '제목'},
          'body': {'ko': '내용'},
        };
        final notification = UserNotification.fromJson(json);
        expect(notification.id, equals(5));
        expect(notification.type, equals('default'));
        expect(notification.isRead, isFalse);
        expect(notification.userId, isNull);
        expect(notification.data, isNull);
        expect(notification.actionUrl, isNull);
        expect(notification.createdAt, isNull);
        expect(notification.readAt, isNull);
      });

      test('문자열 title/body fromJson (MultilangJsonConverter 동작)', () {
        final json = {
          'id': 3,
          'title': '간단한 제목',
          'body': '간단한 내용',
        };
        final notification = UserNotification.fromJson(json);
        expect(notification.title, equals({'ko': '간단한 제목', 'en': '간단한 제목'}));
        expect(notification.body, equals({'ko': '간단한 내용', 'en': '간단한 내용'}));
      });

      test('JSON 문자열 title/body fromJson', () {
        final json = {
          'id': 4,
          'title': '{"ko": "한국어 제목", "en": "English Title"}',
          'body': '{"ko": "한국어 내용", "en": "English Body"}',
        };
        final notification = UserNotification.fromJson(json);
        expect(notification.title['ko'], equals('한국어 제목'));
        expect(notification.title['en'], equals('English Title'));
        expect(notification.body['ko'], equals('한국어 내용'));
        expect(notification.body['en'], equals('English Body'));
      });

      test('toJson은 snake_case 키 사용', () {
        const notification = UserNotification(
          id: 1,
          userId: 'user-1',
          title: {'ko': '제목'},
          body: {'ko': '내용'},
          actionUrl: 'https://example.com',
          isRead: true,
          createdAt: '2024-01-01',
          readAt: '2024-01-02',
        );
        final output = notification.toJson();
        expect(output.containsKey('user_id'), isTrue);
        expect(output.containsKey('action_url'), isTrue);
        expect(output.containsKey('is_read'), isTrue);
        expect(output.containsKey('created_at'), isTrue);
        expect(output.containsKey('read_at'), isTrue);
        // camelCase 키가 없어야 함
        expect(output.containsKey('userId'), isFalse);
        expect(output.containsKey('actionUrl'), isFalse);
        expect(output.containsKey('isRead'), isFalse);
        expect(output.containsKey('createdAt'), isFalse);
        expect(output.containsKey('readAt'), isFalse);
      });

      test('fromJson 후 toJson roundtrip 데이터 보존', () {
        final originalJson = {
          'id': 10,
          'user_id': 'user-xyz',
          'title': {'ko': '원본 제목', 'en': 'Original Title'},
          'body': {'ko': '원본 내용', 'en': 'Original Body'},
          'data': {'deep': {'nested': 'value'}},
          'action_url': 'picnic://deep-link',
          'type': 'promo',
          'is_read': true,
          'created_at': '2025-06-15T12:00:00Z',
          'read_at': '2025-06-15T13:00:00Z',
        };
        final notification = UserNotification.fromJson(originalJson);
        final outputJson = notification.toJson();

        expect(outputJson['id'], equals(originalJson['id']));
        expect(outputJson['user_id'], equals(originalJson['user_id']));
        expect(outputJson['title'], equals(originalJson['title']));
        expect(outputJson['body'], equals(originalJson['body']));
        expect(outputJson['data'], equals(originalJson['data']));
        expect(outputJson['action_url'], equals(originalJson['action_url']));
        expect(outputJson['type'], equals(originalJson['type']));
        expect(outputJson['is_read'], equals(originalJson['is_read']));
        expect(outputJson['created_at'], equals(originalJson['created_at']));
        expect(outputJson['read_at'], equals(originalJson['read_at']));
      });
    });

    group('copyWith', () {
      const original = UserNotification(
        id: 1,
        userId: 'user-1',
        title: {'ko': '원본 제목', 'en': 'Original Title'},
        body: {'ko': '원본 내용', 'en': 'Original Body'},
        data: {'key': 'value'},
        actionUrl: 'picnic://original',
        type: 'default',
        isRead: false,
        createdAt: '2024-01-01T00:00:00Z',
        readAt: null,
      );

      test('파라미터 없이 호출 시 동일한 값 유지', () {
        final copied = original.copyWith();
        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
        expect(copied.title, equals(original.title));
        expect(copied.body, equals(original.body));
        expect(copied.data, equals(original.data));
        expect(copied.actionUrl, equals(original.actionUrl));
        expect(copied.type, equals(original.type));
        expect(copied.isRead, equals(original.isRead));
        expect(copied.createdAt, equals(original.createdAt));
        expect(copied.readAt, equals(original.readAt));
      });

      test('단일 필드 변경', () {
        final copied = original.copyWith(isRead: true);
        expect(copied.isRead, isTrue);
        expect(copied.id, equals(original.id));
        expect(copied.title, equals(original.title));
        expect(copied.type, equals(original.type));
      });

      test('여러 필드 동시 변경', () {
        final copied = original.copyWith(
          type: 'vote',
          readAt: '2024-01-01T12:00:00Z',
          isRead: true,
          actionUrl: 'picnic://vote/99',
        );
        expect(copied.type, equals('vote'));
        expect(copied.readAt, equals('2024-01-01T12:00:00Z'));
        expect(copied.isRead, isTrue);
        expect(copied.actionUrl, equals('picnic://vote/99'));
        // 나머지 필드는 유지
        expect(copied.id, equals(original.id));
        expect(copied.userId, equals(original.userId));
        expect(copied.title, equals(original.title));
        expect(copied.body, equals(original.body));
        expect(copied.createdAt, equals(original.createdAt));
      });

      test('모든 필드 변경', () {
        final copied = original.copyWith(
          id: 99,
          userId: 'user-new',
          title: {'ko': '새 제목', 'en': 'New Title'},
          body: {'ko': '새 내용', 'en': 'New Body'},
          data: {'new_key': 'new_value'},
          actionUrl: 'picnic://new',
          type: 'promo',
          isRead: true,
          createdAt: '2025-01-01T00:00:00Z',
          readAt: '2025-01-01T01:00:00Z',
        );
        expect(copied.id, equals(99));
        expect(copied.userId, equals('user-new'));
        expect(copied.title, equals({'ko': '새 제목', 'en': 'New Title'}));
        expect(copied.body, equals({'ko': '새 내용', 'en': 'New Body'}));
        expect(copied.data, equals({'new_key': 'new_value'}));
        expect(copied.actionUrl, equals('picnic://new'));
        expect(copied.type, equals('promo'));
        expect(copied.isRead, isTrue);
        expect(copied.createdAt, equals('2025-01-01T00:00:00Z'));
        expect(copied.readAt, equals('2025-01-01T01:00:00Z'));
      });

      test('원본은 변경되지 않음', () {
        original.copyWith(id: 999, isRead: true, type: 'changed');
        expect(original.id, equals(1));
        expect(original.isRead, isFalse);
        expect(original.type, equals('default'));
      });
    });

    group('getLocalizedTitleWithLocale', () {
      test('ko 로케일 요청 시 ko 값 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '한국어 제목', 'en': 'English Title'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('ko'),
          equals('한국어 제목'),
        );
      });

      test('en 로케일 요청 시 en 값 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '한국어 제목', 'en': 'English Title'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('en'),
          equals('English Title'),
        );
      });

      test('ja 로케일 요청 시 ja 값 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '한국어', 'en': 'English', 'ja': '日本語'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('ja'),
          equals('日本語'),
        );
      });

      test('없는 언어 코드는 en으로 폴백', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '한국어 제목', 'en': 'Fallback Title'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('fr'),
          equals('Fallback Title'),
        );
      });

      test('en도 없으면 빈 문자열 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '한국어만'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('fr'),
          equals(''),
        );
      });

      test('빈 title 맵이면 빈 문자열 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('ko'),
          equals(''),
        );
      });

      test('zh_CN 언어 코드 → zh로 정규화', () {
        const notification = UserNotification(
          id: 1,
          title: {'zh': '中文标题', 'en': 'English'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('zh_CN'),
          equals('中文标题'),
        );
      });

      test('zh_TW 언어 코드 → zh-TW로 정규화', () {
        const notification = UserNotification(
          id: 1,
          title: {'zh-TW': '繁體中文', 'en': 'English'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('zh_TW'),
          equals('繁體中文'),
        );
      });

      test('bn_BD 언어 코드 → bn으로 정규화', () {
        const notification = UserNotification(
          id: 1,
          title: {'bn': 'বাংলা', 'en': 'English'},
          body: {'ko': '내용'},
        );
        expect(
          notification.getLocalizedTitleWithLocale('bn_BD'),
          equals('বাংলা'),
        );
      });
    });

    group('getLocalizedBodyWithLocale', () {
      test('ko 로케일 요청 시 ko 값 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '제목'},
          body: {'ko': '한국어 내용', 'en': 'English Body'},
        );
        expect(
          notification.getLocalizedBodyWithLocale('ko'),
          equals('한국어 내용'),
        );
      });

      test('en 로케일 요청 시 en 값 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '제목'},
          body: {'ko': '한국어 내용', 'en': 'English Body'},
        );
        expect(
          notification.getLocalizedBodyWithLocale('en'),
          equals('English Body'),
        );
      });

      test('없는 언어 코드는 en으로 폴백', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '제목'},
          body: {'ko': '한국어', 'en': 'Fallback Body'},
        );
        expect(
          notification.getLocalizedBodyWithLocale('de'),
          equals('Fallback Body'),
        );
      });

      test('빈 body 맵이면 빈 문자열 반환', () {
        const notification = UserNotification(
          id: 1,
          title: {'ko': '제목'},
          body: {},
        );
        expect(
          notification.getLocalizedBodyWithLocale('ko'),
          equals(''),
        );
      });
    });
  });
}
