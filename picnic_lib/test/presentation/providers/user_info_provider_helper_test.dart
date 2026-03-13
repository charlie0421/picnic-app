import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider_helper.dart';

void main() {
  group('UserInfoProviderHelper.normalizeLanguageCode', () {
    test('zh_CN normalizes to zh', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('zh_CN'), 'zh');
    });

    test('zh normalizes to zh', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('zh'), 'zh');
    });

    test('zh_TW normalizes to zh-TW', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('zh_TW'), 'zh-TW');
    });

    test('bn_BD normalizes to bn', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('bn_BD'), 'bn');
    });

    test('bn normalizes to bn', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('bn'), 'bn');
    });

    test('ko_KR normalizes to ko', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('ko_KR'), 'ko');
    });

    test('en_US normalizes to en', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('en_US'), 'en');
    });

    test('ja_JP normalizes to ja', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('ja_JP'), 'ja');
    });

    test('simple code without underscore stays the same', () {
      expect(UserInfoProviderHelper.normalizeLanguageCode('ko'), 'ko');
      expect(UserInfoProviderHelper.normalizeLanguageCode('en'), 'en');
      expect(UserInfoProviderHelper.normalizeLanguageCode('ja'), 'ja');
    });
  });

  group('UserInfoProviderHelper.buildProfileUpdateMap', () {
    test('includes all provided fields', () {
      final now = DateTime(2026, 3, 13, 12, 0, 0);
      final birthDate = DateTime(1995, 5, 20);
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: 'male',
        birthDate: birthDate,
        birthTime: '14:30',
        updatedAt: now,
      );

      expect(map['gender'], 'male');
      expect(map['birth_date'], birthDate.toIso8601String());
      expect(map['birth_time'], '14:30');
      expect(map['updated_at'], isNotNull);
    });

    test('omits null gender', () {
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: null,
        birthDate: null,
        birthTime: null,
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(map.containsKey('gender'), isFalse);
      expect(map.containsKey('birth_date'), isFalse);
      expect(map.containsKey('birth_time'), isFalse);
      expect(map.containsKey('updated_at'), isTrue);
    });

    test('includes only gender when others are null', () {
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: 'female',
        birthDate: null,
        birthTime: null,
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(map.containsKey('gender'), isTrue);
      expect(map.containsKey('birth_date'), isFalse);
      expect(map.containsKey('birth_time'), isFalse);
    });

    test('includes only birthDate when others are null', () {
      final bd = DateTime(2000, 6, 15);
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: null,
        birthDate: bd,
        birthTime: null,
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(map.containsKey('gender'), isFalse);
      expect(map['birth_date'], bd.toIso8601String());
      expect(map.containsKey('birth_time'), isFalse);
    });

    test('includes only birthTime when others are null', () {
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        gender: null,
        birthDate: null,
        birthTime: '09:00',
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(map.containsKey('gender'), isFalse);
      expect(map.containsKey('birth_date'), isFalse);
      expect(map['birth_time'], '09:00');
    });

    test('updated_at is always present and in UTC', () {
      final map = UserInfoProviderHelper.buildProfileUpdateMap(
        updatedAt: DateTime(2026, 3, 13, 15, 30, 0),
      );

      expect(map['updated_at'], contains('T'));
      // Should be UTC formatted
      expect(map['updated_at'], endsWith('Z'));
    });
  });

  group('UserInfoProviderHelper.parseNicknameResponse', () {
    test('returns UserProfilesModel on status 200 with string data', () {
      final jsonData = jsonEncode({
        'data': {
          'id': 'test-user-id',
          'nickname': 'newNick',
          'avatar_url': null,
          'is_admin': false,
          'star_candy': 100,
          'star_candy_bonus': 0,
          'jma_candy': 0,
        },
      });

      final result = UserInfoProviderHelper.parseNicknameResponse(
        status: 200,
        data: jsonData,
      );

      expect(result, isNotNull);
      expect(result!.nickname, 'newNick');
      expect(result.id, 'test-user-id');
    });

    test('returns UserProfilesModel on status 200 with map data', () {
      final mapData = {
        'data': {
          'id': 'uid',
          'nickname': 'nick',
          'is_admin': false,
          'star_candy': 0,
          'star_candy_bonus': 0,
          'jma_candy': 0,
        },
      };

      final result = UserInfoProviderHelper.parseNicknameResponse(
        status: 200,
        data: mapData,
      );

      expect(result, isNotNull);
      expect(result!.nickname, 'nick');
    });

    test('returns null on non-200 status', () {
      final result = UserInfoProviderHelper.parseNicknameResponse(
        status: 400,
        data: jsonEncode({'error': 'Nickname taken'}),
      );

      expect(result, isNull);
    });

    test('returns null on status 500', () {
      final result = UserInfoProviderHelper.parseNicknameResponse(
        status: 500,
        data: jsonEncode({'error': 'Internal server error'}),
      );

      expect(result, isNull);
    });
  });

  group('UserInfoProviderHelper.parseExpireBonusResponse', () {
    test('parses List response', () {
      final parsed = [
        {'prediction_month': '2026-04', 'expiring_amount': 50},
        {'prediction_month': '2026-05', 'expiring_amount': 100},
      ];

      final result = UserInfoProviderHelper.parseExpireBonusResponse(parsed);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0]['prediction_month'], '2026-04');
      expect(result[1]['expiring_amount'], 100);
    });

    test('parses empty List', () {
      final result = UserInfoProviderHelper.parseExpireBonusResponse([]);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('parses data wrapper format', () {
      final parsed = {
        'data': [
          {'prediction_month': '2026-06', 'expiring_amount': 200},
        ],
      };

      final result = UserInfoProviderHelper.parseExpireBonusResponse(parsed);
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0]['expiring_amount'], 200);
    });

    test('parses data wrapper with empty list', () {
      final parsed = {'data': []};
      final result = UserInfoProviderHelper.parseExpireBonusResponse(parsed);
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('returns null for unexpected map format', () {
      final parsed = {'unexpected': 'value'};
      final result = UserInfoProviderHelper.parseExpireBonusResponse(parsed);
      expect(result, isNull);
    });

    test('returns null for string input', () {
      final result =
          UserInfoProviderHelper.parseExpireBonusResponse('not a list');
      expect(result, isNull);
    });

    test('returns null for int input', () {
      final result = UserInfoProviderHelper.parseExpireBonusResponse(42);
      expect(result, isNull);
    });

    test('returns null for null input', () {
      final result = UserInfoProviderHelper.parseExpireBonusResponse(null);
      expect(result, isNull);
    });
  });
}
