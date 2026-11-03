import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/image_shimmer_loading.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(initTestColors);

  testWidgets('default cold visible image requests and paints before 100ms', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-cold-default.png';
      const expectedColor = Color(0xffff0000);
      final boundaryKey = GlobalKey();
      await tester.runAsync(
        () => harness.respondPng(
          url,
          width: 32,
          height: 32,
          color: expectedColor,
        ),
      );
      expect(await harness.getFileFromCache(url), isNull);
      expect(harness.requestsFor(url), 0);
      expect(successfullyLoadedImageUrlsContainsForTest(url), isFalse);

      final startedAt = tester.binding.clock.now();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: boundaryKey,
            child: const PicnicCachedNetworkImage(
              imageUrl: url,
              width: 32,
              height: 32,
              memCacheWidth: 32,
              memCacheHeight: 32,
            ),
          ),
        ),
      );

      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
      }

      expect(harness.requestsFor(url), 1);
      await _pumpUntilDecoded(tester);
      expect(find.byType(ShimmerLoading), findsNothing);
      expect(await _paintedCenterRgba(tester, boundaryKey), [255, 0, 0, 255]);
      expect(
        tester.binding.clock.now().difference(startedAt),
        lessThan(const Duration(milliseconds: 100)),
      );
      expect(harness.requestsFor(url), 1);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('explicit viewport low priority ignores a 600ms initial delay', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-low-delay.png';
      await tester.runAsync(
        () => harness.respondPng(
          url,
          width: 32,
          height: 32,
          color: const Color(0xff00ff00),
        ),
      );
      final boundaryKey = GlobalKey();
      final startedAt = tester.binding.clock.now();

      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: boundaryKey,
            child: const PicnicCachedNetworkImage(
              imageUrl: url,
              width: 32,
              height: 32,
              memCacheWidth: 32,
              memCacheHeight: 32,
              lazyLoadingStrategy: LazyLoadingStrategy.viewport,
              priority: ImagePriority.low,
              lazyLoadDelay: Duration(milliseconds: 600),
            ),
          ),
        ),
      );

      for (var frame = 0; frame < 3; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
      }

      expect(harness.requestsFor(url), 1);
      await _pumpUntilDecoded(tester);
      expect(await _paintedCenterRgba(tester, boundaryKey), [0, 255, 0, 255]);
      expect(
        tester.binding.clock.now().difference(startedAt),
        lessThan(const Duration(milliseconds: 100)),
      );
      expect(harness.requestsFor(url), 1);
    });
  });

  testWidgets(
    'preload and progressive use the same post-frame visibility gate',
    (tester) async {
      await _withImageHarness(tester, (harness) async {
        const cases = [
          (
            LazyLoadingStrategy.preload,
            'https://images.example.com/display-wait-preload.png',
          ),
          (
            LazyLoadingStrategy.progressive,
            'https://images.example.com/display-wait-progressive.png',
          ),
        ];

        for (final (strategy, url) in cases) {
          await tester.runAsync(
            () => harness.respondPng(url, width: 32, height: 32),
          );
          VisibilityDetectorController.instance.updateInterval = const Duration(
            milliseconds: 500,
          );
          final startedAt = tester.binding.clock.now();
          await tester.pumpWidget(
            _app(
              SizedBox.square(
                dimension: 32,
                child: PicnicCachedNetworkImage(
                  imageUrl: url,
                  width: 32,
                  height: 32,
                  memCacheWidth: 32,
                  memCacheHeight: 32,
                  lazyLoadingStrategy: strategy,
                ),
              ),
            ),
          );

          await _pumpVisibleDeadline(tester);
          expect(harness.requestsFor(url), 1, reason: strategy.name);
          await _pumpUntilDecoded(tester);
          expect(
            tester.binding.clock.now().difference(startedAt),
            lessThan(const Duration(milliseconds: 100)),
            reason: strategy.name,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    },
  );

  testWidgets('built offscreen image waits until it enters the viewport', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-offscreen.png';
      final boundaryKey = GlobalKey();
      final scrollController = ScrollController();
      try {
        await tester.runAsync(
          () => harness.respondPng(
            url,
            width: 32,
            height: 32,
            color: const Color(0xff0000ff),
          ),
        );
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 100,
              height: 100,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 400),
                    RepaintBoundary(
                      key: boundaryKey,
                      child: const PicnicCachedNetworkImage(
                        imageUrl: url,
                        width: 32,
                        height: 32,
                        memCacheWidth: 32,
                        memCacheHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(harness.requestsFor(url), 0);
        expect(find.byType(Image), findsNothing);

        final startedAt = tester.binding.clock.now();
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await _pumpVisibleDeadline(tester);
        expect(harness.requestsFor(url), 1);
        await _pumpUntilDecoded(tester);
        expect(await _paintedCenterRgba(tester, boundaryKey), [0, 0, 255, 255]);
        expect(
          tester.binding.clock.now().difference(startedAt),
          lessThan(const Duration(milliseconds: 100)),
        );
      } finally {
        scrollController.dispose();
      }
    });
  });

  testWidgets('default spatial threshold rejects 5% and accepts 11%', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-threshold.png';
      final top = ValueNotifier<double>(95);
      try {
        await tester.runAsync(
          () => harness.respondPng(url, width: 100, height: 100),
        );
        await tester.pumpWidget(
          _app(
            SizedBox.square(
              dimension: 100,
              child: ClipRect(
                child: ValueListenableBuilder<double>(
                  valueListenable: top,
                  builder: (context, offset, _) => Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        top: offset,
                        left: 0,
                        width: 100,
                        height: 100,
                        child: const PicnicCachedNetworkImage(
                          imageUrl: url,
                          width: 100,
                          height: 100,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));
        expect(harness.requestsFor(url), 0);

        top.value = 89;
        await _pumpVisibleDeadline(tester);
        expect(harness.requestsFor(url), 1);
        await _pumpUntilDecoded(tester);
      } finally {
        top.dispose();
      }
    });
  });

  testWidgets('offstage image starts only after becoming visible', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-offstage.png';
      final hidden = ValueNotifier<bool>(true);
      try {
        await tester.runAsync(
          () => harness.respondPng(url, width: 32, height: 32),
        );
        await tester.pumpWidget(
          _app(
            ValueListenableBuilder<bool>(
              valueListenable: hidden,
              builder: (context, isHidden, _) => Offstage(
                offstage: isHidden,
                child: const PicnicCachedNetworkImage(
                  imageUrl: url,
                  width: 32,
                  height: 32,
                  memCacheWidth: 32,
                  memCacheHeight: 32,
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));
        expect(harness.requestsFor(url), 0);

        hidden.value = false;
        await _pumpVisibleDeadline(tester);
        expect(harness.requestsFor(url), 1);
        await _pumpUntilDecoded(tester);
      } finally {
        hidden.dispose();
      }
    });
  });

  testWidgets('same URL siblings receive independent visibility callbacks', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-same-url.png';
      const firstKey = ValueKey('same-url-first');
      const secondKey = ValueKey('same-url-second');
      await tester.runAsync(
        () => harness.respondPng(url, width: 32, height: 32),
      );

      await tester.pumpWidget(
        _app(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                key: firstKey,
                dimension: 32,
                child: PicnicCachedNetworkImage(
                  imageUrl: url,
                  width: 32,
                  height: 32,
                  memCacheWidth: 32,
                  memCacheHeight: 32,
                ),
              ),
              SizedBox.square(
                key: secondKey,
                dimension: 32,
                child: PicnicCachedNetworkImage(
                  imageUrl: url,
                  width: 32,
                  height: 32,
                  memCacheWidth: 32,
                  memCacheHeight: 32,
                ),
              ),
            ],
          ),
        ),
      );

      await _pumpVisibleDeadline(tester);
      expect(harness.requestsFor(url), 1);
      await _pumpUntil(
        tester,
        () =>
            _decodedCountUnder(tester, find.byKey(firstKey)) == 1 &&
            _decodedCountUnder(tester, find.byKey(secondKey)) == 1,
      );
      expect(harness.requestsFor(url), 1);
    });
  });

  testWidgets(
    'cold scroll deferral delays request and timeout for both bool values',
    (tester) async {
      await _withImageHarness(tester, (harness) async {
        final physics = _ToggleDeferredPhysics()..deferred.value = true;
        try {
          PicnicCachedNetworkImage.disableTimeoutForTest = false;
          for (final deferDuringFastScroll in [false, true]) {
            final url =
                'https://images.example.com/display-wait-scroll-$deferDuringFastScroll.png';
            await tester.runAsync(
              () => harness.respondPng(url, width: 32, height: 32, held: true),
            );
            try {
              final image = deferDuringFastScroll
                  ? PicnicCachedNetworkImage(
                      imageUrl: url,
                      width: 32,
                      height: 32,
                      memCacheWidth: 32,
                      memCacheHeight: 32,
                      lazyLoadingStrategy: LazyLoadingStrategy.viewport,
                      deferDuringFastScroll: true,
                      timeout: const Duration(milliseconds: 50),
                      maxRetries: 0,
                    )
                  : PicnicCachedNetworkImage(
                      imageUrl: url,
                      width: 32,
                      height: 32,
                      memCacheWidth: 32,
                      memCacheHeight: 32,
                      deferDuringFastScroll: false,
                      timeout: const Duration(milliseconds: 50),
                      maxRetries: 0,
                    );
              await tester.pumpWidget(_scrollApp(physics, image));
              await tester.pump(const Duration(milliseconds: 600));

              expect(
                harness.requestsFor(url),
                0,
                reason: 'deferDuringFastScroll=$deferDuringFastScroll',
              );
              expect(lastTimeoutLogTimesContainsForTest(url), isFalse);

              final startedAt = tester.binding.clock.now();
              physics.deferred.value = false;
              await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
              expect(
                tester.binding.clock.now().difference(startedAt),
                lessThan(const Duration(milliseconds: 100)),
              );
              await tester.pump(const Duration(milliseconds: 60));
              expect(lastTimeoutLogTimesContainsForTest(url), isTrue);

              harness.release(url);
              await _pumpUntilDecoded(tester);
              expect(harness.requestsFor(url), 1);
            } finally {
              harness.release(url);
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
              physics.deferred.value = true;
            }
          }
        } finally {
          physics.deferred.dispose();
        }
      });
    },
  );

  testWidgets('pending and warm images survive deferred-scroll rebuilds', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const url = 'https://images.example.com/display-wait-pending-warm.png';
      final physics = _ToggleDeferredPhysics();
      try {
        await tester.runAsync(
          () => harness.respondPng(url, width: 32, height: 32, held: true),
        );
        try {
          await tester.pumpWidget(
            _scrollApp(
              physics,
              const PicnicCachedNetworkImage(
                imageUrl: url,
                width: 32,
                height: 32,
                memCacheWidth: 32,
                memCacheHeight: 32,
              ),
            ),
          );
          await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
          expect(find.byType(Image), findsOneWidget);

          physics.deferred.value = true;
          await tester.pumpWidget(
            _scrollApp(
              physics,
              const PicnicCachedNetworkImage(
                imageUrl: url,
                width: 32,
                height: 32,
                memCacheWidth: 32,
                memCacheHeight: 32,
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(Image), findsOneWidget);
          expect(harness.requestsFor(url), 1);

          harness.release(url);
          await _pumpUntilDecoded(tester);
          final pendingCompletion = _decodedImage(tester);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.pumpWidget(
            _scrollApp(
              physics,
              const PicnicCachedNetworkImage(
                imageUrl: url,
                width: 32,
                height: 32,
                memCacheWidth: 32,
                memCacheHeight: 32,
              ),
            ),
          );
          await _pumpUntilDecoded(tester);

          expect(_decodedImage(tester).isCloneOf(pendingCompletion), isTrue);
          expect(harness.requestsFor(url), 1);
        } finally {
          harness.release(url);
        }
      } finally {
        physics.deferred.dispose();
      }
    });
  });

  testWidgets('two background jobs do not gate a visible foreground image', (
    tester,
  ) async {
    await _withImageHarness(tester, (harness) async {
      const backgroundA =
          'https://images.example.com/display-wait-background-a.png';
      const backgroundB =
          'https://images.example.com/display-wait-background-b.png';
      const queuedBackground =
          'https://images.example.com/display-wait-background-queued.png';
      const foreground =
          'https://images.example.com/display-wait-foreground.png';
      const heldUrls = [backgroundA, backgroundB, queuedBackground, foreground];
      await tester.runAsync(
        () => Future.wait([
          for (final url in heldUrls)
            harness.respondPng(url, width: 32, height: 32, held: true),
        ]),
      );

      late BuildContext hostContext;
      final showForeground = ValueNotifier<bool>(false);
      final scope = PicnicImagePrefetchScope(maximumCandidates: 3);
      try {
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                hostContext = context;
                return ValueListenableBuilder<bool>(
                  valueListenable: showForeground,
                  builder: (context, show, _) => show
                      ? const PicnicCachedNetworkImage(
                          imageUrl: foreground,
                          width: 32,
                          height: 32,
                          memCacheWidth: 32,
                          memCacheHeight: 32,
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),
        );
        scope.replace(hostContext, [
          _request(hostContext, backgroundA),
          _request(hostContext, backgroundB),
          _request(hostContext, queuedBackground),
        ]);
        await _pumpUntil(
          tester,
          () =>
              harness.requestsFor(backgroundA) == 1 &&
              harness.requestsFor(backgroundB) == 1 &&
              harness.activeRequests == 2,
        );
        expect(harness.requestsFor(queuedBackground), 0);

        final startedAt = tester.binding.clock.now();
        showForeground.value = true;
        await _pumpVisibleDeadline(tester);

        expect(harness.requestsFor(foreground), 1);
        expect(harness.activeRequests, 3);
        expect(harness.maximumActiveRequests, 3);
        expect(harness.requestsFor(queuedBackground), 0);
        expect(
          tester.binding.clock.now().difference(startedAt),
          lessThan(const Duration(milliseconds: 100)),
        );
      } finally {
        scope.dispose();
        for (final url in heldUrls) {
          harness.release(url);
        }
        await _pumpUntil(
          tester,
          () =>
              harness.activeRequests == 0 &&
              PaintingBinding.instance.imageCache.pendingImageCount == 0,
        );
        showForeground.dispose();
      }
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(393, 852), devicePixelRatio: 1),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _scrollApp(_ToggleDeferredPhysics physics, Widget child) {
  return _app(
    ListView(
      physics: physics,
      children: [SizedBox(height: 120, child: Center(child: child))],
    ),
  );
}

PicnicImageRequest _request(BuildContext context, String url) {
  return PicnicImageRequest.resolve(
    context: context,
    imageUrl: url,
    width: 32,
    height: 32,
    memCacheWidth: 32,
    memCacheHeight: 32,
  );
}

Future<void> _withImageHarness(
  WidgetTester tester,
  Future<void> Function(ImageTestHarness harness) body,
) async {
  final controller = VisibilityDetectorController.instance;
  final previousInterval = controller.updateInterval;
  final previousTimeoutFlag = PicnicCachedNetworkImage.disableTimeoutForTest;
  final harness = await ImageTestHarness.create();
  try {
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    controller.updateInterval = const Duration(milliseconds: 500);
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    await body(harness);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.notifyNow();
    controller.updateInterval = previousInterval;
    PicnicCachedNetworkImage.disableTimeoutForTest = previousTimeoutFlag;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    await harness.dispose();
  }
}

Future<void> _pumpUntilDecoded(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () => tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((candidate) => candidate.image != null),
  );
}

Future<void> _pumpVisibleDeadline(WidgetTester tester) async {
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
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
  fail('Condition was not reached after asynchronous fixture work completed.');
}

int _decodedCountUnder(WidgetTester tester, Finder ancestor) => tester
    .widgetList<RawImage>(
      find.descendant(of: ancestor, matching: find.byType(RawImage)),
    )
    .where((candidate) => candidate.image != null)
    .length;

ui.Image _decodedImage(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .singleWhere((candidate) => candidate.image != null)
    .image!;

Future<List<int>> _paintedCenterRgba(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  await tester.pump();
  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final painted = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  if (painted == null) fail('RepaintBoundary did not produce an image.');
  try {
    final bytes = await tester.runAsync(
      () => painted.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) fail('Painted image did not expose RGBA bytes.');
    final offset =
        ((painted.height ~/ 2) * painted.width + painted.width ~/ 2) * 4;
    return [
      for (var channel = 0; channel < 4; channel++)
        bytes.getUint8(offset + channel),
    ];
  } finally {
    painted.dispose();
  }
}

final class _ToggleDeferredPhysics extends AlwaysScrollableScrollPhysics {
  _ToggleDeferredPhysics() : deferred = ValueNotifier(false);

  final ValueNotifier<bool> deferred;

  const _ToggleDeferredPhysics._(this.deferred, {super.parent});

  @override
  _ToggleDeferredPhysics applyTo(ScrollPhysics? ancestor) {
    return _ToggleDeferredPhysics._(deferred, parent: buildParent(ancestor));
  }

  @override
  bool recommendDeferredLoading(
    double velocity,
    ScrollMetrics metrics,
    BuildContext context,
  ) => deferred.value;
}
