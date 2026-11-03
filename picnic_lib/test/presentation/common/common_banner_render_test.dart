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

class ScriptedBannerList extends AsyncBannerList {
  static final List<Future<List<BannerModel>>> responses = [];

  @override
  Future<List<BannerModel>> build({required String location}) =>
      responses.removeAt(0);
}

BannerModel ordinaryBanner(int id, String title) => BannerModel.fromJson({
  'id': id,
  'title': {'en': title, 'ko': title},
  'thumbnail': 'https://example.com/$id-thumb.jpg',
  'image': {'en': 'https://example.com/$id.jpg'},
  'duration': 3000,
  'link': null,
});

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
      (
        bannerId: creative.bannerId,
        durationMs: creative.duration,
        creative: creative,
      ),
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
  return (
    bannerId: bannerId,
    durationMs: creative.duration,
    creative: creative,
  );
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

ActivePromotionCampaignsV2Model emptyV2Campaigns({
  List<int> ownedIds = const [],
}) => v2HomeCampaigns(ownedIds: ownedIds);

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
    ScriptedBannerList.responses.clear();
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

    testWidgets('HOME campaign loading displays ordinary content immediately', (
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
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets(
      'HOME hides cached ordinary data while a session-bound banner refresh is pending',
      (tester) async {
        final normalResponse = Completer<List<BannerModel>>();
        ScriptedBannerList.responses.addAll([
          Future.value([ordinaryBanner(900, 'admin-only ordinary')]),
          normalResponse.future,
        ]);
        await pumpAndDrain(
          tester,
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            locale: const Locale('en'),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(ScriptedBannerList.new),
              homePromotionCampaignProvider(
                'en',
              ).overrideWith((ref) async => emptyHomeResolution()),
            ],
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CommonBanner)),
        );
        await tester.runAsync(
          () => container.read(
            asyncBannerListProvider(location: 'vote_home').future,
          ),
        );
        await tester.pump();
        expect(find.text('admin-only ordinary'), findsOneWidget);

        container.invalidate(asyncBannerListProvider(location: 'vote_home'));
        await tester.pump();

        expect(
          find.text('admin-only ordinary'),
          findsNothing,
          reason: 'retained ordinary AsyncData belongs to the previous session',
        );

        normalResponse.complete([ordinaryBanner(901, 'normal ordinary')]);
        await tester.pump();
        await tester.pump();
        drainExpectedImageErrors(tester);
        expect(find.text('normal ordinary'), findsOneWidget);
      },
    );

    testWidgets(
      'HOME never renders cached campaign data during refresh loading or error',
      (tester) async {
        final nextCampaign = Completer<HomePromotionResolution>();
        var reads = 0;
        await pumpAndDrain(
          tester,
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            locale: const Locale('en'),
            retry: (_, _) => null,
            extraOverrides: [
              asyncBannerListProvider.overrideWith(
                MockAsyncBannerListSingle.new,
              ),
              homePromotionCampaignProvider('en').overrideWith((ref) {
                if (reads++ == 0) {
                  return Future.value(resolvedHomeCampaign());
                }
                return nextCampaign.future;
              }),
            ],
          ),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CommonBanner)),
        );
        await tester.runAsync(
          () => container.read(homePromotionCampaignProvider('en').future),
        );
        await tester.pump();
        // Ordinary content is already visible before the campaign resolves.
        // Select the campaign before testing that refresh removes its content.
        unawaited(
          tester.widget<Swiper>(find.byType(Swiper)).controller!.move(0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CandyBoostBanner), findsOneWidget);

        container.invalidate(homePromotionCampaignProvider('en'));
        await tester.pump();
        expect(
          find.byType(CandyBoostBanner),
          findsNothing,
          reason: 'a refreshing campaign value may belong to the old account',
        );

        nextCampaign.completeError(StateError('normal user is not eligible'));
        await tester.pump();
        await tester.pump();
        drainExpectedImageErrors(tester);
        expect(find.byType(CandyBoostBanner), findsNothing);
        expect(
          find.text('단일 배너'),
          findsOneWidget,
          reason: 'fresh ordinary data remains the narrow HOME error fallback',
        );
      },
    );

    testWidgets('banner image uses its constrained size for CDN resize', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 240,
              child: CommonBanner('pic_home', 16 / 9),
            ),
          ),
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
      final expectedWidth = tester.getSize(find.byType(CommonBanner)).width;
      expect(image.width, expectedWidth);
      expect(image.height, expectedWidth / (16 / 9));
      expect(image.memCacheWidth, isNull);
      expect(image.memCacheHeight, isNull);
    });

    testWidgets('ordinary HOME remains visible while campaign never resolves', (
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
      expect(find.text('단일 배너'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      drainExpectedImageErrors(tester);
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets('late HOME campaign joins the visible ordinary slide', (
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
      expect(find.byType(CandyBoostBanner), findsNothing);
      pending.complete(resolvedHomeCampaign());
      await tester.pump();
      await tester.pump();
      drainExpectedImageErrors(tester);
      expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 2);
      expect(
        tester
            .widget<CustomPagination>(find.byType(CustomPagination))
            .activeIndex,
        1,
      );
    });

    testWidgets('campaign invalidation does not hide ready ordinary data', (
      tester,
    ) async {
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
      expect(find.text('단일 배너'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CommonBanner)),
      );
      container.invalidate(homePromotionCampaignProvider('ko'));
      await tester.pump();
      expect(find.text('단일 배너'), findsOneWidget);
    });

    testWidgets(
      'campaign data joins after a refetch without a blank interval',
      (tester) async {
        final completers = <Completer<HomePromotionResolution>>[];
        await tester.pumpWidget(
          buildTestApp(
            const CommonBanner('vote_home', 16 / 9),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(
                MockAsyncBannerListSingle.new,
              ),
              homePromotionCampaignProvider('ko').overrideWith((ref) {
                final response = Completer<HomePromotionResolution>();
                completers.add(response);
                return response.future;
              }),
            ],
          ),
        );
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CommonBanner)),
        );
        container.invalidate(homePromotionCampaignProvider('ko'));
        await tester.pump();
        await tester.pump();
        expect(find.text('단일 배너'), findsOneWidget);
        completers.last.complete(resolvedHomeCampaign());
        await tester.pump();
        await tester.pump();
        drainExpectedImageErrors(tester);
        expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 2);
      },
    );

    testWidgets(
      'refresh remount immediately shows available ordinary banners',
      (tester) async {
        final pending = Completer<HomePromotionResolution>();
        final overrides = <dynamic>[
          asyncBannerListProvider.overrideWith(MockAsyncBannerListSingle.new),
          homePromotionCampaignProvider(
            'ko',
          ).overrideWith((ref) => pending.future),
        ];
        Widget app(Key key) => buildTestApp(
          CommonBanner('vote_home', 16 / 9, key: key),
          extraOverrides: overrides,
        );
        await tester.pumpWidget(app(const ValueKey('episode-1')));
        await tester.pump();
        expect(find.text('단일 배너'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CommonBanner)),
        );
        container.invalidate(homePromotionCampaignProvider('ko'));
        await tester.pumpWidget(app(const ValueKey('episode-2')));
        await tester.pump();
        expect(find.text('단일 배너'), findsOneWidget);
      },
    );

    testWidgets('single ordinary banner schedules no campaign wait task', (
      tester,
    ) async {
      final scheduler = _Scheduler();
      final pending = Completer<HomePromotionResolution>();
      await tester.pumpWidget(
        buildTestApp(
          CommonBanner('vote_home', 16 / 9, scheduler: scheduler),
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
      expect(find.text('단일 배너'), findsOneWidget);
      expect(scheduler.tasks, isEmpty);
    });

    testWidgets(
      'late campaign and rebuilds preserve the current autoplay deadline',
      (tester) async {
        final scheduler = _Scheduler();
        final pending = Completer<HomePromotionResolution>();
        final moves = <int>[];
        await tester.pumpWidget(
          buildTestApp(
            CommonBanner(
              'vote_home',
              16 / 9,
              scheduler: scheduler,
              onAutoplayMove: moves.add,
            ),
            extraOverrides: [
              asyncBannerListProvider.overrideWith(
                MockAsyncBannerListMultiple.new,
              ),
              homePromotionCampaignProvider(
                'ko',
              ).overrideWith((ref) => pending.future),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
        final originalTask = scheduler.tasks.single;
        for (var i = 0; i < 5; i++) {
          tester.element(find.byType(CommonBanner)).markNeedsBuild();
          await tester.pump();
        }
        expect(scheduler.tasks, hasLength(1));
        pending.complete(resolvedHomeCampaign());
        await tester.pump();
        await tester.pump();
        expect(
          tester
              .widget<CustomPagination>(find.byType(CustomPagination))
              .activeIndex,
          1,
        );
        expect(scheduler.tasks.single, same(originalTask));
        expect(originalTask.cancelled, isFalse);
        originalTask.callback();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(moves, [2]);
        expect(
          tester
              .widget<CustomPagination>(find.byType(CustomPagination))
              .activeIndex,
          2,
        );
        expect(scheduler.delays.last, const Duration(milliseconds: 5000));
        originalTask.callback();
        expect(moves, [
          2,
        ], reason: 'an expired callback cannot advance a newer timer');
      },
    );

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
      expect(tester.widget<Swiper>(find.byType(Swiper)).itemCount, 2);
      scheduler.tasks.last.callback();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(scheduler.delays, contains(const Duration(milliseconds: 4500)));
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
            activePromotionCampaignV2Provider(
              PromotionSurfaceV2.home,
            ).overrideWith(
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

    testWidgets('HOME falls back to V1 when the V2 RPC is missing (PGRST202)', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          // The thrown PostgrestException is an Exception, so riverpod's
          // default retry would park the erroring V2 source in a retrying
          // loading state behind real backoff timers — disable retry so
          // the terminal error (and the resolver's V1 fallback built on
          // it) is observable within pumped test time.
          retry: (_, _) => null,
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockOwnedBannerList.new),
            activePromotionCampaignV2Provider(
              PromotionSurfaceV2.home,
            ).overrideWith(
              (ref) async => throw PostgrestException(
                message:
                    'Could not find the function '
                    'public.get_active_promotion_campaigns_v2'
                    '(p_surface) in the schema cache',
                code: 'PGRST202',
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
    });

    testWidgets('HOME renders only ordinary banners when V2 fails with a '
        'non-eligible PostgREST error (fail closed, no V1 campaign revival)', (
      tester,
    ) async {
      var v1Read = false;
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('vote_home', 16 / 9),
          locale: const Locale('en'),
          retry: (_, _) => null,
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MockMixedBannerList.new),
            activePromotionCampaignV2Provider(
              PromotionSurfaceV2.home,
            ).overrideWith(
              (ref) async => throw PostgrestException(
                message: 'permission denied for function',
                code: '42501',
              ),
            ),
            activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
              (ref) async {
                v1Read = true;
                return homeCampaign();
              },
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      // The resolver rethrows, CommonBanner's error branch renders the
      // ordinary list without campaign slides or ownership filtering, and
      // V1 was never consulted. The swiper's current slide is the first
      // ordinary banner — its unfiltered visibility (compare the success
      // path, where owned id 101 is suppressed) proves the error branch
      // ran rather than the list merely still loading.
      expect(find.byType(CandyBoostBanner), findsNothing);
      expect(v1Read, isFalse);
      expect(find.text('owned ordinary'), findsOneWidget);
    });

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
              activePromotionCampaignV2Provider(
                PromotionSurfaceV2.home,
              ).overrideWith(
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
