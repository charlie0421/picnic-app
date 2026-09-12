import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/image_test_harness.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

typedef _PageLoader = Future<List<VoteModel>> Function(int page, String area);

final class _ScriptedVoteList extends AsyncVoteList {
  _ScriptedVoteList(this.loader);

  final _PageLoader loader;

  @override
  Future<List<VoteModel>> build(
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  }) {
    return loader(page, area);
  }
}

VoteModel _vote(
  int id,
  List<({String url, int total})> images, {
  String voteCategory = 'birthday',
}) {
  return VoteFactory.create(
    id: id,
    voteCategory: voteCategory,
    voteItem: [
      for (var index = 0; index < images.length; index++)
        VoteItemFactory.create(
          id: id * 10 + index,
          voteId: id,
          voteTotal: images[index].total,
          artist: ArtistModel(
            id: id * 10 + index,
            name: {'ko': 'Artist $id-$index'},
            image: images[index].url,
          ),
        ),
    ],
  );
}

List<VoteModel> _pageWithNextCard(List<({String url, int total})> images) {
  return [
    _vote(1, const []),
    _vote(2, images),
    _vote(3, const []),
    _vote(4, const []),
  ];
}

Widget _app(
  _PageLoader loader, {
  String area = 'all',
  VoteStatus status = VoteStatus.active,
}) {
  return buildTestApp(
    VoteList(status, VoteCategory.all, area),
    extraOverrides: [
      asyncVoteListProvider.overrideWith(() => _ScriptedVoteList(loader)),
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
    'prepares the next active card top three and display reuses every key',
    (tester) async {
      tester.view.physicalSize = const Size(393, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = await ImageTestHarness.create();
      const low = 'https://images.example.com/vote-next-low.png';
      const high = 'https://images.example.com/vote-next-high.png';
      const middle = 'https://images.example.com/vote-next-middle.png';
      for (final url in [low, high, middle]) {
        await tester.runAsync(
          () => harness.respondPng(url, width: 400, height: 200, held: true),
        );
      }
      addTearDown(() {
        harness.release(low);
        harness.release(high);
        harness.release(middle);
        return harness.dispose();
      });
      final pageItems = _pageWithNextCard(const [
        (url: low, total: 10),
        (url: high, total: 30),
        (url: middle, total: 20),
      ]);

      await tester.pumpWidget(
        _app((page, _) async {
          if (page != 1) return const [];
          return pageItems;
        }),
      );
      await _pumpUntil(
        tester,
        () =>
            harness.requestsFor(high) == 1 && harness.requestsFor(middle) == 1,
      );

      expect(harness.activeRequests, 2);
      expect(harness.maximumActiveRequests, 2);
      expect(harness.requestsFor(low), 0);

      harness.release(high);
      await _pumpUntil(tester, () => harness.requestsFor(low) == 1);

      expect(harness.activeRequests, 2);
      expect(harness.maximumActiveRequests, 2);

      final listContext = tester.element(find.byType(VoteList));
      final preparedItems = VoteInfoCardHelper.previewItems(
        pageItems[1].voteItem,
        VoteStatus.active,
      );
      final configuration = createLocalImageConfiguration(listContext);
      final prepared =
          <String, ({Object key, ImageStreamCompleter? completer})>{};
      for (final item in preparedItems) {
        final request = VoteInfoCardHelper.rankImageRequest(listContext, item);
        prepared[request.imageUrl] = (
          key: await request.obtainKey(configuration),
          completer: request.provider.resolve(configuration).completer,
        );
        expect(prepared[request.imageUrl]!.completer, isNotNull);
      }

      harness.release(middle);
      harness.release(low);
      await _pumpUntil(tester, () => harness.activeRequests == 0);

      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller!.jumpToPage(1);
      await tester.pump();
      for (final url in [high, middle, low]) {
        await _pumpUntil(
          tester,
          () => _rawImageFor(tester, url)?.image != null,
        );
        final displayed = _imageWidget(tester, url);
        expect((displayed.width, displayed.height), (72, 72));
        expect(displayed.imageRequest, isNotNull);
        expect(
          await displayed.imageRequest!.obtainKey(configuration),
          prepared[url]!.key,
        );
        expect(
          displayed.imageRequest!.provider.resolve(configuration).completer,
          same(prepared[url]!.completer),
        );
        expect(harness.requestsFor(url), 1);
      }

      final decoded = _rawImageFor(tester, high)!.image!;
      expect(
        decoded.width,
        _imageWidget(tester, high).imageRequest!.decodeWidth,
      );
      expect(decoded.width / decoded.height, closeTo(2, 0.02));
      expect(await _centerRgba(tester, decoded), [255, 0, 0, 255]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('prepares only the single forward-adjacent card', (tester) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const adjacent = 'https://images.example.com/one-forward-adjacent.png';
    const farther = [
      'https://images.example.com/two-forward-a.png',
      'https://images.example.com/two-forward-b.png',
      'https://images.example.com/two-forward-c.png',
    ];
    for (final url in [adjacent, ...farther]) {
      await tester.runAsync(() => harness.respondPng(url));
    }
    final pageItems = [
      _vote(1, const []),
      _vote(2, const [(url: adjacent, total: 10)]),
      _vote(3, [
        for (var index = 0; index < farther.length; index++)
          (url: farther[index], total: farther.length - index),
      ]),
      _vote(4, const []),
    ];

    await tester.pumpWidget(
      _app((page, _) async => page == 1 ? pageItems : const []),
    );
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(adjacent) == 1 &&
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await _pumpAsyncWork(tester);

    expect(farther.where((url) => harness.requestsFor(url) > 0), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('outer list excludes upcoming and achieve card portraits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const upcoming = 'https://images.example.com/outer-upcoming.png';
    const achieve = 'https://images.example.com/outer-achieve.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(upcoming),
        harness.respondPng(achieve),
      ]),
    );

    await tester.pumpWidget(
      _app(
        (page, _) async => page == 1
            ? _pageWithNextCard(const [(url: upcoming, total: 10)])
            : const [],
        status: VoteStatus.upcoming,
      ),
    );
    await _pumpAsyncWork(tester);
    expect(harness.requestsFor(upcoming), 0);

    final achievePage = [
      _vote(1, const []),
      _vote(2, const [
        (url: achieve, total: 10),
      ], voteCategory: VoteCategory.achieve.name),
      _vote(3, const []),
      _vote(4, const []),
    ];
    await tester.pumpWidget(
      _app((page, _) async => page == 1 ? achievePage : const []),
    );
    await _pumpAsyncWork(tester);

    expect(harness.requestsFor(achieve), 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('input replacement clears stale queued work before it starts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await ImageTestHarness.create();
    const blockerA = 'https://images.example.com/list-blocker-a.png';
    const blockerB = 'https://images.example.com/list-blocker-b.png';
    const staleA = 'https://images.example.com/list-stale-a.png';
    const staleB = 'https://images.example.com/list-stale-b.png';
    for (final url in [blockerA, blockerB, staleA, staleB]) {
      await tester.runAsync(() => harness.respondPng(url, held: true));
    }
    addTearDown(() {
      harness.release(blockerA);
      harness.release(blockerB);
      harness.release(staleA);
      harness.release(staleB);
      return harness.dispose();
    });

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
    final blockers = PicnicImagePrefetchScope();
    addTearDown(blockers.dispose);
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
    var area = 'old';
    await tester.pumpWidget(
      buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return VoteList(VoteStatus.active, VoteCategory.all, area);
          },
        ),
        extraOverrides: [
          asyncVoteListProvider.overrideWith(
            () => _ScriptedVoteList((page, requestedArea) async {
              if (page != 1) return const [];
              if (requestedArea == 'new') return const [];
              return _pageWithNextCard(const [
                (url: staleA, total: 20),
                (url: staleB, total: 10),
              ]);
            }),
          ),
        ],
      ),
    );
    await _pumpAsyncWork(tester);
    expect(harness.requestsFor(staleA), 0);
    expect(harness.requestsFor(staleB), 0);

    updateHost(() => area = 'new');
    await tester.pump();
    await _pumpAsyncWork(tester);
    harness.release(blockerA);
    await _pumpUntil(tester, () => harness.activeRequests == 1);
    await _pumpAsyncWork(tester);

    expect(harness.requestsFor(staleA), 0);
    expect(harness.requestsFor(staleB), 0);

    await tester.pumpWidget(const SizedBox.shrink());
    harness.release(blockerB);
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await _pumpAsyncWork(tester);
    await tester.pump();
  });

  testWidgets('third-only image identity change replaces the queued request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await ImageTestHarness.create();
    const first = 'https://images.example.com/third-change-first.png';
    const second = 'https://images.example.com/third-change-second.png';
    const staleThird =
        'https://images.example.com/third-change-stale-third.png';
    const currentThird =
        'https://images.example.com/third-change-current-third.png';
    for (final url in [first, second, staleThird, currentThird]) {
      await tester.runAsync(() => harness.respondPng(url, held: true));
    }
    addTearDown(() {
      for (final url in [first, second, staleThird, currentThird]) {
        harness.release(url);
      }
      return harness.dispose();
    });
    final mutableItems = [
      for (final entry in const [
        (url: first, total: 30),
        (url: second, total: 20),
        (url: staleThird, total: 10),
      ])
        VoteItemFactory.create(
          id: 20 + entry.total,
          voteId: 2,
          voteTotal: entry.total,
          artist: ArtistModel(
            id: 20 + entry.total,
            name: {'ko': 'Artist ${entry.total}'},
            image: entry.url,
          ),
        ),
    ];
    final pageItems = [
      _vote(1, const []),
      VoteFactory.create(id: 2, voteItem: mutableItems),
      _vote(3, const []),
      _vote(4, const []),
    ];
    late StateSetter updateHost;
    var topPadding = 0.0;

    await tester.pumpWidget(
      buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: EdgeInsets.only(top: topPadding)),
              child: VoteList(VoteStatus.active, VoteCategory.all, 'all'),
            );
          },
        ),
        extraOverrides: [
          asyncVoteListProvider.overrideWith(
            () => _ScriptedVoteList(
              (page, _) async => page == 1 ? pageItems : const [],
            ),
          ),
        ],
      ),
    );
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(first) == 1 &&
          harness.requestsFor(second) == 1 &&
          harness.activeRequests == 2,
    );
    expect(harness.requestsFor(staleThird), 0);

    updateHost(() {
      mutableItems[2] = VoteItemFactory.create(
        id: 299,
        voteId: 2,
        voteTotal: 10,
        artist: const ArtistModel(
          id: 299,
          name: {'ko': 'Current third'},
          image: currentThird,
        ),
      );
      topPadding = 1;
    });
    await tester.pump();
    await tester.pump();

    harness.release(first);
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(staleThird) == 1 ||
          harness.requestsFor(currentThird) == 1,
    );
    harness.release(second);
    harness.release(staleThird);
    harness.release(currentThird);
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );

    expect(harness.requestsFor(staleThird), 0);
    expect(harness.requestsFor(currentThird), 1);
    expect(harness.maximumActiveRequests, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('same-DPR window resize reevaluates the prepared signature', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/list-resize.png';
    await tester.runAsync(
      () => harness.respondPng(url, width: 240, height: 120),
    );
    final pageItems = _pageWithNextCard(const [(url: url, total: 10)]);

    await tester.pumpWidget(
      _app((page, _) async => page == 1 ? pageItems : const []),
    );
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(url) == 1 &&
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await tester.pump();

    final listContext = tester.element(find.byType(VoteList));
    final request = VoteInfoCardHelper.rankImageRequest(
      listContext,
      pageItems[1].voteItem!.first,
    );
    final key = await request.obtainKey(
      createLocalImageConfiguration(listContext),
    );
    expect(
      PaintingBinding.instance.imageCache.evict(key, includeLive: true),
      isTrue,
    );
    await tester.runAsync(harness.emptyCache);

    tester.view.physicalSize = const Size(500, 892);
    await tester.pump();
    await _pumpUntil(tester, () => harness.requestsFor(url) == 2);

    expect(tester.view.devicePixelRatio, 1);
    expect(harness.requestsFor(url), 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
  return tester
      .widgetList<RawImage>(
        find.descendant(
          of: _imageFinder(url).first,
          matching: find.byType(RawImage),
          skipOffstage: false,
        ),
      )
      .where((candidate) => candidate.image != null)
      .firstOrNull;
}

Future<List<int>> _centerRgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (bytes == null) fail('Decoded rank image did not expose RGBA bytes.');
  final center = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      bytes.getUint8(center + channel),
  ];
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  for (var step = 0; step < 8; step++) {
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
