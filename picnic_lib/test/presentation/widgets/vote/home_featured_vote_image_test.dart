import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/image_test_harness.dart';
import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _MutableFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() async => _entries([1, 2, 3, 4]);
}

class _CdnFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() async =>
      _entries([1, 2, 3, 4], imageBase: '/artist/hero');
}

class _PendingFeaturedVotes extends AsyncActiveFeaturedVotes {
  _PendingFeaturedVotes(this._votes);

  final Future<List<FeaturedVoteEntry>> _votes;

  @override
  Future<List<FeaturedVoteEntry>> build() => _votes;
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

List<FeaturedVoteEntry> _entries(
  List<int> ids, {
  String imageBase = 'https://example.com/hero',
}) => [
  for (final id in ids)
    FeaturedVoteEntry(
      vote: VoteFactory.create(
        id: id,
        voteItem: [
          VoteItemFactory.create(
            id: id,
            artist: ArtistFactory.create(id: id, image: '$imageBase-$id.png'),
          ),
        ],
      ),
      totalVotes: 100,
    ),
];

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    initTestColors();
    setupMockSupabase({});
    resetSuccessfullyLoadedImageUrlsForTest();
  });
  tearDown(tearDownMockSupabase);

  void useDevice(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(tester.view.reset);
  }

  Future<void> decodeFrames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  Future<void> pumpUntil(
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

  bool schedulerIdle() =>
      PicnicImagePrefetchScope.schedulerStateForTest ==
      (inFlight: 0, unclaimed: 0, queued: 0);

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'featured hero keeps its contents inside a small card at $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        addTearDown(tester.view.reset);
        final harness = await ImageTestHarness.create();
        addTearDown(harness.dispose);
        const url = 'https://example.com/hero-small.png';
        await tester.runAsync(
          () => harness.respondPng(url, width: 800, height: 400),
        );
        final vote = VoteFactory.create(
          title: {'ko': '현재 진행 중인 아티스트 투표'},
          voteItem: [
            VoteItemFactory.create(
              artist: ArtistFactory.create(
                image: url,
                name: {'ko': '이름이 아주 긴 아티스트'},
              ),
            ),
          ],
        );
        await tester.pumpWidget(
          buildTestApp(
            Center(
              child: SizedBox(
                width: 250,
                height: 364,
                child: HomeFeaturedVoteCard(vote: vote, percent: 1),
              ),
            ),
            designSize: const Size(393, 892),
            splitScreenMode: true,
            textScaler: TextScaler.linear(scale),
          ),
        );
        await decodeFrames(tester);
        expect(tester.takeException(), isNull);
        final hero = tester.getRect(find.byType(PicnicCachedNetworkImage));
        final percent = tester.getRect(find.text('100.0%'));
        expect(percent.right, lessThanOrEqualTo(hero.right));
        expect(percent.bottom, lessThanOrEqualTo(hero.bottom));
        expect(hero.width, closeTo(HomeFeaturedVoteCard.heroWidth(250), 0.01));
        expect(harness.requestsFor(url), 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets(
    'visible hero loads once and keeps its decode when height changes',
    (tester) async {
      useDevice(tester);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const url = 'https://example.com/hero-1.png';
      await tester.runAsync(
        () => harness.respondPng(url, width: 800, height: 400),
      );
      final vote = _entries([1]).single.vote;
      Widget app(double height) => buildTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            height: height,
            child: HomeFeaturedVoteCard(vote: vote),
          ),
        ),
      );
      await tester.pumpWidget(app(372));
      await decodeFrames(tester);
      final first = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage),
      );
      expect(first.imageRequest, isNotNull);
      expect(first.imageRequest!.url, url);
      final config = createLocalImageConfiguration(
        tester.element(find.byType(PicnicCachedNetworkImage)),
      );
      final key = await first.imageRequest!.obtainKey(config);
      final completer = first.imageRequest!.provider.resolve(config).completer;
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((raw) => raw.image != null),
        isTrue,
      );
      expect(harness.requestsFor(url), 1);
      await tester.pumpWidget(app(440));
      await tester.pump();
      final resized = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage),
      );
      expect(await resized.imageRequest!.obtainKey(config), key);
      expect(
        resized.imageRequest!.provider.resolve(config).completer,
        same(completer),
      );
      expect(harness.requestsFor(url), 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('offscreen hero ignores prior avatar-sized source success', (
    tester,
  ) async {
    useDevice(tester);
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    addTearDown(() => PicnicCachedNetworkImage.disableTimeoutForTest = false);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://test-cdn.example.com/artist/hero-1.png?q=80&w=1000';
    // The same raw artist image may already have loaded at w180 in a vote
    // portrait. That success must not admit this still-offscreen w1000 hero.
    rememberSuccessfullyLoadedImageUrlForTest('/artist/hero-1.png');
    await tester.runAsync(
      () => harness.respondPng(url, width: 800, height: 400),
    );
    final vote = _entries([1], imageBase: '/artist/hero').single.vote;
    await tester.pumpWidget(
      buildTestApp(
        // Built inside the vertical list's cache extent, one screen down.
        ListView(
          children: [
            const SizedBox(height: 844),
            SizedBox(height: 372, child: HomeFeaturedVoteCard(vote: vote)),
          ],
        ),
      ),
    );
    await decodeFrames(tester);

    expect(
      find.byType(PicnicCachedNetworkImage, skipOffstage: false),
      findsOneWidget,
    );
    expect(harness.requestsFor(url), 0);

    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(372);
    await decodeFrames(tester);

    expect(harness.requestsFor(url), 1);
    expect(
      tester
          .widgetList<RawImage>(find.byType(RawImage))
          .any((raw) => raw.image != null),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'carousel prepares only the next card and preserves vote across reorder',
    (tester) async {
      useDevice(tester);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      for (var i = 1; i <= 4; i++) {
        await tester.runAsync(
          () => harness.respondPng(
            'https://example.com/hero-$i.png',
            width: 800,
            height: 400,
          ),
        );
      }
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(width: 390, child: HomeFeaturedVoteCarousel()),
          extraOverrides: [
            asyncActiveFeaturedVotesProvider.overrideWith(
              _MutableFeaturedVotes.new,
            ),
          ],
        ),
      );
      await decodeFrames(tester);
      expect(harness.requestsFor('https://example.com/hero-1.png'), 1);
      expect(harness.requestsFor('https://example.com/hero-2.png'), 1);
      // The card after next is two swipes away; it waits for the next page.
      expect(harness.requestsFor('https://example.com/hero-3.png'), 0);
      expect(harness.requestsFor('https://example.com/hero-4.png'), 0);
      final initialHero = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage).first,
      );
      final boxWidth = tester
          .getSize(find.byType(PicnicCachedNetworkImage).first)
          .width;
      expect(initialHero.width, boxWidth);
      final heroContext = tester.element(
        find.byType(PicnicCachedNetworkImage).first,
      );
      final measuredRequest = PicnicImageRequest.resolve(
        context: heroContext,
        imageUrl: initialHero.imageUrl,
        width: boxWidth,
      );
      final heroConfig = createLocalImageConfiguration(heroContext);
      expect(
        await initialHero.imageRequest!.obtainKey(heroConfig),
        await measuredRequest.obtainKey(heroConfig),
      );

      var pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller!.jumpToPage(1);
      await tester.pump();
      await tester.pump();
      final card = tester
          .widgetList<HomeFeaturedVoteCard>(find.byType(HomeFeaturedVoteCard))
          .singleWhere((card) => card.vote.id == 2);
      final request = card.heroImageRequest!;
      final config = createLocalImageConfiguration(
        tester.element(find.byType(HomeFeaturedVoteCard).first),
      );
      final key = await request.obtainKey(config);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeFeaturedVoteCarousel)),
      );
      container.read(asyncActiveFeaturedVotesProvider.notifier).state =
          AsyncData(_entries([3, 1, 2, 4]));
      await tester.pump();
      await tester.pump();
      pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller!.page, 2);
      final preserved = tester
          .widgetList<HomeFeaturedVoteCard>(find.byType(HomeFeaturedVoteCard))
          .singleWhere((c) => c.vote.id == 2);
      expect(await preserved.heroImageRequest!.obtainKey(config), key);
      container.read(asyncActiveFeaturedVotesProvider.notifier).state =
          AsyncData(_entries([4]));
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      // A started prefetch outlives its scope; let it finish before the
      // harness closes, or it stays in the shared scheduler for later tests.
      await pumpUntil(tester, schedulerIdle, 'prefetch teardown');
    },
  );

  testWidgets(
    'first-party heroes share one large variant for prefetch and display',
    (tester) async {
      useDevice(tester);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      String large(int id) =>
          'https://test-cdn.example.com/artist/hero-$id.png?q=80&w=1000';
      for (var id = 1; id <= 4; id++) {
        await tester.runAsync(
          () => harness.respondPng(large(id), width: 800, height: 400),
        );
      }
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(width: 390, child: HomeFeaturedVoteCarousel()),
          extraOverrides: [
            asyncActiveFeaturedVotesProvider.overrideWith(
              _CdnFeaturedVotes.new,
            ),
          ],
        ),
      );
      await decodeFrames(tester);

      final hero = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage).first,
      );
      expect(hero.imageRequest!.url, large(1));
      // The next card is prefetched through the very URL the display uses.
      expect(
        [for (var id = 1; id <= 4; id++) harness.requestsFor(large(id))],
        [1, 1, 0, 0],
      );
      final context = tester.element(find.byType(HomeFeaturedVoteCard).first);
      final vote = _entries([2], imageBase: '/artist/hero').single.vote;
      expect(
        {
          for (final width in [180.0, 343.0, 700.0])
            HomeFeaturedVoteCard.imageRequestFor(context, vote, width)!.url,
        },
        {large(2)},
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpUntil(tester, schedulerIdle, 'prefetch teardown');
    },
  );

  testWidgets(
    'covered home drops the queued next card and restores it when shown',
    (tester) async {
      useDevice(tester);
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      PicnicCachedNetworkImage.disableTimeoutForTest = true;
      addTearDown(() => PicnicCachedNetworkImage.disableTimeoutForTest = false);
      final harness = await ImageTestHarness.create();
      // Real async lets held streams close even when an expectation fails.
      addTearDown(() => tester.runAsync(harness.dispose));
      await pumpUntil(tester, schedulerIdle);
      String large(int id) =>
          'https://test-cdn.example.com/artist/hero-$id.png?q=80&w=1000';
      const blockers = [
        'https://images.example.com/blocker-a.png',
        'https://images.example.com/blocker-b.png',
      ];
      await tester.runAsync(() async {
        for (var id = 1; id <= 3; id++) {
          await harness.respondPng(large(id), width: 800, height: 400);
        }
        for (final url in blockers) {
          await harness.respondPng(url, held: true);
        }
      });
      final votes = Completer<List<FeaturedVoteEntry>>();
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
                home: const HomeFeaturedVoteCarousel(),
              );
            },
          ),
          extraOverrides: [
            asyncActiveFeaturedVotesProvider.overrideWith(
              () => _PendingFeaturedVotes(votes.future),
            ),
          ],
        ),
      );
      // Another screen's prefetch holds both background slots, so the
      // carousel's next card has to wait in the queue.
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
      await pumpUntil(
        tester,
        () => blockers.every((url) => harness.requestsFor(url) == 1),
      );

      votes.complete(_entries([1, 2, 3], imageBase: '/artist/hero'));
      await pumpUntil(
        tester,
        () =>
            harness.requestsFor(large(1)) == 1 &&
            PicnicImagePrefetchScope.schedulerStateForTest.queued == 1,
      );
      expect(harness.requestsFor(large(2)), 0);

      // A pushed page covers home; home stays mounted under it.
      page.value = 1;
      await decodeFrames(tester);
      expect(PicnicImagePrefetchScope.schedulerStateForTest.queued, 0);

      for (final url in blockers) {
        harness.release(url);
      }
      await pumpUntil(tester, () => harness.activeRequests == 0);
      await decodeFrames(tester);
      expect(harness.requestsFor(large(2)), 0);

      page.value = 0;
      await pumpUntil(tester, () => harness.requestsFor(large(2)) == 1);
      await pumpUntil(tester, schedulerIdle);
      final next = tester
          .widgetList<HomeFeaturedVoteCard>(find.byType(HomeFeaturedVoteCard))
          .singleWhere((card) => card.vote.id == 2)
          .heroImageRequest!;
      expect(next.url, large(2));
      final nextKey = await next.obtainKey(
        createLocalImageConfiguration(
          tester.element(find.byType(HomeFeaturedVoteCarousel)),
        ),
      );
      expect(PaintingBinding.instance.imageCache.containsKey(nextKey), isTrue);

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await decodeFrames(tester);
      expect(harness.requestsFor(large(2)), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpUntil(tester, schedulerIdle);
    },
  );
}
