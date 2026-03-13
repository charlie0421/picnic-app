import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/presentation/providers/celeb_list_provider_helper.dart';

void main() {
  group('CelebListProviderHelper.parseCelebList', () {
    test('parses multiple celebs from JSON list', () {
      final response = [
        {
          'id': 1,
          'name_ko': '아이유',
          'name_en': 'IU',
          'thumbnail': 'iu.jpg',
        },
        {
          'id': 2,
          'name_ko': '뉴진스',
          'name_en': 'NewJeans',
          'thumbnail': 'nj.jpg',
        },
      ];

      final result = CelebListProviderHelper.parseCelebList(response);

      expect(result, isA<List<CelebModel>>());
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[0].nameKo, '아이유');
      expect(result[0].nameEn, 'IU');
      expect(result[0].thumbnail, 'iu.jpg');
      expect(result[1].id, 2);
      expect(result[1].nameKo, '뉴진스');
      expect(result[1].nameEn, 'NewJeans');
    });

    test('returns empty list for empty response', () {
      final result =
          CelebListProviderHelper.parseCelebList(<Map<String, dynamic>>[]);

      expect(result, isEmpty);
      expect(result, isA<List<CelebModel>>());
    });

    test('handles null thumbnail', () {
      final response = [
        {
          'id': 3,
          'name_ko': '방탄소년단',
          'name_en': 'BTS',
          'thumbnail': null,
        },
      ];

      final result = CelebListProviderHelper.parseCelebList(response);

      expect(result.length, 1);
      expect(result[0].thumbnail, isNull);
    });

    test('handles single item list', () {
      final response = [
        {
          'id': 99,
          'name_ko': '테스트 셀럽',
          'name_en': 'Test Celeb',
          'thumbnail': 'test.png',
        },
      ];

      final result = CelebListProviderHelper.parseCelebList(response);

      expect(result.length, 1);
      expect(result[0].id, 99);
      expect(result[0].nameKo, '테스트 셀럽');
    });

    test('handles JSON with extra fields gracefully', () {
      final response = [
        {
          'id': 1,
          'name_ko': '아이유',
          'name_en': 'IU',
          'thumbnail': 'iu.jpg',
          'extra_field': 'should be ignored',
        },
      ];

      final result = CelebListProviderHelper.parseCelebList(response);

      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('handles JSON with users field', () {
      final response = [
        {
          'id': 1,
          'name_ko': '셀럽',
          'name_en': 'Celeb',
          'users': [
            {
              'id': 'user-1',
              'nickname': 'fan1',
              'is_admin': false,
              'star_candy': 100,
              'star_candy_bonus': 0,
              'jma_candy': 0,
            }
          ],
        },
      ];

      final result = CelebListProviderHelper.parseCelebList(response);

      expect(result.length, 1);
      expect(result[0].users, isNotNull);
      expect(result[0].users!.length, 1);
      expect(result[0].users![0].nickname, 'fan1');
    });
  });

  group('CelebListProviderHelper.parseMyCelebList', () {
    test('parses nested celeb data from bookmark response', () {
      final response = [
        {
          'celeb': {
            'id': 1,
            'name_ko': '아이유',
            'name_en': 'IU',
            'thumbnail': 'iu.jpg',
          },
        },
        {
          'celeb': {
            'id': 2,
            'name_ko': '뉴진스',
            'name_en': 'NewJeans',
            'thumbnail': 'nj.jpg',
          },
        },
      ];

      final result = CelebListProviderHelper.parseMyCelebList(response);

      expect(result, isA<List<CelebModel>>());
      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[0].nameKo, '아이유');
      expect(result[1].id, 2);
      expect(result[1].nameKo, '뉴진스');
    });

    test('returns empty list for empty bookmark response', () {
      final result =
          CelebListProviderHelper.parseMyCelebList(<Map<String, dynamic>>[]);

      expect(result, isEmpty);
    });

    test('handles single bookmark', () {
      final response = [
        {
          'celeb': {
            'id': 5,
            'name_ko': '테스트',
            'name_en': 'Test',
            'thumbnail': null,
          },
        },
      ];

      final result = CelebListProviderHelper.parseMyCelebList(response);

      expect(result.length, 1);
      expect(result[0].id, 5);
      expect(result[0].thumbnail, isNull);
    });

    test('handles bookmark response with extra fields in outer map', () {
      final response = [
        {
          'user_id': 'uid-123',
          'celeb_id': 1,
          'celeb': {
            'id': 1,
            'name_ko': '아이유',
            'name_en': 'IU',
            'thumbnail': 'iu.jpg',
          },
        },
      ];

      final result = CelebListProviderHelper.parseMyCelebList(response);

      expect(result.length, 1);
      expect(result[0].id, 1);
      expect(result[0].nameKo, '아이유');
    });
  });
}
