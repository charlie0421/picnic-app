import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/factories/vote_factory.dart';
import '../../../../helpers/image_test_harness.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

VoteItemModel _item(String imageUrl) {
  return VoteItemModel.fromJson({
    'id': 1,
    'vote_id': 1,
    'vote_total': 100,
    'artist': {
      'id': 10,
      'name': {'ko': 'Artist', 'en': 'Artist'},
      'image': imageUrl,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'Group', 'en': 'Group'},
        'image': null,
      },
    },
    'artist_group': null,
  });
}

void main() {
  late Duration previousVisibilityInterval;

  setUp(() {
    initTestColors();
    setupMockSupabase({'vote': <dynamic>[], 'vote_item': <dynamic>[]});
    previousVisibilityInterval =
        VisibilityDetectorController.instance.updateInterval;
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval =
        previousVisibilityInterval;
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    resetSuccessfullyLoadedImageUrlsForTest();
    resetImageLoadTrackingMapsForTest();
    tearDownMockSupabase();
  });

  testWidgets('standard voting artist starts and decodes before 500 ms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/voting-artist.png';
    await tester.runAsync(
      () => harness.respondPng(
        url,
        width: 320,
        height: 160,
        color: const Color(0xff00ff00),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(VotingArtistImage(voteItemModel: _item(url))),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await _pumpUntil(tester, () => _decodedImage(tester, url) != null);

    final loader = _loader(tester, url);
    expect(loader.lazyLoadingStrategy, LazyLoadingStrategy.none);
    expect(loader.priority, ImagePriority.high);
    expect((loader.width, loader.height), (80, 80));
    final decoded = _decodedImage(tester, url)!;
    expect(decoded.width / decoded.height, closeTo(2, 0.04));
    expect(await _centerRgba(tester, decoded), [0, 255, 0, 255]);
    expect(harness.requestsFor(url), 1);
  });

  for (final isGroup in [false, true]) {
    testWidgets(
      'completion ${isGroup ? "group" : "artist"} starts eagerly and paints cached detail before the final image',
      (tester) async {
        _configurePhone(tester, devicePixelRatio: 3);
        // The Ahem test font overflows the pre-existing receipt timestamp row.
        // Image and other framework errors must still fail this test.
        _ignoreDialogOverflow(addTearDown);
        final appIcon = await tester.runAsync(
          () => File('../picnic_app/assets/app_icon_128.png').readAsBytes(),
        );
        final harness = await ImageTestHarness.create();
        addTearDown(harness.dispose);
        final source = '/artist/complete-${isGroup ? "group" : "artist"}.png';
        final context = await _pumpRequestContext(tester);
        final detail = _detailRequest(context, source);
        final complete = PicnicImageRequest.resolve(
          context: context,
          imageUrl: source,
          width: 60,
          height: 60,
        );
        await tester.runAsync(
          () => harness.respondPng(
            detail.url,
            width: 156,
            height: 156,
            color: const Color(0xff00ff00),
          ),
        );
        await tester.runAsync(
          () => harness.respondPng(
            complete.url,
            width: 600,
            height: 600,
            color: const Color(0xffff0000),
            held: true,
          ),
        );
        addTearDown(() => harness.release(complete.url));
        await _prime(tester, detail, context);
        final item = isGroup
            ? VoteItemModel.fromJson({
                'id': 1,
                'vote_id': 1,
                'vote_total': 100,
                'artist': null,
                'artist_group': {
                  'id': 1,
                  'name': {'ko': 'Group', 'en': 'Group'},
                  'image': source,
                },
              })
            : _item(source);

        await tester.pumpWidget(
          buildTestApp(
            DefaultAssetBundle(
              bundle: _CompletionAssetBundle(appIcon!),
              child: VotingCompleteDialog(
                voteModel: VoteFactory.create(),
                voteItemModel: item,
                result: const {'addedVoteTotal': 10},
              ),
            ),
          ),
        );
        await _pumpUntil(tester, () => harness.requestsFor(complete.url) == 1);
        await _pumpUntil(tester, () => _decodedImage(tester, source) != null);
        final loader = _loader(tester, source);
        expect((loader.width, loader.height), (60, 60));
        expect(_decodedImage(tester, source)!.width, 78);
        expect(await _centerRgba(tester, _decodedImage(tester, source)!), [
          0,
          255,
          0,
          255,
        ]);
        expect(harness.requestsFor(detail.url), 1);

        harness.release(complete.url);
        await _pumpUntil(
          tester,
          () => _decodedImage(tester, source)?.width == complete.decodeWidth,
        );
        expect(await _centerRgba(tester, _decodedImage(tester, source)!), [
          255,
          0,
          0,
          255,
        ]);
        expect(harness.requestsFor(complete.url), 1);
        expect(harness.requestsFor(detail.url), 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }

  testWidgets(
    'standard popup paints the completed detail pixels until its larger CDN variant arrives',
    (tester) async {
      _configurePhone(tester, devicePixelRatio: 3);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const source = '/artist/warm-standard.png?stale=discarded';
      final context = await _pumpRequestContext(tester);
      final detail = _detailRequest(context, source);
      final popup = _popupRequest(context, source, logicalSize: 80);
      expect(detail.url, isNot(popup.url));
      expect(
        popup.url,
        'https://test-cdn.example.com/artist/warm-standard.png?q=85&w=190&h=190',
      );
      expect(Uri.parse(detail.url).queryParameters, {
        'q': '55',
        'w': '78',
        'h': '78',
      });

      await tester.runAsync(
        () => harness.respondPng(
          detail.url,
          width: 156,
          height: 78,
          color: const Color(0xff00ff00),
        ),
      );
      await tester.runAsync(
        () => harness.respondPng(
          popup.url,
          width: 800,
          height: 400,
          color: const Color(0xffff0000),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popup.url));
      final detailKey = await _prime(tester, detail, context);

      await tester.pumpWidget(
        buildTestApp(VotingArtistImage(voteItemModel: _item(source))),
      );
      await _pumpUntil(tester, () => harness.requestsFor(popup.url) == 1);
      await _pumpUntil(tester, () => _decodedImage(tester, source) != null);

      final preview = _decodedImage(tester, source)!;
      expect(preview.debugDisposed, isFalse);
      expect(await _centerRgba(tester, preview), [0, 255, 0, 255]);
      expect(preview.width, 78);
      expect(harness.requestsFor(detail.url), 1);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKey).live,
        isTrue,
      );

      harness.release(popup.url);
      await _pumpUntil(
        tester,
        () => _decodedImage(tester, source)?.width == popup.decodeWidth,
      );

      final finalImage = _decodedImage(tester, source)!;
      expect(await _centerRgba(tester, finalImage), [255, 0, 0, 255]);
      expect(finalImage.width, greaterThan(preview.width));
      expect(preview.debugDisposed, isTrue);
      expect(harness.requestsFor(detail.url), 1);
      expect(harness.requestsFor(popup.url), 1);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKey).live,
        isFalse,
      );
    },
  );

  testWidgets(
    'JMA popup uses the same completed detail preview without changing its 60 logical pixel request',
    (tester) async {
      _configurePhone(tester, devicePixelRatio: 3);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const source = 'https://test-cdn.example.com/artist/warm-jma.png?old=1';
      final context = await _pumpRequestContext(tester);
      final detail = _detailRequest(context, source);
      final popup = _popupRequest(context, source, logicalSize: 60);
      expect(detail.url, isNot(popup.url));
      await tester.runAsync(
        () => harness.respondPng(
          detail.url,
          width: 156,
          height: 78,
          color: const Color(0xff00ff00),
        ),
      );
      await tester.runAsync(
        () => harness.respondPng(
          popup.url,
          width: 600,
          height: 300,
          color: const Color(0xff0000ff),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popup.url));
      await _prime(tester, detail, context);
      _ignoreDialogOverflow(addTearDown);

      await tester.pumpWidget(
        buildTestApp(
          JmaVotingDialog(
            voteModel: VoteFactory.create(id: 1),
            voteItemModel: _item(source),
            portalType: VotePortal.vote,
          ),
          loggedIn: false,
        ),
      );
      await _pumpUntil(tester, () => harness.requestsFor(popup.url) == 1);
      await _pumpUntil(tester, () => _decodedImage(tester, source) != null);

      expect(await _centerRgba(tester, _decodedImage(tester, source)!), [
        0,
        255,
        0,
        255,
      ]);
      expect(
        (_loader(tester, source).width, _loader(tester, source).height),
        (60, 60),
      );

      harness.release(popup.url);
      await _pumpUntil(
        tester,
        () => _decodedImage(tester, source)?.width == popup.decodeWidth,
      );
      expect(await _centerRgba(tester, _decodedImage(tester, source)!), [
        0,
        0,
        255,
        255,
      ]);
      expect(harness.requestsFor(detail.url), 1);
      expect(harness.requestsFor(popup.url), 1);
    },
  );

  testWidgets('a missing detail memory entry never starts a fallback request', (
    tester,
  ) async {
    _configurePhone(tester, devicePixelRatio: 3);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const source = '/artist/cold-popup.png';
    final context = await _pumpRequestContext(tester);
    final detail = _detailRequest(context, source);
    final popup = _popupRequest(context, source, logicalSize: 80);
    await tester.runAsync(
      () => harness.respondPng(
        popup.url,
        color: const Color(0xffff0000),
        held: true,
      ),
    );
    addTearDown(() => harness.release(popup.url));

    await tester.pumpWidget(
      buildTestApp(VotingArtistImage(voteItemModel: _item(source))),
    );
    await _pumpUntil(tester, () => harness.requestsFor(popup.url) == 1);
    await tester.pump();

    expect(_decodedImage(tester, source), isNull);
    expect(harness.requestsFor(detail.url), 0);
    expect(harness.requestsFor(popup.url), 1);
    harness.release(popup.url);
    await _pumpUntil(tester, () => harness.activeRequests == 0);
  });

  testWidgets(
    'an evicted detail entry stays a non-fetching miss while the popup loads',
    (tester) async {
      _configurePhone(tester, devicePixelRatio: 3);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const source = '/artist/evicted-popup.png';
      final context = await _pumpRequestContext(tester);
      final detail = _detailRequest(context, source);
      final popup = _popupRequest(context, source, logicalSize: 80);
      await tester.runAsync(
        () => harness.respondPng(detail.url, color: const Color(0xff00ff00)),
      );
      await tester.runAsync(
        () => harness.respondPng(
          popup.url,
          color: const Color(0xffff0000),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popup.url));
      final detailKey = await _prime(tester, detail, context);
      expect(PaintingBinding.instance.imageCache.evict(detailKey), isTrue);
      await tester.runAsync(() => harness.removeFile(detail.url));

      await tester.pumpWidget(
        buildTestApp(VotingArtistImage(voteItemModel: _item(source))),
      );
      await _pumpUntil(tester, () => harness.requestsFor(popup.url) == 1);
      await tester.pump();

      expect(_decodedImage(tester, source), isNull);
      expect(harness.requestsFor(detail.url), 1);
      expect(harness.requestsFor(popup.url), 1);
      harness.release(popup.url);
      await _pumpUntil(tester, () => harness.activeRequests == 0);
    },
  );

  testWidgets('a pending detail entry is never adopted after it completes', (
    tester,
  ) async {
    _configurePhone(tester, devicePixelRatio: 3);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const source = '/artist/pending-detail.png';
    final context = await _pumpRequestContext(tester);
    final detail = _detailRequest(context, source);
    final popup = _popupRequest(context, source, logicalSize: 80);
    final detailKey = await detail.obtainKey(
      createLocalImageConfiguration(context),
    );
    await tester.runAsync(
      () => harness.respondPng(
        detail.url,
        color: const Color(0xff00ff00),
        held: true,
      ),
    );
    addTearDown(() => harness.release(detail.url));
    await tester.runAsync(
      () => harness.respondPng(
        popup.url,
        color: const Color(0xffff0000),
        held: true,
      ),
    );
    addTearDown(() => harness.release(popup.url));

    await tester.pumpWidget(
      buildTestApp(Image(image: detail.provider, width: 39, height: 39)),
    );
    await _pumpUntil(tester, () => harness.requestsFor(detail.url) == 1);
    expect(
      PaintingBinding.instance.imageCache.statusForKey(detailKey).pending,
      isTrue,
    );

    await tester.pumpWidget(
      buildTestApp(VotingArtistImage(voteItemModel: _item(source))),
    );
    await _pumpUntil(tester, () => harness.requestsFor(popup.url) == 1);
    harness.release(detail.url);
    await _pumpUntil(
      tester,
      () =>
          PaintingBinding.instance.imageCache.statusForKey(detailKey).keepAlive,
    );
    await tester.pump();

    expect(_decodedImage(tester, source), isNull);
    expect(harness.requestsFor(detail.url), 1);
    expect(harness.requestsFor(popup.url), 1);
    harness.release(popup.url);
    await _pumpUntil(tester, () => harness.activeRequests == 0);
  });

  testWidgets(
    'closing before the primary frame removes the cached-detail listener and image handle',
    (tester) async {
      _configurePhone(tester, devicePixelRatio: 3);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const source = '/artist/close-before-primary.png';
      final context = await _pumpRequestContext(tester);
      final detail = _detailRequest(context, source);
      final popup = _popupRequest(context, source, logicalSize: 80);
      await tester.runAsync(
        () => harness.respondPng(detail.url, color: const Color(0xff00ff00)),
      );
      await tester.runAsync(
        () => harness.respondPng(
          popup.url,
          color: const Color(0xffff0000),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popup.url));
      final detailKey = await _prime(tester, detail, context);

      await tester.pumpWidget(
        buildTestApp(VotingArtistImage(voteItemModel: _item(source))),
      );
      await _pumpUntil(tester, () => _decodedImage(tester, source) != null);
      final preview = _decodedImage(tester, source)!;
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKey).live,
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(preview.debugDisposed, isTrue);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKey).live,
        isFalse,
      );
      harness.release(popup.url);
      await _pumpUntil(tester, () => harness.activeRequests == 0);
    },
  );

  testWidgets(
    'rapid artist replacement drops the old preview and ignores its late primary frame',
    (tester) async {
      _configurePhone(tester, devicePixelRatio: 3);
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const sourceA = '/artist/rapid-a.png';
      const sourceB = '/artist/rapid-b.png';
      final context = await _pumpRequestContext(tester);
      final detailA = _detailRequest(context, sourceA);
      final detailB = _detailRequest(context, sourceB);
      final popupA = _popupRequest(context, sourceA, logicalSize: 80);
      final popupB = _popupRequest(context, sourceB, logicalSize: 80);
      await tester.runAsync(
        () => harness.respondPng(detailA.url, color: const Color(0xff00ff00)),
      );
      await tester.runAsync(
        () => harness.respondPng(detailB.url, color: const Color(0xff0000ff)),
      );
      await tester.runAsync(
        () => harness.respondPng(
          popupA.url,
          color: const Color(0xffff0000),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popupA.url));
      await tester.runAsync(
        () => harness.respondPng(
          popupB.url,
          color: const Color(0xffffff00),
          held: true,
        ),
      );
      addTearDown(() => harness.release(popupB.url));
      final detailKeyA = await _prime(tester, detailA, context);
      final detailKeyB = await _prime(tester, detailB, context);

      await tester.pumpWidget(
        buildTestApp(VotingArtistImage(voteItemModel: _item(sourceA))),
      );
      await _pumpUntil(tester, () => _decodedImage(tester, sourceA) != null);
      final previewA = _decodedImage(tester, sourceA)!;
      expect(await _centerRgba(tester, previewA), [0, 255, 0, 255]);

      await tester.pumpWidget(
        buildTestApp(VotingArtistImage(voteItemModel: _item(sourceB))),
      );
      await _pumpUntil(tester, () => harness.requestsFor(popupB.url) == 1);
      await _pumpUntil(tester, () => _decodedImage(tester, sourceB) != null);

      expect(previewA.debugDisposed, isTrue);
      expect(await _centerRgba(tester, _decodedImage(tester, sourceB)!), [
        0,
        0,
        255,
        255,
      ]);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKeyA).live,
        isFalse,
      );
      expect(
        PaintingBinding.instance.imageCache.statusForKey(detailKeyB).live,
        isTrue,
      );

      harness.release(popupA.url);
      await _pumpUntil(tester, () => harness.activeRequests == 1);
      expect(await _centerRgba(tester, _decodedImage(tester, sourceB)!), [
        0,
        0,
        255,
        255,
      ]);

      harness.release(popupB.url);
      await _pumpUntil(
        tester,
        () => _decodedImage(tester, sourceB)?.width == popupB.decodeWidth,
      );
      expect(await _centerRgba(tester, _decodedImage(tester, sourceB)!), [
        255,
        255,
        0,
        255,
      ]);
      expect(harness.requestsFor(detailA.url), 1);
      expect(harness.requestsFor(detailB.url), 1);
      expect(harness.requestsFor(popupA.url), 1);
      expect(harness.requestsFor(popupB.url), 1);
    },
  );

  testWidgets('JMA artist starts and decodes before 500 ms', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    const url = 'https://images.example.com/jma-artist.png';
    await tester.runAsync(
      () => harness.respondPng(
        url,
        width: 240,
        height: 120,
        color: const Color(0xff0000ff),
      ),
    );
    _ignoreDialogOverflow(addTearDown);

    await tester.pumpWidget(
      buildTestApp(
        JmaVotingDialog(
          voteModel: VoteFactory.create(id: 1),
          voteItemModel: _item(url),
          portalType: VotePortal.vote,
        ),
        loggedIn: false,
      ),
    );
    await _pumpUntil(tester, () => harness.requestsFor(url) == 1);
    await _pumpUntil(tester, () => _decodedImage(tester, url) != null);

    final loader = _loader(tester, url);
    expect(loader.lazyLoadingStrategy, LazyLoadingStrategy.none);
    expect(loader.priority, ImagePriority.high);
    expect((loader.width, loader.height), (60, 60));
    final decoded = _decodedImage(tester, url)!;
    expect(decoded.width / decoded.height, closeTo(2, 0.04));
    expect(await _centerRgba(tester, decoded), [0, 0, 255, 255]);
    expect(harness.requestsFor(url), 1);
  });
}

void _configurePhone(WidgetTester tester, {required double devicePixelRatio}) {
  tester.view.physicalSize = Size(
    375 * devicePixelRatio,
    812 * devicePixelRatio,
  );
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<BuildContext> _pumpRequestContext(WidgetTester tester) async {
  late BuildContext requestContext;
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          requestContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return requestContext;
}

PicnicImageRequest _detailRequest(BuildContext context, String source) {
  return PicnicImageRequest.resolve(
    context: context,
    imageUrl: source,
    width: 39,
    height: 39,
    memCacheWidth: 78,
    memCacheHeight: 78,
    maxQualityOverride: 55,
    maxResolutionMultiplierCap: 2,
  );
}

PicnicImageRequest _popupRequest(
  BuildContext context,
  String source, {
  required double logicalSize,
}) {
  return PicnicImageRequest.resolve(
    context: context,
    imageUrl: source,
    width: logicalSize.w - 4,
    height: logicalSize.w - 4,
  );
}

Future<Object> _prime(
  WidgetTester tester,
  PicnicImageRequest request,
  BuildContext context,
) async {
  final configuration = createLocalImageConfiguration(context);
  final key = await request.obtainKey(configuration);
  await tester.runAsync(() => precacheImage(request.provider, context));
  await tester.pump();
  expect(
    PaintingBinding.instance.imageCache.statusForKey(key).keepAlive,
    isTrue,
  );
  return key;
}

final class _CompletionAssetBundle extends CachingAssetBundle {
  _CompletionAssetBundle(this.appIcon);

  final Uint8List appIcon;

  @override
  Future<ByteData> load(String key) {
    if (key == 'assets/app_icon_128.png') {
      return Future.value(ByteData.sublistView(appIcon));
    }
    return rootBundle.load(key);
  }
}

void _ignoreDialogOverflow(void Function(VoidCallback callback) addCleanup) {
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    final exception = details.exception;
    if (exception is FlutterError && exception.message.contains('overflowed')) {
      return;
    }
    previousFlutterError?.call(details);
  };
  addCleanup(() {
    FlutterError.onError = previousFlutterError;
  });
}

Finder _loaderFinder(String url) => find.byWidgetPredicate(
  (widget) => widget is PicnicCachedNetworkImage && widget.imageUrl == url,
  skipOffstage: false,
);

PicnicCachedNetworkImage _loader(WidgetTester tester, String url) {
  return tester.widget<PicnicCachedNetworkImage>(_loaderFinder(url).first);
}

ui.Image? _decodedImage(WidgetTester tester, String url) {
  final rawImages = find.descendant(
    of: _loaderFinder(url).first,
    matching: find.byType(RawImage),
    skipOffstage: false,
  );
  for (final element in rawImages.evaluate()) {
    final renderObject = element.renderObject;
    if (renderObject is RenderImage && renderObject.image != null) {
      return renderObject.image;
    }
  }
  return null;
}

Future<List<int>> _centerRgba(WidgetTester tester, ui.Image image) async {
  final ownedImage = image.clone();
  try {
    final bytes = await tester.runAsync(
      () => ownedImage.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) fail('Decoded popup image did not expose RGBA bytes.');
    final center =
        ((ownedImage.height ~/ 2) * ownedImage.width + ownedImage.width ~/ 2) *
        4;
    return [
      for (var channel = 0; channel < 4; channel++)
        bytes.getUint8(center + channel),
    ];
  } finally {
    ownedImage.dispose();
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
  fail('Condition was not reached before advancing the 500 ms test clock.');
}
