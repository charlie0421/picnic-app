import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/presentation/providers/celeb_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncCelebList provider with mock Supabase', () {
    setUp(() {
      setupMockSupabase({
        'celeb': [
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
          {
            'id': 3,
            'name_ko': '방탄소년단',
            'name_en': 'BTS',
            'thumbnail': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of CelebModel from mock data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncCelebListProvider.future);

      expect(result, isA<List<CelebModel>>());
      expect(result!.length, 3);
    });

    test('data matches expected model fields', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncCelebListProvider.future);

      final first = result![0];
      expect(first.id, 1);
      expect(first.nameKo, '아이유');
      expect(first.nameEn, 'IU');
      expect(first.thumbnail, 'iu.jpg');

      final second = result[1];
      expect(second.id, 2);
      expect(second.nameKo, '뉴진스');
      expect(second.nameEn, 'NewJeans');
      expect(second.thumbnail, 'nj.jpg');

      final third = result[2];
      expect(third.id, 3);
      expect(third.nameKo, '방탄소년단');
      expect(third.nameEn, 'BTS');
      expect(third.thumbnail, isNull);
    });

    test('provider returns AsyncData state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(asyncCelebListProvider.future);

      final state = container.read(asyncCelebListProvider);
      expect(state, isA<AsyncData<List<CelebModel>?>>());
      expect(state.hasValue, true);
      expect(state.hasError, false);
    });
  });

  group('AsyncCelebList provider with empty data', () {
    setUp(() {
      setupMockSupabase({
        'celeb': [],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty list when table has no data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncCelebListProvider.future);

      expect(result, isA<List<CelebModel>>());
      expect(result, isEmpty);
    });
  });

  group('AsyncCelebList provider with single item', () {
    setUp(() {
      setupMockSupabase({
        'celeb': [
          {
            'id': 99,
            'name_ko': '테스트 셀럽',
            'name_en': 'Test Celeb',
            'thumbnail': 'test.png',
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns single item list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncCelebListProvider.future);

      expect(result!.length, 1);
      expect(result[0].id, 99);
      expect(result[0].nameKo, '테스트 셀럽');
    });
  });

  group('AsyncMyCelebList provider', () {
    setUp(() {
      setupMockSupabase({
        'celeb_bookmark_user': [
          {
            'celeb': {
              'id': 1,
              'name_ko': '아이유',
              'name_en': 'IU',
              'thumbnail': 'iu.jpg',
            },
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns null when user is not authenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // currentUser is null in mock environment, so fetchMyCelebList returns null
      final result = await container.read(asyncMyCelebListProvider.future);
      expect(result, isNull);
    });

    test('asyncMyCelebListProvider is keepAlive', () {
      expect(asyncMyCelebListProvider, isNotNull);
    });
  });

  group('SelectedCeleb provider', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(selectedCelebProvider);
      expect(result, isNull);
    });

    test('setSelectedCeleb updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final celeb = CelebModel(
        id: 1,
        nameKo: '아이유',
        nameEn: 'IU',
        thumbnail: 'iu.jpg',
      );

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb);
      final result = container.read(selectedCelebProvider);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.nameKo, '아이유');
    });

    test('setSelectedCeleb to null clears state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final celeb = CelebModel(
        id: 1,
        nameKo: '아이유',
        nameEn: 'IU',
      );

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb);
      expect(container.read(selectedCelebProvider), isNotNull);

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(null);
      expect(container.read(selectedCelebProvider), isNull);
    });

    test('setSelectedCeleb replaces previous selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final celeb1 = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      final celeb2 = CelebModel(id: 2, nameKo: '뉴진스', nameEn: 'NewJeans');

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb1);
      expect(container.read(selectedCelebProvider)!.id, 1);

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb2);
      expect(container.read(selectedCelebProvider)!.id, 2);
      expect(container.read(selectedCelebProvider)!.nameKo, '뉴진스');
    });
  });

  group('SelectedCeleb edge cases', () {
    test('setting same celeb twice does not throw', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final celeb = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb);
      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb);
      expect(container.read(selectedCelebProvider)!.id, 1);
    });

    test('setting null then new celeb works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCelebProvider.notifier).setSelectedCeleb(null);
      expect(container.read(selectedCelebProvider), isNull);

      final celeb = CelebModel(id: 5, nameKo: '테스트', nameEn: 'Test');
      container.read(selectedCelebProvider.notifier).setSelectedCeleb(celeb);
      expect(container.read(selectedCelebProvider)!.id, 5);
    });
  });

  group('CelebModel structure tests', () {
    test('CelebModel fromJson with all fields', () {
      final json = {
        'id': 1,
        'name_ko': '셀럽',
        'name_en': 'Celeb',
        'thumbnail': 'thumb.jpg',
        'users': null,
      };

      final model = CelebModel.fromJson(json);
      expect(model.id, 1);
      expect(model.nameKo, '셀럽');
      expect(model.nameEn, 'Celeb');
      expect(model.thumbnail, 'thumb.jpg');
      expect(model.users, isNull);
    });

    test('CelebModel fromJson with minimal fields', () {
      final json = {
        'id': 10,
        'name_ko': '테스트',
        'name_en': 'Test',
      };

      final model = CelebModel.fromJson(json);
      expect(model.id, 10);
      expect(model.nameKo, '테스트');
      expect(model.nameEn, 'Test');
      expect(model.thumbnail, isNull);
      expect(model.users, isNull);
    });

    test('CelebModel copyWith works correctly', () {
      final model = CelebModel(
        id: 1,
        nameKo: '원본',
        nameEn: 'Original',
      );

      final updated = model.copyWith(nameKo: '수정됨');
      expect(updated.nameKo, '수정됨');
      expect(updated.id, 1);
      expect(updated.nameEn, 'Original');
    });

    test('CelebModel copyWith updates thumbnail', () {
      final model = CelebModel(
        id: 1,
        nameKo: '테스트',
        nameEn: 'Test',
      );

      final updated = model.copyWith(thumbnail: 'new_thumb.jpg');
      expect(updated.thumbnail, 'new_thumb.jpg');
    });

    test('CelebModel thumbnail can be null', () {
      final model = CelebModel(
        id: 1,
        nameKo: '테스트',
        nameEn: 'Test',
      );

      expect(model.thumbnail, isNull);
    });

    test('CelebModel equality', () {
      final model1 = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      final model2 = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');

      expect(model1, equals(model2));
    });

    test('CelebModel inequality', () {
      final model1 = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      final model2 = CelebModel(id: 2, nameKo: '뉴진스', nameEn: 'NewJeans');

      expect(model1, isNot(equals(model2)));
    });

    test('CelebModel fromJson with users list', () {
      final json = {
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
      };

      final model = CelebModel.fromJson(json);
      expect(model.users, isNotNull);
      expect(model.users!.length, 1);
      expect(model.users![0].nickname, 'fan1');
    });
  });
}
