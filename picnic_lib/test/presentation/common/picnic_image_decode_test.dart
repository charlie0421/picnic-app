import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(initTestColors);

  setUp(() {
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'prefetch and display share one provider key, completer, decode, and fetch',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const url = 'https://images.example.com/shared-red.png';
      await tester.runAsync(
        () => harness.respondPng(
          url,
          width: 160,
          height: 80,
          color: const Color(0xffff0000),
        ),
      );
      final context = await _pumpContext(tester);
      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: url,
        width: 80,
        height: 80,
        memCacheWidth: 80,
        memCacheHeight: 80,
      );
      final configuration = createLocalImageConfiguration(context);
      final preparedKey = await request.obtainKey(configuration);

      await tester.runAsync(() => precacheImage(request.provider, context));
      await tester.pump();
      final preparedCompleter = request.provider
          .resolve(configuration)
          .completer;

      await tester.pumpWidget(
        _app(
          SizedBox.square(
            dimension: 80,
            child: PicnicCachedNetworkImage(
              imageUrl: url,
              imageRequest: request,
              fit: BoxFit.cover,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
        ),
      );
      await _pumpUntilRawImage(tester);

      final displayed = _displayImage(tester);
      expect(displayed.image, same(request.provider));
      expect(await displayed.image.obtainKey(configuration), preparedKey);
      expect(
        displayed.image.resolve(configuration).completer,
        same(preparedCompleter),
      );
      expect(harness.requestsFor(request.url), 1);

      final decoded = _decodedImage(tester);
      expect((decoded.width, decoded.height), (80, 40));
      expect(decoded.width / decoded.height, closeTo(2, 0.02));
      expect(await _centerRgba(tester, decoded), [255, 0, 0, 255]);
      expect(PaintingBinding.instance.imageCache.currentSize, 1);

      for (var pump = 0; pump < 5; pump++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(
        _app(
          SizedBox.square(
            dimension: 80,
            child: PicnicCachedNetworkImage(
              imageUrl: url,
              imageRequest: request,
              fit: BoxFit.cover,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_displayImage(tester).image, same(request.provider));
      expect(harness.requestsFor(request.url), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'default viewport consumes an exact prefetched key in two frames',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const url = 'https://images.example.com/viewport-prefetched.png';
      await tester.runAsync(
        () => harness.respondPng(url, width: 160, height: 80),
      );
      final context = await _pumpContext(tester);
      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: url,
        width: 80,
        height: 40,
        memCacheWidth: 80,
        memCacheHeight: 40,
      );
      final configuration = createLocalImageConfiguration(context);
      await tester.runAsync(() => precacheImage(request.provider, context));
      await tester.pump();
      final prefetchedCompleter = request.provider
          .resolve(configuration)
          .completer;
      resetSuccessfullyLoadedImageUrlsForTest();

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 80,
            height: 40,
            child: PicnicCachedNetworkImage(
              imageUrl: url,
              imageRequest: request,
              showLoadingOverlay: false,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);

      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      await tester.pump();
      expect(_decodedImage(tester), isNotNull);
      expect(_displayImage(tester).image, same(request.provider));
      expect(
        _displayImage(tester).image.resolve(configuration).completer,
        same(prefetchedCompleter),
      );
      expect(harness.requestsFor(url), 1);
    },
  );

  testWidgets('implicit decode dimensions track DPR and bounded layout', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const expectations = <(double, int, int)>[
      (1, 96, 48),
      (2, 192, 96),
      (3, 200, 100),
    ];

    for (final (dpr, expectedWidth, expectedHeight) in expectations) {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 80,
            height: 40,
            child: PicnicCachedNetworkImage(
              imageUrl: 'https://test-cdn.example.com/inferred.png',
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
          devicePixelRatio: dpr,
        ),
      );
      await tester.pump();

      final resize = _displayImage(tester).image as ResizeImage;
      expect(resize.width, expectedWidth, reason: 'DPR $dpr width');
      expect(resize.height, expectedHeight, reason: 'DPR $dpr height');
      final query = Uri.parse(_networkProvider(resize).url).queryParameters;
      expect(query['w'], '$expectedWidth');
      expect(query['h'], '$expectedHeight');
    }
  });

  testWidgets(
    'explicit memory pixels stay fixed while single-axis requests stay single',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 72,
            height: 72,
            child: PicnicCachedNetworkImage(
              imageUrl: 'https://test-cdn.example.com/explicit.png',
              width: 72,
              height: 72,
              memCacheWidth: 78,
              memCacheHeight: 78,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
          devicePixelRatio: 3,
        ),
      );
      await tester.pump();
      var resize = _displayImage(tester).image as ResizeImage;
      expect((resize.width, resize.height), (78, 78));

      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 80,
            height: 40,
            child: PicnicCachedNetworkImage(
              imageUrl: 'https://test-cdn.example.com/width-only.png',
              width: 80,
              fit: BoxFit.cover,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
        ),
      );
      await tester.pump();
      resize = _displayImage(tester).image as ResizeImage;
      var query = Uri.parse(_networkProvider(resize).url).queryParameters;
      expect(query['w'], '96');
      expect(query, isNot(contains('h')));
      expect((resize.width, resize.height), (96, 2000));

      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 80,
            height: 40,
            child: PicnicCachedNetworkImage(
              imageUrl: 'https://test-cdn.example.com/contain.png',
              fit: BoxFit.contain,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
        ),
      );
      await tester.pump();
      resize = _displayImage(tester).image as ResizeImage;
      query = Uri.parse(_networkProvider(resize).url).queryParameters;
      expect(query['w'], '96');
      expect(query, isNot(contains('h')));
    },
  );

  testWidgets('provided request survives layout-only height changes', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/frozen-request.png';
    await tester.runAsync(() => harness.respondPng(url, held: true));
    addTearDown(() => harness.release(url));
    final context = await _pumpContext(tester);
    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: url,
      width: 120,
    );
    final configuration = createLocalImageConfiguration(context);
    final height = ValueNotifier<double>(40);
    addTearDown(height.dispose);

    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<double>(
          valueListenable: height,
          builder: (context, value, _) => SizedBox(
            width: 120,
            height: value,
            child: PicnicCachedNetworkImage(
              imageUrl: url,
              imageRequest: request,
              lazyLoadingStrategy: LazyLoadingStrategy.none,
              showLoadingOverlay: false,
            ),
          ),
        ),
      ),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    final firstCompleter = request.provider.resolve(configuration).completer;
    expect(_displayImage(tester).image, same(request.provider));
    expect(_displayImage(tester).height, 40);

    height.value = 80;
    await tester.pump();
    expect(_displayImage(tester).image, same(request.provider));
    expect(_displayImage(tester).height, 80);
    expect(
      request.provider.resolve(configuration).completer,
      same(firstCompleter),
    );
    expect(harness.requestsFor(url), 1);

    harness.release(url);
    await _pumpUntilRawImage(tester);
    expect(harness.requestsFor(url), 1);
  });

  testWidgets('blank and zero-area inputs never create an image request', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 80,
          height: 40,
          child: PicnicCachedNetworkImage(
            imageUrl: '   ',
            lazyLoadingStrategy: LazyLoadingStrategy.none,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(harness.maximumActiveRequests, 0);

    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 0,
          height: 0,
          child: PicnicCachedNetworkImage(
            imageUrl: 'https://images.example.com/zero.png',
            lazyLoadingStrategy: LazyLoadingStrategy.none,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(harness.requestsFor('https://images.example.com/zero.png'), 0);
  });

  testWidgets('cold scroll deferral delays both request and timeout', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/deferred.png';
    await tester.runAsync(() => harness.respondPng(url, held: true));
    addTearDown(() => harness.release(url));
    final physics = _ToggleDeferredPhysics()..deferred.value = true;
    addTearDown(physics.deferred.dispose);
    PicnicCachedNetworkImage.disableTimeoutForTest = false;

    await tester.pumpWidget(
      _scrollApp(
        physics,
        const PicnicCachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 40,
          timeout: Duration(milliseconds: 50),
          maxRetries: 0,
          deferDuringFastScroll: true,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(harness.requestsFor(url), 0);
    expect(lastTimeoutLogTimesContainsForTest(url), isFalse);

    physics.deferred.value = false;
    await tester.pump();
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await tester.pump(const Duration(milliseconds: 60));

    expect(lastTimeoutLogTimesContainsForTest(url), isTrue);
    harness.release(url);
    await _pumpUntilRawImage(tester);
  });

  testWidgets('warm and pending images survive a deferred-scroll rebuild', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/pending-scroll.png';
    await tester.runAsync(() => harness.respondPng(url, held: true));
    addTearDown(() => harness.release(url));
    final physics = _ToggleDeferredPhysics();
    addTearDown(physics.deferred.dispose);

    await tester.pumpWidget(
      _scrollApp(
        physics,
        const PicnicCachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 40,
          deferDuringFastScroll: true,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);

    physics.deferred.value = true;
    await tester.pumpWidget(
      _scrollApp(
        physics,
        const PicnicCachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 40,
          deferDuringFastScroll: true,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(harness.requestsFor(url), 1);

    harness.release(url);
    await _pumpUntilRawImage(tester);
    final completed = _decodedImage(tester);

    await tester.pumpWidget(
      _scrollApp(
        physics,
        const PicnicCachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 40,
          deferDuringFastScroll: true,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );
    await tester.pump();

    expect(_decodedImage(tester), same(completed));
    expect(harness.requestsFor(url), 1);
  });

  testWidgets('query-string GIF renders multiple frames through one provider', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/two-frame.gif?token=signed';
    await tester.runAsync(() => harness.respondAnimatedGif(url));
    final context = await _pumpContext(tester);
    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: url,
      width: 4,
      height: 2,
      memCacheWidth: 4,
      memCacheHeight: 2,
    );

    await tester.pumpWidget(
      _app(
        PicnicCachedNetworkImage(
          imageUrl: url,
          imageRequest: request,
          width: 4,
          height: 2,
          lazyLoadingStrategy: LazyLoadingStrategy.none,
          showLoadingOverlay: false,
        ),
      ),
    );
    await _pumpUntilRawImage(tester);
    expect(_displayImage(tester).image, same(request.provider));
    expect(harness.requestsFor(url), 1);
    final first = await _firstRgba(tester, _decodedImage(tester));
    var sawDifferentFrame = false;
    for (var frame = 0; frame < 8 && !sawDifferentFrame; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      final current = await _firstRgba(tester, _decodedImage(tester));
      sawDifferentFrame = current.toString() != first.toString();
    }
    expect(sawDifferentFrame, isTrue);
    expect(successfullyLoadedImageUrlsContainsForTest(url), isTrue);
    expect(harness.requestsFor(url), 1);
  });
}

Widget _app(Widget child, {double devicePixelRatio = 1}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(393, 852),
        devicePixelRatio: devicePixelRatio,
      ),
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

Future<BuildContext> _pumpContext(
  WidgetTester tester, {
  double devicePixelRatio = 1,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (currentContext) {
          context = currentContext;
          return const SizedBox.shrink();
        },
      ),
      devicePixelRatio: devicePixelRatio,
    ),
  );
  return context;
}

Image _displayImage(WidgetTester tester) => tester.widget<Image>(
  find.descendant(
    of: find.byType(PicnicCachedNetworkImage),
    matching: find.byType(Image),
  ),
);

CachedNetworkImageProvider _networkProvider(ResizeImage resize) =>
    resize.imageProvider as CachedNetworkImageProvider;

ui.Image _decodedImage(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .singleWhere((candidate) => candidate.image != null)
    .image!;

Future<List<int>> _centerRgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (bytes == null) fail('Decoded image did not expose RGBA bytes.');
  final center = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      bytes.getUint8(center + channel),
  ];
}

Future<List<int>> _firstRgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (bytes == null) fail('Decoded image did not expose RGBA bytes.');
  return [
    for (var channel = 0; channel < 4; channel++) bytes.getUint8(channel),
  ];
}

Future<void> _pumpUntilRawImage(WidgetTester tester) {
  return _pumpUntil(
    tester,
    () => tester
        .widgetList<RawImage>(find.byType(RawImage))
        .any((candidate) => candidate.image != null),
  );
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
