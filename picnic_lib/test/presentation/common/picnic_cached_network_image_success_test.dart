import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

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

  testWidgets('static PNG has one configured decode entry and settles', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/static.png';
    await tester.runAsync(
      () => harness.respondPng(url, width: 160, height: 80),
    );

    await tester.pumpWidget(_imageApp(url));
    await _pumpUntilRawImage(tester);

    expect(_decodedDimensions(tester), {(80, 40)});
    expect(harness.requestsFor(url), 1);
    expect(PaintingBinding.instance.imageCache.currentSize, 1);
    for (var pump = 0; pump < 5; pump++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_imageApp(url));
    await tester.pump();
    expect(harness.requestsFor(url), 1);
    expect(_decodedDimensions(tester), {(80, 40)});
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('old success cannot cancel a replacement timeout', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const firstUrl = 'https://images.example.com/old-success.png';
    const replacementUrl = 'https://images.example.com/replacement.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(firstUrl, held: true),
        harness.respondPng(replacementUrl, held: true),
      ]),
    );
    addTearDown(() {
      harness.release(firstUrl);
      harness.release(replacementUrl);
    });

    await tester.pumpWidget(_imageApp(firstUrl));
    await _pumpUntil(tester, () => harness.requestsFor(firstUrl) == 1);
    final oldFrameBuilder = _displayImage(tester).frameBuilder!;

    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    await tester.pumpWidget(
      _imageApp(replacementUrl, timeout: const Duration(milliseconds: 50)),
    );
    await _pumpUntil(tester, () => harness.requestsFor(replacementUrl) == 1);

    oldFrameBuilder(
      tester.element(find.byType(PicnicCachedNetworkImage)),
      const SizedBox.shrink(),
      0,
      false,
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(lastTimeoutLogTimesContainsForTest(replacementUrl), isTrue);
    expect(successfullyLoadedImageUrlsContainsForTest(replacementUrl), isFalse);
    expect(successfullyLoadedImageUrlsContainsForTest(firstUrl), isFalse);

    harness.release(firstUrl);
    harness.release(replacementUrl);
    await _pumpUntilRawImage(tester);
  });

  testWidgets('old and repeated error callbacks cannot multiply retries', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const oldUrl = 'https://images.example.com/old-error.png';
    const currentUrl = 'https://images.example.com/current.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(oldUrl, held: true),
        harness.respondPng(currentUrl),
      ]),
    );
    addTearDown(() => harness.release(oldUrl));

    await tester.pumpWidget(_imageApp(oldUrl, maxRetries: 1));
    await _pumpUntil(tester, () => harness.requestsFor(oldUrl) == 1);
    final oldErrorBuilder = _displayImage(tester).errorBuilder!;

    harness.failNext(currentUrl, StateError('SocketException: reset'));
    await tester.pumpWidget(_imageApp(currentUrl, maxRetries: 1));
    await _pumpUntil(tester, () => harness.requestsFor(currentUrl) == 1);
    final currentErrorBuilder = _displayImage(tester).errorBuilder!;
    final buildContext = tester.element(find.byType(PicnicCachedNetworkImage));

    for (var repeat = 0; repeat < 5; repeat++) {
      oldErrorBuilder(
        buildContext,
        StateError('SocketException: stale'),
        StackTrace.current,
      );
      currentErrorBuilder(
        buildContext,
        StateError('SocketException: repeated'),
        StackTrace.current,
      );
    }

    harness.release(oldUrl);
    await tester.pump(const Duration(milliseconds: 760));
    await _pumpUntilRawImage(tester);
    expect(harness.requestsFor(oldUrl), 1);
    expect(harness.requestsFor(currentUrl), 2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('HTTP 404 is terminal and does not consume retry budget', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/not-found.png';
    await tester.runAsync(() => harness.respondPng(url));
    harness.failNext(url, StateError('HTTP 404 Not Found'));

    await tester.pumpWidget(
      _imageApp(url, maxRetries: 2, errorWidget: const Text('terminal-error')),
    );
    await _pumpUntil(
      tester,
      () => find.text('terminal-error').evaluate().isNotEmpty,
    );
    await tester.pump(const Duration(seconds: 2));

    expect(harness.requestsFor(url), 1);
    expect(find.text('terminal-error'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('terminal timeout shows its error while the stream can recover', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    const url = 'https://images.example.com/terminal-timeout.png';
    const errorKey = ValueKey('terminal-timeout-error');
    await tester.runAsync(() => harness.respondPng(url, held: true));
    addTearDown(() async {
      harness.release(url);
      await harness.dispose();
    });
    PicnicCachedNetworkImage.disableTimeoutForTest = false;

    await tester.pumpWidget(
      _imageApp(
        url,
        timeout: const Duration(milliseconds: 50),
        maxRetries: 0,
        errorWidget: const SizedBox(key: errorKey),
      ),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byKey(errorKey), findsOneWidget);
    expect(lastTimeoutLogTimesContainsForTest(url), isTrue);

    harness.release(url);
    await _pumpUntilRawImage(tester);
    expect(find.byKey(errorKey), findsNothing);
    expect(successfullyLoadedImageUrlsContainsForTest(url), isTrue);
  });

  testWidgets('dispose cancels a scheduled retry', (tester) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/disposed-retry.png';
    await tester.runAsync(() => harness.respondPng(url));
    harness.failNext(url, StateError('SocketException: reset'));

    await tester.pumpWidget(_imageApp(url, maxRetries: 1));
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(harness.requestsFor(url), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late success cancels the retry created by timeout', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/late-success.png';
    await tester.runAsync(() => harness.respondPng(url, held: true));
    addTearDown(() => harness.release(url));
    PicnicCachedNetworkImage.disableTimeoutForTest = false;

    await tester.pumpWidget(
      _imageApp(url, timeout: const Duration(milliseconds: 50), maxRetries: 1),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await tester.pump(const Duration(milliseconds: 60));
    expect(lastTimeoutLogTimesContainsForTest(url), isTrue);

    harness.release(url);
    await _pumpUntilRawImage(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(harness.requestsFor(url), 1);
    expect(successfullyLoadedImageUrlsContainsForTest(url), isTrue);
    expect(lastTimeoutLogTimesContainsForTest(url), isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

Widget _imageApp(
  String url, {
  Duration timeout = const Duration(seconds: 30),
  int maxRetries = 0,
  Widget? errorWidget,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PicnicCachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 40,
        memCacheWidth: 80,
        memCacheHeight: 40,
        timeout: timeout,
        maxRetries: maxRetries,
        errorWidget: errorWidget,
        lazyLoadingStrategy: LazyLoadingStrategy.none,
        showLoadingOverlay: false,
      ),
    ),
  );
}

Image _displayImage(WidgetTester tester) => tester.widget<Image>(
  find.descendant(
    of: find.byType(PicnicCachedNetworkImage),
    matching: find.byType(Image),
  ),
);

Set<(int, int)> _decodedDimensions(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .where((widget) => widget.image != null)
    .map((widget) => (widget.image!.width, widget.image!.height))
    .toSet();

Future<void> _pumpUntilRawImage(WidgetTester tester) {
  return _pumpUntil(tester, () => _decodedDimensions(tester).isNotEmpty);
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
