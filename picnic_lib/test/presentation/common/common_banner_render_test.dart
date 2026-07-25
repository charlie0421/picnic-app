import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// Mock for AsyncBannerList that returns a provided list
class MockAsyncBannerListEmpty extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [];
}

class MockAsyncBannerListSingle extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
    BannerModel.fromJson({
      'id': 1,
      'title': {'ko': '단일 배너'},
      'thumbnail': 'https://example.com/thumb.jpg',
      'image': {'ko': 'https://example.com/img.jpg'},
      'duration': 3000,
      'link': null,
    }),
  ];
}

class MockAsyncBannerListMultiple extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
    BannerModel.fromJson({
      'id': 1,
      'title': {'ko': '배너 1'},
      'thumbnail': 'https://example.com/thumb1.jpg',
      'image': {'ko': 'https://example.com/img1.jpg'},
      'duration': 3000,
      'link': 'https://www.picnic.fan/vote',
    }),
    BannerModel.fromJson({
      'id': 2,
      'title': {'ko': '배너 2'},
      'thumbnail': 'https://example.com/thumb2.jpg',
      'image': {'ko': 'https://example.com/img2.jpg'},
      'duration': 5000,
      'link': 'https://applink.picnic.fan/something',
    }),
    BannerModel.fromJson({
      'id': 3,
      'title': {'ko': ''},
      'thumbnail': 'https://example.com/thumb3.jpg',
      'image': {'ko': 'https://example.com/img3.gif'},
      'duration': 4000,
      'link': null,
    }),
  ];
}

class MockAsyncBannerListError extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    throw Exception('Banner load error');
  }
}

class MockAsyncBannerListWithLinks extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
    BannerModel.fromJson({
      'id': 1,
      'title': {'ko': '외부 링크'},
      'thumbnail': 'https://example.com/thumb.jpg',
      'image': {'ko': 'https://example.com/img.jpg'},
      'duration': 3000,
      'link': 'https://www.google.com',
    }),
  ];
}

class MockOwnedBannerList extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
    for (var i = 0; i < 2; i++)
      BannerModel.fromJson({
        'id': 101,
        'title': {'en': 'owned ordinary'},
        'thumbnail': 'https://example.com/thumb.jpg',
        'image': {'en': 'https://example.com/owned.jpg'},
        'duration': 3000,
        'link': null,
      }),
  ];
}

class MockMixedBannerList extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
    ...await MockOwnedBannerList().build(location: location),
    BannerModel.fromJson({
      'id': 202,
      'title': {'en': 'ordinary unowned'},
      'thumbnail': 'https://example.com/thumb.jpg',
      'image': {'en': 'https://example.com/ordinary.jpg'},
      'duration': 3000,
      'link': null,
    }),
  ];
}

class MutableBannerList extends AsyncBannerList {
  static List<BannerModel> items = [];

  @override
  Future<List<BannerModel>> build({required String location}) async => items;
}

ActivePromotionCampaignsModel homeCampaign() =>
    ActivePromotionCampaignsModel.fromJson({
      'items': [
        {
          'campaign_id': 'campaign',
          'campaign_version_id': 'version',
          'code': 'CANDY_BOOST_DAY',
          'display_name': {'en': 'Candy Boost Day'},
          'extra_bonus_bps': 10000,
          'window_starts_at': '2026-07-21T00:00:00Z',
          'window_ends_at': '2026-07-22T00:00:00Z',
          'show_in_store': true,
          'show_home_banner': true,
          'home_creative': {
            'banner_id': 101,
            'title': {'en': 'Campaign creative'},
            'image': {'en': 'https://example.com/campaign.jpg'},
            'thumbnail': null,
            'link': null,
            'duration': 4500,
          },
        },
      ],
      'total_count': '1',
      'next_cursor': null,
      'snapshot_at': '2026-07-21T00:00:00Z',
      'campaign_owned_home_banner_ids': [101],
    });

class _Scheduled implements CommonBannerScheduledTask {
  _Scheduled(this.callback);
  final VoidCallback callback;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
}

class _Scheduler implements CommonBannerScheduler {
  final List<Duration> delays = [];
  final List<_Scheduled> tasks = [];
  @override
  CommonBannerScheduledTask schedule(Duration delay, VoidCallback callback) {
    delays.add(delay);
    final task = _Scheduled(callback);
    tasks.add(task);
    return task;
  }
}

void main() {
  late void Function() restore;

  test('unified slide timing and shrink index rules are deterministic', () {
    expect(commonBannerSlideDuration(4500), const Duration(milliseconds: 4500));
    expect(commonBannerSlideDuration(0), const Duration(milliseconds: 3000));
    expect(commonBannerSafeIndex(2, 1), 0);
    expect(commonBannerSafeIndex(1, 3), 1);
  });

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({'banner': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('CommonBanner render', () {
    testWidgets('renders with empty banner list', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with single banner item (no swiper)', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with multiple banners (swiper)', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(
              MockAsyncBannerListMultiple.new,
            ),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders error state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListError.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with link banners', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 3144 / 1200),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(
              MockAsyncBannerListWithLinks.new,
            ),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with different aspect ratio', (
      WidgetTester tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('pic_home', 4 / 3),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('HOME filters every owned duplicate and emits creative once', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en', 'US'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) async => homeCampaign()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CandyBoostBanner), findsOneWidget);
      expect(find.text('owned ordinary'), findsNothing);
    });

    testWidgets('HOME campaign loading withholds ordinary content', (
      tester,
    ) async {
      final pending = Completer<ActivePromotionCampaignsModel>();
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) => pending.future),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('단일 배너'), findsNothing);
    });

    testWidgets('HOME campaign error still renders ordinary content', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) => Future.error(StateError('campaign error'))),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets('inactive owned campaign suppresses ordinary owned rows', (
      tester,
    ) async {
      final inactive = homeCampaign().copyWith(items: []);
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) async => inactive),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('owned ordinary'), findsNothing);
      expect(find.byType(CandyBoostBanner), findsNothing);
    });

    testWidgets('mixed HOME prepends campaign and keeps unowned ordinary', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockMixedBannerList.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) async => homeCampaign()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CandyBoostBanner), findsOneWidget);
      expect(find.text('owned ordinary'), findsNothing);
      expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 2);
    });

    testWidgets('non HOME location never reads promotion provider', (
      tester,
    ) async {
      var reads = 0;
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('pic_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
              (ref) async {
                reads++;
                return homeCampaign();
              },
            ),
          ],
        ),
      );
      expect(reads, 0);
    });

    testWidgets('actual ordinary carousel schedules its displayed duration', (
      tester,
    ) async {
      final scheduler = _Scheduler();
      final moves = <int>[];
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommonBanner(
            'pic_home',
            16 / 9,
            scheduler: scheduler,
            onAutoplayMove: moves.add,
          ),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(
              MockAsyncBannerListMultiple.new,
            ),
          ],
        ),
      );
      expect(scheduler.delays, contains(const Duration(milliseconds: 3000)));
      scheduler.tasks.last.callback();
      await tester.pump();
      expect(moves, contains(1));
      expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 3);
    });

    testWidgets('actual HOME carousel schedules campaign creative duration', (
      tester,
    ) async {
      final scheduler = _Scheduler();
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommonBanner('vote_home', 16 / 9, scheduler: scheduler),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockMixedBannerList.new),
            activePromotionCampaignProvider(
              PromotionSurface.home,
            ).overrideWith((ref) async => homeCampaign()),
          ],
        ),
      );
      await tester.pump();
      expect(scheduler.delays, contains(const Duration(milliseconds: 4500)));
      expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 2);
    });

    testWidgets(
      'actual carousel clamps index and pagination after list shrink',
      (tester) async {
        MutableBannerList.items = await MockAsyncBannerListMultiple().build(
          location: 'pic_home',
        );
        final scheduler = _Scheduler();
        await pumpAndDrain(
          tester,
          buildTestApp(
            CommonBanner('pic_home', 16 / 9, scheduler: scheduler),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(MutableBannerList.new),
            ],
          ),
        );
        expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 3);

        scheduler.tasks.last.callback();
        await tester.pump();
        scheduler.tasks.last.callback();
        await tester.pump();

        MutableBannerList.items = [MutableBannerList.items.first];
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CommonBanner)),
        );
        container.invalidate(asyncBannerListProvider(location: 'pic_home'));
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(Swiper), findsNothing);
        expect(find.byType(CustomPagination), findsNothing);
      },
    );
  });
}
