import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';
import 'common_banner_render_test.dart' show MutableBannerList, ordinaryBanner;

final class _PendingBannerList extends AsyncBannerList {
  static Future<List<BannerModel>> next = Future.value(const []);

  @override
  Future<List<BannerModel>> build({required String location}) => next;
}

final class _ManualAutoplay implements CommonBannerScheduler {
  final List<VoidCallback> callbacks = [];

  @override
  CommonBannerScheduledTask schedule(Duration delay, VoidCallback callback) {
    callbacks.add(callback);
    return _ManualAutoplayTask();
  }
}

final class _ManualAutoplayTask implements CommonBannerScheduledTask {
  @override
  void cancel() {}
}

/// The app shell (`PicnicAnimatedSwitcher`) stacks pages in an [IndexedStack]:
/// a covered home stays mounted and laid out but is not painted.
class _PageStack extends StatelessWidget {
  const _PageStack({required this.page, required this.home});

  final ValueNotifier<int> page;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: page,
      builder: (context, index, _) => IndexedStack(
        index: index,
        children: [
          // Like HomePage, sections are children of a vertical ListView.
          ListView(children: [home]),
          const ColoredBox(color: Colors.white),
        ],
      ),
    );
  }
}

String _large(int id) =>
    'https://test-cdn.example.com/banner/$id.jpg?q=80&w=1000';

List<BannerModel> _cdnBanners(int count) => [
  for (var id = 1; id <= count; id++)
    BannerModel.fromJson({
      'id': id,
      'title': {'en': 'Banner $id', 'ko': 'Banner $id'},
      'thumbnail': '/banner/$id-thumb.jpg',
      'image': {'en': '/banner/$id.jpg'},
      'duration': 3000,
      'link': null,
    }),
];

const _campaignLarge =
    'https://test-cdn.example.com/banner/campaign.jpg?q=80&w=1000';

HomePromotionResolution _cdnCampaign() {
  final creative = PromotionCreativeModel.fromJson({
    'banner_id': 101,
    'title': {'en': 'Candy Boost Day'},
    'image': {'en': '/banner/campaign.jpg'},
    'thumbnail': null,
    'link': null,
    'duration': 4500,
  });
  return (
    slides: [(bannerId: 101, durationMs: 4500, creative: creative)],
    ownedBannerIds: {101},
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, [
  String what = 'asynchronous image work',
]) async {
  for (var i = 0; i < 150 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump();
  }
  expect(
    done(),
    isTrue,
    reason:
        '$what did not settle: '
        '${PicnicImagePrefetchScope.schedulerStateForTest}',
  );
}

bool _schedulerIdle() =>
    PicnicImagePrefetchScope.schedulerStateForTest ==
    (inFlight: 0, unclaimed: 0, queued: 0);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

bool _decoded(WidgetTester tester, int id) =>
    _decodedIn(tester, find.byKey(ValueKey('banner_$id')));

bool _decodedIn(WidgetTester tester, Finder slide) => tester
    .widgetList<RawImage>(
      find.descendant(of: slide, matching: find.byType(RawImage)),
    )
    .any((raw) => raw.image != null);

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({'banner': <dynamic>[]});
    resetSuccessfullyLoadedImageUrlsForTest();
  });

  tearDown(tearDownMockSupabase);

  testWidgets('constrained banners reuse prepared decode keys across slides', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    MutableBannerList.items = [
      for (var id = 1; id <= 3; id++) ordinaryBanner(id, 'Banner $id'),
    ];
    for (var id = 1; id <= 3; id++) {
      await tester.runAsync(
        () => harness.respondPng(
          'https://example.com/$id.jpg',
          width: 800,
          height: 400,
        ),
      );
    }
    await tester.pumpWidget(
      buildTestApp(
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 240, child: CommonBanner('pic_home', 2)),
        ),
        locale: const Locale('en'),
        extraOverrides: [
          asyncBannerListProvider.overrideWith(MutableBannerList.new),
        ],
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    final banner = tester.widget<PicnicCachedNetworkImage>(
      find.byKey(const ValueKey('banner_1')),
    );
    expect(banner.width, 240);
    expect(banner.height, 120);
    expect(banner.memCacheWidth, isNull);
    final request = banner.imageRequest!;
    final context = tester.element(find.byKey(const ValueKey('banner_1')));
    final configuration = createLocalImageConfiguration(context);
    final key = await request.obtainKey(configuration);
    final completer = request.provider.resolve(configuration).completer;
    final raw = tester
        .widgetList<RawImage>(
          find.descendant(
            of: find.byKey(const ValueKey('banner_1')),
            matching: find.byType(RawImage),
          ),
        )
        .singleWhere((image) => image.image != null)
        .image!;
    expect(raw.width / raw.height, closeTo(2, .02));
    expect(raw.width, request.decodeWidth);
    expect(harness.requestsFor(request.url), 1);

    final swiper = tester.widget<Swiper>(find.byType(Swiper));
    unawaited(swiper.controller!.move(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    unawaited(swiper.controller!.move(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final returned = tester.widget<PicnicCachedNetworkImage>(
      find.byKey(const ValueKey('banner_1')),
    );
    expect(await returned.imageRequest!.obtainKey(configuration), key);
    expect(
      returned.imageRequest!.provider.resolve(configuration).completer,
      same(completer),
    );
    expect(harness.requestsFor(request.url), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    // A started prefetch outlives its scope; let it finish before the
    // harness closes, or it stays in the shared scheduler for later tests.
    await _pumpUntil(tester, _schedulerIdle, 'prefetch teardown');
  });

  testWidgets('first-party banners request one large variant at any width', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    String large(int id) =>
        'https://test-cdn.example.com/banner/$id.jpg?q=80&w=1000';
    MutableBannerList.items = [
      for (var id = 1; id <= 2; id++)
        BannerModel.fromJson({
          'id': id,
          'title': {'en': 'Banner $id', 'ko': 'Banner $id'},
          'thumbnail': '/banner/$id-thumb.jpg',
          'image': {'en': '/banner/$id.jpg'},
          'duration': 3000,
          'link': null,
        }),
    ];
    for (var id = 1; id <= 2; id++) {
      await tester.runAsync(
        () => harness.respondPng(large(id), width: 800, height: 400),
      );
    }

    for (final width in [240.0, 390.0]) {
      await tester.pumpWidget(
        buildTestApp(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: const CommonBanner('pic_home', 2),
            ),
          ),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MutableBannerList.new),
          ],
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      final banner = tester.widget<PicnicCachedNetworkImage>(
        find.byKey(const ValueKey('banner_1')),
      );
      expect(banner.imageRequest!.url, large(1), reason: 'width $width');
    }

    // The visible slide and the prefetched next slide use the same variant,
    // and a new banner width reuses the bytes instead of a new CDN variant.
    expect(harness.requestsFor(large(1)), 1);
    expect(harness.requestsFor(large(2)), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(tester, _schedulerIdle, 'prefetch teardown');
  });

  testWidgets('below-fold banner admits no HTTP until it scrolls into view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    addTearDown(() => PicnicCachedNetworkImage.disableTimeoutForTest = false);
    final harness = await ImageTestHarness.create();
    addTearDown(() => tester.runAsync(harness.dispose));
    await _pumpUntil(tester, _schedulerIdle);
    MutableBannerList.items = _cdnBanners(3);
    await tester.runAsync(() async {
      for (var id = 1; id <= 3; id++) {
        await harness.respondPng(_large(id), width: 800, height: 400);
      }
    });
    List<int> requests() => [
      for (var id = 1; id <= 3; id++) harness.requestsFor(_large(id)),
    ];

    await tester.pumpWidget(
      buildTestApp(
        // Built inside the vertical list's cache extent, one screen down.
        ListView(
          children: const [SizedBox(height: 700), CommonBanner('pic_home', 2)],
        ),
        locale: const Locale('en'),
        extraOverrides: [
          asyncBannerListProvider.overrideWith(MutableBannerList.new),
        ],
      ),
    );
    await _settle(tester);

    expect(
      find.byKey(const ValueKey('banner_1'), skipOffstage: false),
      findsOneWidget,
    );
    expect(requests(), [0, 0, 0]);

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await _pumpUntil(tester, () => _decoded(tester, 1));
    await _pumpUntil(tester, _schedulerIdle);

    // The visible slide and only the next one, at the fixed large variant.
    expect(requests(), [1, 1, 0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(tester, _schedulerIdle, 'prefetch teardown');
  });

  testWidgets(
    'covered banner drops its queued next slide; autoplay still shows it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      PicnicCachedNetworkImage.disableTimeoutForTest = true;
      addTearDown(() => PicnicCachedNetworkImage.disableTimeoutForTest = false);
      final harness = await ImageTestHarness.create();
      // Real async lets held streams close even when an expectation fails.
      addTearDown(() => tester.runAsync(harness.dispose));
      await _pumpUntil(tester, _schedulerIdle);
      const blockers = [
        'https://images.example.com/blocker-a.png',
        'https://images.example.com/blocker-b.png',
      ];
      await tester.runAsync(() async {
        for (var id = 1; id <= 3; id++) {
          await harness.respondPng(_large(id), width: 800, height: 400);
        }
        for (final url in blockers) {
          await harness.respondPng(url, held: true);
        }
      });
      final banners = Completer<List<BannerModel>>();
      _PendingBannerList.next = banners.future;
      final autoplay = _ManualAutoplay();
      final moves = <int>[];
      final page = ValueNotifier<int>(0);
      addTearDown(page.dispose);
      late BuildContext appContext;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              appContext = context;
              return _PageStack(
                page: page,
                home: CommonBanner(
                  'pic_home',
                  2,
                  scheduler: autoplay,
                  onAutoplayMove: moves.add,
                ),
              );
            },
          ),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(_PendingBannerList.new),
          ],
        ),
      );
      // Another screen's prefetch holds both background slots, so the
      // banner's next slide has to wait in the queue.
      final blocker = PicnicImagePrefetchScope();
      addTearDown(blocker.dispose);
      blocker.replace(appContext, [
        for (final url in blockers)
          PicnicImageRequest.resolve(
            context: appContext,
            imageUrl: url,
            width: 40,
            height: 20,
          ),
      ]);
      await _pumpUntil(
        tester,
        () => blockers.every((url) => harness.requestsFor(url) == 1),
      );

      banners.complete(_cdnBanners(3));
      await _pumpUntil(
        tester,
        () =>
            _decoded(tester, 1) &&
            PicnicImagePrefetchScope.schedulerStateForTest.queued == 1,
      );
      expect(harness.requestsFor(_large(2)), 0);

      // A pushed page covers home; home stays mounted under it.
      page.value = 1;
      await _settle(tester);
      expect(PicnicImagePrefetchScope.schedulerStateForTest.queued, 0);

      for (final url in blockers) {
        harness.release(url);
      }
      await _pumpUntil(tester, () => harness.activeRequests == 0);
      await _settle(tester);
      expect(harness.requestsFor(_large(2)), 0);

      page.value = 0;
      await _pumpUntil(tester, () => harness.requestsFor(_large(2)) == 1);
      await _pumpUntil(tester, _schedulerIdle);

      autoplay.callbacks.last();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await _pumpUntil(tester, () => _decoded(tester, 2));

      expect(moves, [1]);
      expect(
        tester
            .widget<CustomPagination>(find.byType(CustomPagination))
            .activeIndex,
        1,
      );
      final shown = tester.widget<PicnicCachedNetworkImage>(
        find.byKey(const ValueKey('banner_2')),
      );
      expect(shown.imageRequest!.url, _large(2));
      // The slide the user now sees reused the prepared bytes.
      expect(harness.requestsFor(_large(2)), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpUntil(tester, _schedulerIdle, 'prefetch teardown');
    },
  );

  testWidgets(
    'covered HOME campaign admits no HTTP until home shows; autoplay moves on',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      PicnicCachedNetworkImage.disableTimeoutForTest = true;
      addTearDown(() => PicnicCachedNetworkImage.disableTimeoutForTest = false);
      final harness = await ImageTestHarness.create();
      addTearDown(() => tester.runAsync(harness.dispose));
      await _pumpUntil(tester, _schedulerIdle);
      MutableBannerList.items = _cdnBanners(1);
      await tester.runAsync(() async {
        await harness.respondPng(_campaignLarge, width: 800, height: 400);
        await harness.respondPng(_large(1), width: 800, height: 400);
      });
      final autoplay = _ManualAutoplay();
      final moves = <int>[];
      // Home starts under another page: mounted and laid out, never painted.
      final page = ValueNotifier<int>(1);
      addTearDown(page.dispose);
      await tester.pumpWidget(
        buildTestApp(
          _PageStack(
            page: page,
            home: CommonBanner(
              'vote_home',
              2,
              scheduler: autoplay,
              onAutoplayMove: moves.add,
            ),
          ),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(MutableBannerList.new),
            // Resolved before the banner rows arrive, so the campaign is the
            // first and current slide.
            homePromotionCampaignProvider(
              'en',
            ).overrideWith((ref) => _cdnCampaign()),
          ],
        ),
      );
      await _settle(tester);

      expect(
        find.byType(CandyBoostBanner, skipOffstage: false),
        findsOneWidget,
      );
      expect(harness.requestsFor(_campaignLarge), 0);
      expect(harness.requestsFor(_large(1)), 0);

      page.value = 0;
      await _pumpUntil(
        tester,
        () => _decodedIn(tester, find.byType(CandyBoostBanner)),
      );
      await _pumpUntil(tester, _schedulerIdle);
      // The campaign at its fixed large variant, plus only the next slide.
      expect(harness.requestsFor(_campaignLarge), 1);
      expect(harness.requestsFor(_large(1)), 1);

      autoplay.callbacks.last();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await _pumpUntil(tester, () => _decoded(tester, 1));

      expect(moves, [1]);
      expect(
        tester
            .widget<CustomPagination>(find.byType(CustomPagination))
            .activeIndex,
        1,
      );
      expect(harness.requestsFor(_campaignLarge), 1);
      expect(harness.requestsFor(_large(1)), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpUntil(tester, _schedulerIdle, 'prefetch teardown');
    },
  );
}
