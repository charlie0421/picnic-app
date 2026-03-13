import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/library.dart';
import 'package:picnic_lib/presentation/providers/library_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncLibraryList provider with mock Supabase', () {
    setUp(() {
      setupMockSupabase({
        'library': [
          {
            'id': 1,
            'title': '포토 라이브러리',
            'images': null,
          },
          {
            'id': 2,
            'title': '팬아트 모음',
            'images': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of LibraryModel from mock data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncLibraryListProvider.future);

      expect(result, isA<List<LibraryModel>>());
      expect(result!.length, 2);
      expect(result[0].id, 1);
      expect(result[0].title, '포토 라이브러리');
      expect(result[1].id, 2);
      expect(result[1].title, '팬아트 모음');
    });
  });

  group('AsyncLibraryList provider with empty data', () {
    setUp(() {
      setupMockSupabase({
        'library': [],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty list when no libraries', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncLibraryListProvider.future);

      expect(result, isA<List<LibraryModel>>());
      expect(result, isEmpty);
    });
  });
}
