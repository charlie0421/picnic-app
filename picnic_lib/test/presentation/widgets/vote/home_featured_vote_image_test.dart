import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/image_test_harness.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _MutableFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() async => _entries([1, 2, 3, 4]);
}

List<FeaturedVoteEntry> _entries(List<int> ids) => [
  for (final id in ids)
    FeaturedVoteEntry(
      vote: VoteFactory.create(
        id: id,
        voteItem: [
          VoteItemFactory.create(
            id: id,
            artist: ArtistFactory.create(
              id: id,
              image: 'https://example.com/hero-$id.png',
            ),
          ),
        ],
      ),
      totalVotes: 100,
    ),
];

void main() {
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

  testWidgets(
    'hero starts immediately and keeps its decode when height changes',
    (tester) async {
      useDevice(tester);
      final interval = VisibilityDetectorController.instance.updateInterval;
      VisibilityDetectorController.instance.updateInterval = const Duration(
        milliseconds: 500,
      );
      addTearDown(() {
        VisibilityDetectorController.instance.updateInterval = interval;
      });
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
      expect(first.lazyLoadingStrategy, LazyLoadingStrategy.none);
      expect(first.imageRequest, isNotNull);
      expect(first.imageRequest!.requestHeight, isNull);
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

  testWidgets(
    'carousel prepares only neighbors and preserves vote across reorder',
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
      expect(harness.requestsFor('https://example.com/hero-3.png'), 1);
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
      await tester.pump();
    },
  );
}
