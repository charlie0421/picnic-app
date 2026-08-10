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

    test('query excludes soft-deleted rows and keeps open-ended windows', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(asyncBannerListProvider(location: 'vote_home').future);

      final uri = capturedMockRequests
          .singleWhere((u) => u.path.contains('/rest/v1/banner'));
      final params = uri.queryParametersAll;

      // 소프트 딜리트 배너 제외 (레포 컨벤션: deleted_at=is.null)
      expect(params['deleted_at'], ['is.null']);

      // "지금 유효" 술어: start_at/end_at 각각 NULL 을 무제한으로 해석해야
      // 한다. 단일 or 술어는 (start_at IS NULL AND end_at IS NOT NULL) 행을
      // 누락하므로, 컬럼별 null-허용 조건 2개가 AND 로 걸려야 한다.
      // mock 은 filter 를 해석하지 않으므로 와이어 파라미터를 괄호 포함
      // 전체 형태로 고정한다.
      const isoPattern = r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z';
      final ors = params['or'] ?? [];
      expect(ors, hasLength(2));
      expect(
        ors,
        contains(
          matches(RegExp('^\\(start_at\\.is\\.null,start_at\\.lte\\.$isoPattern\\)\$')),
        ),
      );
      expect(
        ors,
        contains(
          matches(RegExp('^\\(end_at\\.is\\.null,end_at\\.gte\\.$isoPattern\\)\$')),
        ),
      );
    });

    test('active-window filters treat each NULL bound as unlimited', () {
      final now = DateTime.utc(2026, 8, 7, 12);
      // 정확한 술어 문자열을 고정한다. 이 두 or 조건이 AND 로 결합되면
      // PostgREST 는 아래 진리표대로 행을 선택한다:
      //   (NULL, NULL) / (과거, NULL) / (NULL, 미래) / (과거, 미래) -> 통과
      //   start_at 이 미래이거나 end_at 이 과거 -> 탈락
      expect(bannerActiveWindowOrFilters(now), [
        'start_at.is.null,start_at.lte.2026-08-07T12:00:00.000Z',
        'end_at.is.null,end_at.gte.2026-08-07T12:00:00.000Z',
      ]);
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
