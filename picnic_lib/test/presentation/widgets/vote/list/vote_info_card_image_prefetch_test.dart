import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/image_test_harness.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

VoteModel _upcomingVote(List<String> urls) {
  final now = DateTime.now();
  return VoteFactory.create(
    id: 77,
    isUpcoming: true,
    startAt: now.add(const Duration(days: 1)),
    stopAt: now.add(const Duration(days: 8)),
    voteItem: [
      for (var index = 0; index < urls.length; index++)
        VoteItemFactory.create(
          id: index + 1,
          voteId: 77,
          voteTotal: urls.length - index,
          artist: ArtistModel(
            id: index + 1,
            name: {'ko': 'Artist $index'},
            image: urls[index],
          ),
        ),
    ],
  );
}

void main() {
  late Duration previousVisibilityInterval;

  setUp(() {
    initTestColors();
    previousVisibilityInterval =
        VisibilityDetectorController.instance.updateInterval;
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval =
        previousVisibilityInterval;
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'upcoming card prepares the next internal page first two without wrap',
    (tester) async {
      tester.view.physicalSize = const Size(393, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final harness = await ImageTestHarness.create();
      final urls = [
        for (var index = 0; index < 24; index++)
          'https://images.example.com/upcoming-$index.png',
      ];
      try {
        for (final url in urls) {
          await tester.runAsync(
            () => harness.respondPng(url, width: 240, height: 120, held: true),
          );
        }
        final vote = _upcomingVote(urls);

        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => VoteInfoCard(
                context: context,
                vote: vote,
                status: VoteStatus.upcoming,
              ),
            ),
          ),
        );
        await tester.pump();
        final currentPageUrls = find
            .byType(PicnicCachedNetworkImage)
            .hitTestable()
            .evaluate()
            .map(
              (element) =>
                  (element.widget as PicnicCachedNetworkImage).imageUrl,
            )
            .toSet();
        expect(currentPageUrls, hasLength(12));
        await _pumpUntil(
          tester,
          () =>
              urls
                  .where(
                    (url) =>
                        !currentPageUrls.contains(url) &&
                        harness.requestsFor(url) == 1,
                  )
                  .length ==
              2,
        );

        final preparedUrls = urls
            .where(
              (url) =>
                  !currentPageUrls.contains(url) &&
                  harness.requestsFor(url) == 1,
            )
            .toSet();
        expect(preparedUrls, hasLength(2));
        final prepared =
            <String, ({Object key, ImageStreamCompleter? completer})>{};
        final cardContext = tester.element(find.byType(VoteInfoCard));
        for (final url in preparedUrls) {
          final item = vote.voteItem!.singleWhere(
            (candidate) =>
                VoteInfoCardHelper.resolveVoteItemImageUrl(candidate) == url,
          );
          final request = VoteInfoCardHelper.thumbnailImageRequest(
            cardContext,
            item,
          );
          final configuration = createLocalImageConfiguration(cardContext);
          prepared[url] = (
            key: await request.obtainKey(configuration),
            completer: request.provider.resolve(configuration).completer,
          );
          expect(prepared[url]!.completer, isNotNull);
          harness.release(url);
        }
        for (final url in currentPageUrls) {
          harness.release(url);
        }
        await _pumpUntil(tester, () => harness.activeRequests == 0);

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('2/2'), findsOneWidget);

        final visibleImages = find
            .byType(PicnicCachedNetworkImage)
            .hitTestable()
            .evaluate()
            .map(
              (element) =>
                  (element.widget as PicnicCachedNetworkImage).imageUrl,
            )
            .toList();
        expect(visibleImages, hasLength(12));
        expect(visibleImages.take(2).toSet(), preparedUrls);

        for (final url in preparedUrls) {
          await _pumpUntil(
            tester,
            () => _rawImageFor(tester, url)?.image != null,
          );
          final image = _imageWidget(tester, url);
          final configuration = createLocalImageConfiguration(
            tester.element(_imageFinder(url).first),
          );
          expect(
            await image.imageRequest!.obtainKey(configuration),
            prepared[url]!.key,
          );
          expect(
            image.imageRequest!.provider.resolve(configuration).completer,
            same(prepared[url]!.completer),
          );
          expect(harness.requestsFor(url), 1);
        }

        final decoded = _rawImageFor(tester, preparedUrls.first)!.image!;
        expect(decoded.width / decoded.height, closeTo(2, 0.04));
        expect(await _centerRgba(tester, decoded), [255, 0, 0, 255]);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      } finally {
        for (final url in urls) {
          harness.release(url);
        }
        await _pumpUntil(tester, () => harness.activeRequests == 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpAsyncWork(tester);
        await harness.dispose();
      }
    },
  );

  testWidgets('single upcoming page requests only its 12 visible images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final harness = await ImageTestHarness.create();
    final urls = [
      for (var index = 0; index < 12; index++)
        'https://images.example.com/upcoming-single-$index.png',
    ];
    for (final url in urls) {
      await tester.runAsync(() => harness.respondPng(url, held: true));
    }
    try {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => VoteInfoCard(
              context: context,
              vote: _upcomingVote(urls),
              status: VoteStatus.upcoming,
            ),
          ),
        ),
      );
      await _pumpUntil(tester, () => harness.activeRequests == 12);

      expect(urls.every((url) => harness.requestsFor(url) == 1), isTrue);
      expect(harness.maximumActiveRequests, 12);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      for (final url in urls) {
        harness.release(url);
      }
      await _pumpUntil(tester, () => harness.activeRequests == 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpAsyncWork(tester);
      await harness.dispose();
    }
  });

  testWidgets('stale upcoming page work is cleared before a slot opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final harness = await ImageTestHarness.create();
    const blockerA = 'https://images.example.com/upcoming-blocker-a.png';
    const blockerB = 'https://images.example.com/upcoming-blocker-b.png';
    final oldUrls = [
      for (var index = 0; index < 24; index++)
        'https://images.example.com/upcoming-stale-$index.png',
    ];
    final newUrls = [
      for (var index = 0; index < 12; index++)
        'https://images.example.com/upcoming-current-$index.png',
    ];
    final allUrls = [blockerA, blockerB, ...oldUrls, ...newUrls];
    for (final url in allUrls) {
      await tester.runAsync(
        () => harness.respondPng(url, width: 4, height: 2, held: true),
      );
    }
    final blockers = PicnicImagePrefetchScope();
    try {
      late BuildContext blockerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              blockerContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      blockers.replace(blockerContext, [
        PicnicImageRequest.resolve(
          context: blockerContext,
          imageUrl: blockerA,
          width: 20,
          height: 20,
        ),
        PicnicImageRequest.resolve(
          context: blockerContext,
          imageUrl: blockerB,
          width: 20,
          height: 20,
        ),
      ]);
      await _pumpUntil(tester, () => harness.activeRequests == 2);

      late StateSetter updateHost;
      var vote = _upcomingVote(oldUrls);
      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return VoteInfoCard(
                context: context,
                vote: vote,
                status: VoteStatus.upcoming,
              );
            },
          ),
        ),
      );
      await tester.pump();
      final oldVisibleUrls = find
          .byType(PicnicCachedNetworkImage)
          .hitTestable()
          .evaluate()
          .map(
            (element) => (element.widget as PicnicCachedNetworkImage).imageUrl,
          )
          .toSet();
      expect(oldVisibleUrls, hasLength(12));
      await _pumpUntil(
        tester,
        () => oldVisibleUrls.every((url) => harness.requestsFor(url) == 1),
      );
      for (final url in oldVisibleUrls) {
        harness.release(url);
      }
      await _pumpUntil(tester, () => harness.activeRequests == 2);

      updateHost(() => vote = _upcomingVote(newUrls));
      await tester.pump();
      final newVisibleUrls = find
          .byType(PicnicCachedNetworkImage)
          .hitTestable()
          .evaluate()
          .map(
            (element) => (element.widget as PicnicCachedNetworkImage).imageUrl,
          )
          .toSet();
      expect(newVisibleUrls, hasLength(12));
      await _pumpUntil(
        tester,
        () => newVisibleUrls.every((url) => harness.requestsFor(url) == 1),
      );
      for (final url in newVisibleUrls) {
        harness.release(url);
      }
      await _pumpUntil(tester, () => harness.activeRequests == 2);

      harness.release(blockerA);
      await _pumpUntil(tester, () => harness.activeRequests == 1);
      await _pumpAsyncWork(tester);

      final staleSpeculativeUrls = oldUrls.where(
        (url) => !oldVisibleUrls.contains(url),
      );
      expect(
        staleSpeculativeUrls.where((url) => harness.requestsFor(url) > 0),
        isEmpty,
      );
      expect(
        newVisibleUrls.every((url) => harness.requestsFor(url) == 1),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      harness.release(blockerB);
      await _pumpUntil(tester, () => harness.activeRequests == 0);
      await _pumpAsyncWork(tester);
    } finally {
      for (final url in allUrls) {
        harness.release(url);
      }
      blockers.dispose();
      await _pumpUntil(tester, () => harness.activeRequests == 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpAsyncWork(tester);
      await harness.dispose();
    }
  });
}

Finder _imageFinder(String url) => find.byWidgetPredicate(
  (widget) => widget is PicnicCachedNetworkImage && widget.imageUrl == url,
  skipOffstage: false,
);

PicnicCachedNetworkImage _imageWidget(WidgetTester tester, String url) {
  return tester.widget<PicnicCachedNetworkImage>(_imageFinder(url).first);
}

RawImage? _rawImageFor(WidgetTester tester, String url) {
  final images = tester
      .widgetList<RawImage>(
        find.descendant(
          of: _imageFinder(url).first,
          matching: find.byType(RawImage),
          skipOffstage: false,
        ),
      )
      .where((candidate) => candidate.image != null);
  return images.isEmpty ? null : images.first;
}

Future<List<int>> _centerRgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (bytes == null) fail('Decoded thumbnail did not expose RGBA bytes.');
  final center = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      bytes.getUint8(center + channel),
  ];
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  for (var step = 0; step < 10; step++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump();
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump();
  }
  fail('Condition was not reached after asynchronous image work completed.');
}
