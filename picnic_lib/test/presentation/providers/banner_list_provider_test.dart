import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncBannerList provider with mock Supabase', () {
    setUp(() {
      setupMockSupabase({
        'banner': [
          {
            'id': 1,
            'title': {'ko': '이벤트 배너'},
            'thumbnail': 'banner1.jpg',
            'image': {'ko': 'banner1_ko.jpg', 'en': 'banner1_en.jpg'},
            'duration': 5000,
            'link': 'https://example.com',
          },
          {
            'id': 2,
            'title': {'ko': '프로모션'},
            'thumbnail': 'banner2.jpg',
            'image': {'ko': 'banner2_ko.jpg'},
            'duration': 3000,
            'link': null,
          },
        ],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns list of BannerModel from mock data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(asyncBannerListProvider(location: 'home').future);

      expect(result, isA<List<BannerModel>>());
      expect(result.length, 2);
    });

    test('banner fields are correctly parsed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(asyncBannerListProvider(location: 'home').future);

      final first = result[0];
      expect(first.id, 1);
      expect(first.title, {'ko': '이벤트 배너'});
      expect(first.thumbnail, 'banner1.jpg');
      expect(first.image, {'ko': 'banner1_ko.jpg', 'en': 'banner1_en.jpg'});
      expect(first.duration, 5000);
      expect(first.link, 'https://example.com');

      final second = result[1];
      expect(second.id, 2);
      expect(second.link, isNull);
      expect(second.duration, 3000);
    });
  });

  group('AsyncBannerList provider with empty data', () {
    setUp(() {
      setupMockSupabase({
        'banner': [],
      });
    });

    tearDown(() => tearDownMockSupabase());

    test('returns empty list when no banners', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(asyncBannerListProvider(location: 'home').future);

      expect(result, isA<List<BannerModel>>());
      expect(result, isEmpty);
    });
  });
}
