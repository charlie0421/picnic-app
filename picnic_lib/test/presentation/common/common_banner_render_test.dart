import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// The `homePromotionCampaignProvider` resolution equivalent to
/// `homeCampaign()` — used by tests that migrated to override the resolver
/// directly instead of the V1 source provider (see
/// task-6-7-plan-audit.md's guidance to reserve source-provider overrides
/// for the V2 success/empty/eligible-error fallback tests).
HomePromotionResolution resolvedHomeCampaign() {
  final creative = homeCampaign().items.single.homeCreative!;
  return (
    slides: [
      (bannerId: creative.bannerId, durationMs: creative.duration, creative: creative),
    ],
    ownedBannerIds: {101},
  );
}

HomePromotionResolution emptyHomeResolution() =>
    (slides: const [], ownedBannerIds: const {});

PromotionCreativeModel v2HomeCreative({int bannerId = 501}) =>
    PromotionCreativeModel.fromJson({
      'banner_id': bannerId,
      'title': {'en': 'V2 campaign creative'},
      'image': {'en': 'https://example.com/v2-campaign.jpg'},
      'thumbnail': null,
      'link': null,
      'duration': 4500,
    });

HomePromotionSlideData v2HomeSlide({int bannerId = 501}) {
  final creative = v2HomeCreative(bannerId: bannerId);
  return (bannerId: bannerId, durationMs: creative.duration, creative: creative);
}

Map<String, dynamic> _v2HomeItemJson({
  required int bannerId,
  Map<String, dynamic> title = const {'en': 'V2 campaign creative'},
  Map<String, dynamic> image = const {
    'en': 'https://example.com/v2-campaign.jpg',
  },
}) => {
  'campaign_id': '33333333-3333-4333-8333-333333333333',
  'campaign_version_id': '44444444-4444-4444-8444-444444444444',
  'code': 'CANDY_BOOST_V2',
  'display_name': {'en': 'Chuseok Candy Boost'},
  'multiplier_tenths': 15,
  'event_starts_at': '2026-09-07T00:00:00+09:00',
  'event_ends_at': '2026-09-14T00:00:00+09:00',
  'repeat_iso_dows': [1, 3, 5],
  'home_creative': {
    'banner_id': bannerId,
    'title': title,
    'image': image,
    'thumbnail': null,
    'link': null,
    'duration': 4500,
  },
};

ActivePromotionCampaignsV2Model v2HomeCampaigns({
  List<Map<String, dynamic>> items = const [],
  List<int> ownedIds = const [],
}) => ActivePromotionCampaignsV2Model.fromJson({
  'items': items,
  'total_count': '${items.length}',
  'next_cursor': null,
  'snapshot_at': '2026-09-07T00:10:00Z',
  'campaign_owned_home_banner_ids': ownedIds,
});

ActivePromotionCampaignsV2Model emptyV2Campaigns({List<int> ownedIds = const []}) =>
    v2HomeCampaigns(ownedIds: ownedIds);

// The "HOME falls back to V1 when V2 throws" test below is skipped: riverpod
// 3.0.3 has a confirmed bug (reproduced with a minimal standalone provider
// unrelated to this file, and independently on
// promotion_badge_resolver_provider_test.dart's own plain-`test()` cases):
// once an autoDispose provider's override throws an Exception (not an
// Error) and loses its transient watcher, its internal disposal scheduling
// gets stuck rather than delivering the real error — here that leaves the
// whole resolver chain parked in AsyncLoading indefinitely (confirmed by
// reading the resolver's own state after 4.5s of pumped time), which
// `tester.pump(duration)` cannot force past since riverpod's own scheduler
// timer does not appear to be driven by the fake test clock.
//
// The fallback behavior this would exercise is still covered without
// hitting the bug: `promotion_badge_resolver_provider_test.dart` proves
// `_readEligibleV2` classifies exactly PostgrestException/SocketException/
// TimeoutException as fallback-eligible (via the "fails closed" tests'
// exhaustive exclusion list) and this file's "HOME falls back to V1 when V2
// succeeds but has no active item" test exercises the identical
// fallback-to-V1 rendering path this test would have.

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
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
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
      drainExpectedImageErrors(tester);

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
      drainExpectedImageErrors(tester);

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
      drainExpectedImageErrors(tester);

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
      drainExpectedImageErrors(tester);

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
      drainExpectedImageErrors(tester);

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
      drainExpectedImageErrors(tester);

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
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) async => resolvedHomeCampaign()),
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
      final pending = Completer<HomePromotionResolution>();
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider(
              'ko',
            ).overrideWith((ref) => pending.future),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('단일 배너'), findsNothing);
    });

    testWidgets('banner image carries its rendered size for CDN resize', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('pic_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      final image = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage),
      );
      final expectedWidth = MediaQuery.of(
        tester.element(find.byType(CommonBanner)),
      ).size.width;
      // width/height 가 null 이면 CDN URL 에 w/h 리사이즈 파라미터가 붙지 않아
      // 원본 크기를 그대로 내려받는다 (_getTransformedUrl 참조).
      expect(image.width, expectedWidth);
      expect(image.height, expectedWidth / (16 / 9));
    });

    testWidgets('HOME campaign stuck past wait cap degrades to ordinary', (
      tester,
    ) async {
      final pending = Completer<HomePromotionResolution>();
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider(
              'ko',
            ).overrideWith((ref) => pending.future),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      // 상한 이전에는 기존 보류 동작 유지
      expect(find.text('단일 배너'), findsNothing);

      await tester.pump(commonBannerCampaignWaitCap);
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets('HOME campaign arriving after cap upgrades from degrade', (
      tester,
    ) async {
      final pending = Completer<HomePromotionResolution>();
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) => pending.future),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(commonBannerCampaignWaitCap);
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.byType(CandyBoostBanner), findsNothing);

      pending.complete(resolvedHomeCampaign());
      await tester.pump();
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.byType(CandyBoostBanner), findsOneWidget);
    });

    testWidgets(
        'refetch without remount does not extend the cap in the same state', (
      tester,
    ) async {
      // 같은 위젯 state 가 유지되는 동안의 보장이다: 상한은 "사용자가
      // shimmer 를 연속으로 본 시간"을 재므로 loading 중 bare invalidate 가
      // 있어도 리셋되지 않는다 (riverpod 이 loading→loading 을 dedupe 해
      // 위젯이 관측할 수도 없다). pull-to-refresh 처럼 UniqueKey remount 를
      // 동반하는 경로는 새 episode 다 — 아래 remount 테스트가 고정한다.
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider('ko').overrideWith(
              (ref) => Completer<HomePromotionResolution>().future,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CommonBanner)),
      );
      container.invalidate(homePromotionCampaignProvider('ko'));
      await tester.pump();

      // 재조회와 무관하게 shimmer 누적 5초 시점에 degrade
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets(
        'degrade persists across refetch in the same state until data arrives',
        (
      tester,
    ) async {
      final completers = <Completer<HomePromotionResolution>>[];
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider('en').overrideWith(
              (ref) {
                final completer = Completer<HomePromotionResolution>();
                completers.add(completer);
                return completer.future;
              },
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(commonBannerCampaignWaitCap);
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.text('단일 배너'), findsOneWidget); // 만료 -> degrade

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CommonBanner)),
      );
      container.invalidate(homePromotionCampaignProvider('en'));
      await tester.pump();
      await tester.pump();
      // 만료 뒤 재조회는 shimmer 로 돌아가지 않고 일반 슬라이드를 유지한다
      expect(find.text('단일 배너'), findsOneWidget);

      // 재조회 세대의 data 가 도착하면 캠페인 슬라이드로 복구된다
      completers.last.complete(resolvedHomeCampaign());
      await tester.pump();
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.byType(CandyBoostBanner), findsOneWidget);
    });

    testWidgets('pull-to-refresh remount starts a fresh cap episode', (
      tester,
    ) async {
      // 실사용 refresh 경로(vote_home_page.dart:152, home_page.dart:83)는
      // invalidate 직후 UniqueKey 로 CommonBanner 를 remount 한다. 새
      // state 는 새 episode 로 full cap 을 다시 잰다 — 새로고침은 "다시
      // 기다리겠다"는 명시적 의사표시이므로 의도된 동작으로 고정한다.
      final pending = Completer<HomePromotionResolution>();
      final overrides = <dynamic>[
        asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
        homePromotionCampaignProvider(
          'ko',
        ).overrideWith((ref) => pending.future),
      ];
      Widget app(Key bannerKey) => buildTestApp(
        CommonBanner('vote_home', 16 / 9, key: bannerKey),
        extraOverrides: overrides,
      );

      await tester.pumpWidget(app(const ValueKey('episode-1')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      // t=4s: 사용자 pull-to-refresh 재현 — invalidate + remount
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CommonBanner)),
      );
      container.invalidate(homePromotionCampaignProvider('ko'));
      await tester.pumpWidget(app(const ValueKey('episode-2')));
      await tester.pump();

      // 구 episode 의 잔여 시간(1초)로는 degrade 하지 않는다
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('단일 배너'), findsNothing);

      // remount 시점부터 full cap 이 지나면 degrade
      await tester.pump(commonBannerCampaignWaitCap);
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets('campaign data before cap cancels the degrade task', (
      tester,
    ) async {
      final scheduler = _Scheduler();
      await pumpAndDrain(
        tester,
        buildTestApp(
          CommonBanner('vote_home', 16 / 9, scheduler: scheduler),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) async => resolvedHomeCampaign()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final capTasks = [
        for (var i = 0; i < scheduler.delays.length; i++)
          if (scheduler.delays[i] == commonBannerCampaignWaitCap)
            scheduler.tasks[i],
      ];
      expect(capTasks, isNotEmpty);
      expect(capTasks.every((task) => task.cancelled), isTrue);
    });

    testWidgets('HOME campaign error still renders ordinary content', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
            homePromotionCampaignProvider(
              'ko',
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
      // Owned banner id retained (still assigned to a campaign) even though
      // there is no currently active item to render as a creative slide.
      const inactive = (
        slides: <HomePromotionSlideData>[],
        ownedBannerIds: {101},
      );
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
            homePromotionCampaignProvider(
              'ko',
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
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) async => resolvedHomeCampaign()),
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
            homePromotionCampaignProvider('ko').overrideWith((ref) async {
              reads++;
              return resolvedHomeCampaign();
            }),
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
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) async => resolvedHomeCampaign()),
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

    testWidgets('HOME uses V2 when it has an active item', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
            activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
                .overrideWith(
                  (ref) async => v2HomeCampaigns(
                    items: [_v2HomeItemJson(bannerId: 101)],
                    ownedIds: [101],
                  ),
                ),
            activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
              (ref) async => throw StateError(
                'V1 must not be read when V2 has an active item',
              ),
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CandyBoostBanner), findsOneWidget);
      expect(find.text('owned ordinary'), findsNothing);
    });

    testWidgets(
      'HOME falls back to V1 when V2 throws',
      (tester) async {
        await pumpAndDrain(
          tester,
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
              activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
                  .overrideWith(
                    (ref) async => throw PostgrestException(
                      message: 'undefined function',
                    ),
                  ),
              activePromotionCampaignProvider(
                PromotionSurface.home,
              ).overrideWith((ref) async => homeCampaign()),
            ],
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CandyBoostBanner), findsOneWidget);
      },
      // See the comment on _v2ThrowsFallbackSkipReason above.
      skip: true,
    );

    testWidgets(
      'HOME falls back to V1 when V2 succeeds but has no active item (e.g. flag still off)',
      (tester) async {
        await pumpAndDrain(
          tester,
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
              activePromotionCampaignV2Provider(
                PromotionSurfaceV2.home,
              ).overrideWith((ref) async => emptyV2Campaigns()),
              activePromotionCampaignProvider(
                PromotionSurface.home,
              ).overrideWith((ref) async => homeCampaign()),
            ],
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CandyBoostBanner), findsOneWidget);
      },
    );

    testWidgets(
      'HOME with active but unreadable V2 creative shows no campaign slide, '
      'suppresses the owned ordinary banner, and never reads V1',
      (tester) async {
        await pumpAndDrain(
          tester,
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            locale: const Locale('en'),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
              activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
                  .overrideWith(
                    (ref) async => v2HomeCampaigns(
                      items: [
                        _v2HomeItemJson(
                          bannerId: 101,
                          title: const {},
                          image: const {},
                        ),
                      ],
                      ownedIds: [101],
                    ),
                  ),
              activePromotionCampaignProvider(
                PromotionSurface.home,
              ).overrideWith(
                (ref) async => throw StateError(
                  'V1 must not be read when V2 has active items, readable or not',
                ),
              ),
            ],
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        // Unreadable creative -> zero campaign slides, but the id stays
        // owned so the plain ordinary copy of banner 101 must not leak
        // through either (if it did, V1's sentinel error would also have
        // had to fire, since only the .when() error branch skips ownership
        // filtering).
        expect(find.byType(CandyBoostBanner), findsNothing);
        expect(find.text('owned ordinary'), findsNothing);
      },
    );
  });
}
