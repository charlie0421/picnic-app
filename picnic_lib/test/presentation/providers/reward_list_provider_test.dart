import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncRewardList provider with mock Supabase', () {
    setUp(() {
      setupMockSupabase({
        'reward': [
          {
            'id': 1,
            'title': {'ko': '포토카드'},
            'thumbnail': 'img.jpg',
            'overview_images': null,
            'location': null,
            'size_guide': null,
            'size_guide_images': null,
          },
          {
            'id': 2,
            'title': {'ko': '앨범', 'en': 'Album'},
            'thumbnail': 'album.jpg',
            'overview_images': ['img1.jpg', 'img2.jpg'],
            'location': {'ko': '서울'},
            'size_guide': null,
            'size_guide_images': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of RewardModel from mock data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncRewardListProvider.future);

      expect(result, isA<List<RewardModel>>());
      expect(result.length, 2);
    });

    test('data matches expected model fields', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncRewardListProvider.future);

      final first = result[0];
      expect(first.id, 1);
      expect(first.title, {'ko': '포토카드'});
      expect(first.thumbnail, 'img.jpg');
      expect(first.overviewImages, isNull);
      expect(first.location, isNull);
      expect(first.sizeGuide, isNull);
      expect(first.sizeGuideImages, isNull);

      final second = result[1];
      expect(second.id, 2);
      expect(second.title, {'ko': '앨범', 'en': 'Album'});
      expect(second.thumbnail, 'album.jpg');
      expect(second.overviewImages, ['img1.jpg', 'img2.jpg']);
      expect(second.location, {'ko': '서울'});
    });
  });

  group('AsyncRewardList provider with empty data', () {
    setUp(() {
      setupMockSupabase({
        'reward': [],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty list when table has no data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncRewardListProvider.future);

      expect(result, isA<List<RewardModel>>());
      expect(result, isEmpty);
    });
  });
}
