import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(initTestColors);

  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('candidate limit accepts one and rejects unsupported values', () {
    expect(() {
      final scope = PicnicImagePrefetchScope(maximumCandidates: 1);
      scope.dispose();
    }, returnsNormally);
    expect(
      () => PicnicImagePrefetchScope(maximumCandidates: 0),
      throwsRangeError,
    );
    expect(
      () => PicnicImagePrefetchScope(maximumCandidates: 4),
      throwsRangeError,
    );
  });

  testWidgets(
    'three-candidate scope starts queued C after A decodes and never requests D',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const a = 'https://images.example.com/rank3-a.png';
      const b = 'https://images.example.com/rank3-b.png';
      const c = 'https://images.example.com/rank3-c.png';
      const d = 'https://images.example.com/rank3-d.png';
      await tester.runAsync(
        () => Future.wait([
          for (final url in [a, b, c, d]) harness.respondPng(url, held: true),
        ]),
      );
      final context = await _pumpContext(tester);
      final scope = PicnicImagePrefetchScope(maximumCandidates: 3);
      addTearDown(scope.dispose);
      final requestA = _request(context, a);

      scope.replace(context, [
        PicnicImageRequest.resolve(context: context, imageUrl: '   '),
        requestA,
        requestA,
        _request(context, b),
        _request(context, c),
        _request(context, d),
      ]);
      await _pumpUntil(
        tester,
        () =>
            harness.requestsFor(a) == 1 &&
            harness.requestsFor(b) == 1 &&
            harness.activeRequests == 2,
      );

      expect(harness.requestsFor(c), 0);
      expect(harness.requestsFor(d), 0);
      harness.release(a);
      await _pumpUntil(tester, () => harness.requestsFor(c) == 1);

      final keyA = await requestA.obtainKey(
        createLocalImageConfiguration(context),
      );
      expect(
        PaintingBinding.instance.imageCache.statusForKey(keyA).tracked,
        isTrue,
      );
      expect(harness.requestsFor(d), 0);
      expect(harness.activeRequests, 2);
      expect(harness.maximumActiveRequests, 2);

      scope.dispose();
      harness.release(b);
      harness.release(c);
      await _pumpUntil(
        tester,
        () =>
            harness.activeRequests == 0 &&
            PaintingBinding.instance.imageCache.pendingImageCount == 0,
      );
      await tester.pump();
    },
  );

  testWidgets(
    'three-candidate scopes share work under the global two-job cap',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const urls = [
        'https://images.example.com/a.png',
        'https://images.example.com/b.png',
        'https://images.example.com/c.png',
        'https://images.example.com/d.png',
      ];
      await tester.runAsync(
        () => Future.wait([
          for (final url in urls) harness.respondPng(url, held: true),
        ]),
      );
      final context = await _pumpContext(tester);
      final requests = [for (final url in urls) _request(context, url)];
      final first = PicnicImagePrefetchScope(maximumCandidates: 3);
      final second = PicnicImagePrefetchScope(maximumCandidates: 3);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.replace(context, [requests[0], requests[1]]);
      await _pumpUntil(
        tester,
        () =>
            harness.requestsFor(urls[0]) == 1 &&
            harness.requestsFor(urls[1]) == 1 &&
            harness.activeRequests == 2,
      );
      second.replace(context, [
        requests[0],
        requests[0],
        requests[2],
        requests[3],
      ]);
      await _pumpAsyncWork(tester);

      expect(harness.requestsFor(urls[0]), 1);
      expect(harness.requestsFor(urls[2]), 0);
      expect(harness.requestsFor(urls[3]), 0);
      expect(harness.maximumActiveRequests, 2);

      harness.release(urls[1]);
      await _pumpUntil(tester, () => harness.requestsFor(urls[2]) == 1);

      expect(harness.requestsFor(urls[0]), 1);
      expect(harness.requestsFor(urls[3]), 0);
      expect(harness.activeRequests, 2);
      expect(harness.maximumActiveRequests, 2);

      first.dispose();
      second.dispose();
      harness.release(urls[0]);
      harness.release(urls[2]);
      await _pumpUntil(
        tester,
        () =>
            harness.activeRequests == 0 &&
            PaintingBinding.instance.imageCache.pendingImageCount == 0,
      );
      await tester.pump();
    },
  );

  for (final maximumCandidates in [2, 3]) {
    testWidgets('candidate iteration stops at $maximumCandidates unique keys', (
      tester,
    ) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const a = 'https://images.example.com/bounded-a.png';
      const b = 'https://images.example.com/bounded-b.png';
      const c = 'https://images.example.com/bounded-c.png';
      const d = 'https://images.example.com/bounded-d.png';
      await tester.runAsync(
        () => Future.wait([
          harness.respondPng(a, held: true),
          harness.respondPng(b, held: true),
          harness.respondPng(c, held: true),
          harness.respondPng(d, held: true),
        ]),
      );
      final context = await _pumpContext(tester);
      final scope = maximumCandidates == 2
          ? PicnicImagePrefetchScope()
          : PicnicImagePrefetchScope(maximumCandidates: maximumCandidates);
      addTearDown(scope.dispose);

      var enumerated = 0;
      Iterable<PicnicImageRequest> candidates() sync* {
        for (final url in [a, b, c, d]) {
          enumerated++;
          yield _request(context, url);
        }
      }

      expect(() => scope.replace(context, candidates()), returnsNormally);
      await _pumpUntil(tester, () => harness.activeRequests == 2);
      await _pumpAsyncWork(tester);

      // Release held responses before assertions so a failed bound check can
      // finish cleanly instead of leaving the test server waiting forever.
      scope.dispose();
      harness.release(a);
      harness.release(b);
      harness.release(c);
      harness.release(d);
      await _pumpUntil(
        tester,
        () =>
            harness.activeRequests == 0 &&
            PaintingBinding.instance.imageCache.pendingImageCount == 0,
      );
      await tester.pump();
      expect(enumerated, maximumCandidates);
      expect(harness.requestsFor(a), 1);
      expect(harness.requestsFor(b), 1);
    });
  }

  testWidgets('replace and dispose cancel queued work without gating display', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const a = 'https://images.example.com/held-a.png';
    const b = 'https://images.example.com/held-b.png';
    const stale = 'https://images.example.com/stale.png';
    const disposed = 'https://images.example.com/disposed.png';
    const display = 'https://images.example.com/display.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(a, held: true),
        harness.respondPng(b, held: true),
        harness.respondPng(stale, held: true),
        harness.respondPng(disposed, held: true),
        harness.respondPng(display),
      ]),
    );
    final host = await _pumpDisplayHost(tester);
    final activeScope = PicnicImagePrefetchScope(maximumCandidates: 3);
    final queuedScope = PicnicImagePrefetchScope(maximumCandidates: 3);
    addTearDown(activeScope.dispose);
    addTearDown(queuedScope.dispose);

    activeScope.replace(host.context, [
      _request(host.context, a),
      _request(host.context, b),
      _request(host.context, stale),
    ]);
    await _pumpUntil(tester, () => harness.activeRequests == 2);
    expect(harness.requestsFor(stale), 0);
    activeScope.replace(host.context, [
      _request(host.context, a),
      _request(host.context, b),
    ]);
    for (var replacement = 0; replacement < 50; replacement++) {
      queuedScope.replace(host.context, [_request(host.context, disposed)]);
      await tester.pump();
    }
    queuedScope.dispose();

    host.display.value = _request(host.context, display).provider;
    await tester.pump();
    await _pumpUntil(tester, () => harness.requestsFor(display) == 1);

    expect(harness.requestsFor(a), 1);
    expect(harness.requestsFor(b), 1);
    expect(harness.requestsFor(stale), 0);
    expect(harness.requestsFor(disposed), 0);
    expect(harness.maximumActiveRequests, 3);

    activeScope.dispose();
    harness.release(a);
    harness.release(b);
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    expect(harness.requestsFor(stale), 0);
    expect(harness.requestsFor(disposed), 0);
    host.display.value = null;
    await tester.pump();
  });

  testWidgets('a failure releases capacity and a later replace retries it', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const a = 'https://images.example.com/failure-held-a.png';
    const b = 'https://images.example.com/failure-held-b.png';
    const failing = 'https://images.example.com/failing.png';
    const afterFailure = 'https://images.example.com/after-failure.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(a, held: true),
        harness.respondPng(b, held: true),
        harness.respondPng(failing),
        harness.respondPng(afterFailure, held: true),
      ]),
    );
    harness.failNext(failing, StateError('intentional first failure'));
    final context = await _pumpContext(tester);
    final activeScope = PicnicImagePrefetchScope();
    final queuedScope = PicnicImagePrefetchScope();
    addTearDown(activeScope.dispose);
    addTearDown(queuedScope.dispose);
    final failingRequest = _request(context, failing);

    activeScope.replace(context, [_request(context, a), _request(context, b)]);
    await _pumpUntil(tester, () => harness.activeRequests == 2);
    queuedScope.replace(context, [
      failingRequest,
      _request(context, afterFailure),
    ]);

    harness.release(a);
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(failing) == 1 &&
          harness.requestsFor(afterFailure) == 1,
    );

    expect(tester.takeException(), isNull);
    expect(harness.activeRequests, 2);
    expect(harness.maximumActiveRequests, 2);

    final key = await failingRequest.obtainKey(
      createLocalImageConfiguration(context),
    );
    PaintingBinding.instance.imageCache.evict(key, includeLive: true);
    queuedScope.replace(context, [failingRequest]);
    harness.release(afterFailure);
    await _pumpUntil(tester, () => harness.requestsFor(failing) == 2);

    expect(tester.takeException(), isNull);
    expect(harness.maximumActiveRequests, 2);
    harness.release(b);
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await tester.pump();
  });

  testWidgets('eviction allows an unchanged scope candidate to prepare again', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/evicted.png';
    await tester.runAsync(() => harness.respondPng(url));
    final context = await _pumpContext(tester);
    final request = _request(context, url);
    final scope = PicnicImagePrefetchScope();
    addTearDown(scope.dispose);

    scope.replace(context, [request]);
    await _pumpUntil(
      tester,
      () =>
          harness.requestsFor(url) == 1 &&
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await tester.pump();
    final configuration = createLocalImageConfiguration(context);
    final key = await request.obtainKey(configuration);
    final firstCompleter = request.provider.resolve(configuration).completer;

    scope.replace(context, [request]);
    await _pumpAsyncWork(tester);
    expect(harness.requestsFor(url), 1);

    PaintingBinding.instance.imageCache.evict(key, includeLive: true);
    await harness.removeFile(request.url);
    scope.replace(context, [request]);
    await _pumpUntil(tester, () => harness.requestsFor(url) == 2);
    await _pumpUntil(
      tester,
      () => PaintingBinding.instance.imageCache.statusForKey(key).tracked,
    );

    expect(
      request.provider.resolve(configuration).completer,
      isNot(same(firstCompleter)),
    );
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await tester.pump();
  });

  testWidgets('queued work is discarded when its BuildContext unmounts', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const a = 'https://images.example.com/context-a.png';
    const b = 'https://images.example.com/context-b.png';
    const queuedA = 'https://images.example.com/context-queued-a.png';
    const queuedB = 'https://images.example.com/context-queued-b.png';
    const queuedC = 'https://images.example.com/context-queued-c.png';
    await tester.runAsync(
      () => Future.wait([
        harness.respondPng(a, held: true),
        harness.respondPng(b, held: true),
        harness.respondPng(queuedA, held: true),
        harness.respondPng(queuedB, held: true),
        harness.respondPng(queuedC, held: true),
      ]),
    );
    final mounted = ValueNotifier<bool>(true);
    addTearDown(mounted.dispose);
    late BuildContext stableContext;
    late BuildContext transientContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            stableContext = context;
            return ValueListenableBuilder<bool>(
              valueListenable: mounted,
              builder: (context, isMounted, _) {
                if (!isMounted) return const SizedBox.shrink();
                return Builder(
                  builder: (context) {
                    transientContext = context;
                    return const SizedBox.shrink();
                  },
                );
              },
            );
          },
        ),
      ),
    );
    final activeScope = PicnicImagePrefetchScope();
    final queuedScope = PicnicImagePrefetchScope(maximumCandidates: 3);
    addTearDown(activeScope.dispose);
    addTearDown(queuedScope.dispose);

    activeScope.replace(stableContext, [
      _request(stableContext, a),
      _request(stableContext, b),
    ]);
    await _pumpUntil(tester, () => harness.activeRequests == 2);
    queuedScope.replace(transientContext, [
      _request(transientContext, queuedA),
      _request(transientContext, queuedB),
      _request(transientContext, queuedC),
    ]);
    mounted.value = false;
    await tester.pump();
    expect(transientContext.mounted, isFalse);

    harness.release(a);
    await _pumpUntil(tester, () => harness.activeRequests == 1);
    expect(harness.requestsFor(queuedA), 0);
    expect(harness.requestsFor(queuedB), 0);
    expect(harness.requestsFor(queuedC), 0);

    activeScope.dispose();
    queuedScope.dispose();
    harness.release(b);
    await _pumpUntil(
      tester,
      () =>
          harness.activeRequests == 0 &&
          PaintingBinding.instance.imageCache.pendingImageCount == 0,
    );
    await tester.pump();
  });

  testWidgets('blank requests do not consume a background slot', (
    tester,
  ) async {
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    final context = await _pumpContext(tester);
    final scope = PicnicImagePrefetchScope();
    addTearDown(scope.dispose);

    scope.replace(context, [
      PicnicImageRequest.resolve(context: context, imageUrl: ''),
      PicnicImageRequest.resolve(context: context, imageUrl: '   '),
    ]);
    await _pumpAsyncWork(tester);

    expect(harness.requestsFor(''), 0);
    expect(harness.activeRequests, 0);
    expect(harness.maximumActiveRequests, 0);
  });
}

PicnicImageRequest _request(BuildContext context, String url) {
  return PicnicImageRequest.resolve(
    context: context,
    imageUrl: url,
    width: 40,
    height: 20,
  );
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(393, 852), devicePixelRatio: 1),
        child: Builder(
          builder: (currentContext) {
            context = currentContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return context;
}

Future<_DisplayHost> _pumpDisplayHost(WidgetTester tester) async {
  late BuildContext context;
  final display = ValueNotifier<ImageProvider<Object>?>(null);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(393, 852), devicePixelRatio: 1),
        child: Builder(
          builder: (currentContext) {
            context = currentContext;
            return ValueListenableBuilder<ImageProvider<Object>?>(
              valueListenable: display,
              builder: (context, provider, _) {
                return provider == null
                    ? const SizedBox.shrink()
                    : Image(image: provider);
              },
            );
          },
        ),
      ),
    ),
  );
  addTearDown(display.dispose);
  return _DisplayHost(context, display);
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  for (var iteration = 0; iteration < 5; iteration++) {
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

final class _DisplayHost {
  const _DisplayHost(this.context, this.display);

  final BuildContext context;
  final ValueNotifier<ImageProvider<Object>?> display;
}
