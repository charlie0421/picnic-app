import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(initTestColors);

  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('nullable CDN axes become capped physical request pixels', (
    tester,
  ) async {
    final context = await _pumpContext(tester, devicePixelRatio: 2);

    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/hero.jpg',
      width: 320,
    );

    expect(request.requestWidth, 768);
    expect(request.requestHeight, isNull);
    expect(Uri.parse(request.url).queryParameters, {'q': '80', 'w': '768'});
    expect(request.decodeWidth, 768);
    expect(request.decodeHeight, 2000);
  });

  testWidgets('missing or invalid axes keep a q-only request and safe decode', (
    tester,
  ) async {
    final context = await _pumpContext(tester, devicePixelRatio: double.nan);

    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/unknown.png',
      width: double.nan,
      height: -20,
      maxResolutionMultiplierCap: double.nan,
    );

    expect(request.requestWidth, isNull);
    expect(request.requestHeight, isNull);
    expect(Uri.parse(request.url).queryParameters, {'q': '80'});
    expect(request.decodeWidth, 400);
    expect(request.decodeHeight, 400);
  });

  testWidgets('resolution cap accepts only finite positive values', (
    tester,
  ) async {
    final context = await _pumpContext(tester, devicePixelRatio: 3);

    final capped = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/capped.jpg',
      width: 100,
      maxResolutionMultiplierCap: 0.5,
    );
    final invalidCap = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/uncapped.jpg',
      width: 100,
      maxResolutionMultiplierCap: 0,
    );

    expect(capped.requestWidth, 50);
    expect(invalidCap.requestWidth, 250);
  });

  testWidgets('two physical axes are proportionally capped at two megapixels', (
    tester,
  ) async {
    final context = await _pumpContext(tester);

    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/large.jpg',
      width: 2000,
      height: 2000,
    );

    expect(request.requestWidth, 1414);
    expect(request.requestHeight, 1414);
    expect(
      request.requestWidth! * request.requestHeight!,
      lessThanOrEqualTo(2000000),
    );
    expect(request.decodeWidth, 1414);
    expect(request.decodeHeight, 1414);
  });

  testWidgets(
    'finite huge axes are capped before integer conversion overflows',
    (tester) async {
      final context = await _pumpContext(tester, devicePixelRatio: 3);

      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: '/images/huge.jpg',
        width: 1e308,
        height: 5e307,
      );

      expect(request.requestWidth, 2000);
      expect(request.requestHeight, 1000);
      expect(request.decodeWidth, 2000);
      expect(request.decodeHeight, 1000);
    },
  );

  testWidgets('blank source stays blank instead of resolving to the CDN root', (
    tester,
  ) async {
    final context = await _pumpContext(tester);

    final empty = PicnicImageRequest.resolve(context: context, imageUrl: '');
    final whitespace = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '   ',
    );

    expect(empty.imageUrl, '');
    expect(empty.url, '');
    expect(whitespace.imageUrl, '   ');
    expect(whitespace.url, '');
  });

  testWidgets(
    'explicit memory dimensions stay physical and cap the auto axis',
    (tester) async {
      final context = await _pumpContext(tester, devicePixelRatio: 2);

      final fixed = PicnicImageRequest.resolve(
        context: context,
        imageUrl: '/images/avatar.jpg',
        width: 72,
        height: 72,
        memCacheWidth: 78,
        memCacheHeight: 78,
      );
      final mixed = PicnicImageRequest.resolve(
        context: context,
        imageUrl: '/images/mixed.jpg',
        width: 1000,
        height: 1000,
        memCacheWidth: 1800,
      );

      expect(fixed.requestWidth, 173);
      expect(fixed.requestHeight, 173);
      expect(fixed.decodeWidth, 78);
      expect(fixed.decodeHeight, 78);
      expect(mixed.requestWidth, 1414);
      expect(mixed.requestHeight, 1414);
      expect(mixed.decodeWidth, 1800);
      expect(mixed.decodeHeight, 1111);
    },
  );

  testWidgets('GIF query detection and low-quality override retain policy', (
    tester,
  ) async {
    final context = await _pumpContext(tester);

    final gif = PicnicImageRequest.resolve(
      context: context,
      imageUrl: 'https://test-cdn.example.com/animation.gif?token=old',
      width: 100,
      height: 100,
      maxQualityOverride: 55,
    );
    final low = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/low.jpg',
      width: 100,
      height: 100,
      maxQualityOverride: 55,
    );

    expect(Uri.parse(gif.url).queryParameters['q'], '80');
    expect(Uri.parse(low.url).queryParameters['q'], '55');
  });

  testWidgets(
    'provider keeps signed external URL and has the exact resize key',
    (tester) async {
      final context = await _pumpContext(tester);
      const signedUrl =
          'https://external.example.com/photo.png?signature=a%2Bb&expires=9';

      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: signedUrl,
        width: 100,
        height: 100,
      );
      final identicalRequest = PicnicImageRequest.resolve(
        context: context,
        imageUrl: signedUrl,
        width: 100,
        height: 100,
      );
      final differentDecode = PicnicImageRequest.resolve(
        context: context,
        imageUrl: signedUrl,
        width: 100,
        height: 100,
        memCacheWidth: 80,
        memCacheHeight: 80,
      );

      expect(request.url, signedUrl);
      final resize = request.provider as ResizeImage;
      expect(resize.width, 120);
      expect(resize.height, 120);
      expect(resize.policy, ResizeImagePolicy.fit);
      expect(resize.allowUpscaling, isFalse);
      final network = resize.imageProvider as CachedNetworkImageProvider;
      expect(network.url, signedUrl);
      expect(network.cacheKey, signedUrl);
      expect(network.maxWidth, isNull);
      expect(network.maxHeight, isNull);

      final configuration = createLocalImageConfiguration(context);
      final key = await request.obtainKey(configuration);
      expect(key, await request.provider.obtainKey(configuration));
      expect(await identicalRequest.obtainKey(configuration), key);
      expect(await differentDecode.obtainKey(configuration), isNot(key));
    },
  );

  testWidgets(
    'real PNG preserves ratio and pixels through the request provider',
    (tester) async {
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const url = 'https://external.example.com/ratio.png';
      await tester.runAsync(
        () => harness.respondPng(
          url,
          width: 400,
          height: 200,
          color: const Color(0xffff0000),
        ),
      );
      final context = await _pumpContext(tester);
      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: url,
        width: 100,
        height: 100,
      );
      final configuration = createLocalImageConfiguration(context);
      final key = await request.obtainKey(configuration);

      await tester.runAsync(() => precacheImage(request.provider, context));
      await tester.pump();
      final preparedCompleter = request.provider
          .resolve(configuration)
          .completer;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              devicePixelRatio: 1,
            ),
            child: Image(image: request.provider),
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () => tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((raw) => raw.image != null),
      );

      final displayed = tester.widget<Image>(find.byType(Image));
      expect(await displayed.image.obtainKey(configuration), key);
      expect(
        displayed.image.resolve(configuration).completer,
        same(preparedCompleter),
      );
      expect(harness.requestsFor(request.url), 1);

      final raw = tester
          .widgetList<RawImage>(find.byType(RawImage))
          .singleWhere((candidate) => candidate.image != null);
      final rendered = raw.image!;
      expect(rendered.width / rendered.height, closeTo(2, 0.02));
      final pixels = await tester.runAsync(
        () => rendered.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(pixels, isNotNull);
      final center =
          ((rendered.height ~/ 2) * rendered.width + rendered.width ~/ 2) * 4;
      expect(
        [
          pixels!.getUint8(center),
          pixels.getUint8(center + 1),
          pixels.getUint8(center + 2),
          pixels.getUint8(center + 3),
        ],
        [255, 0, 0, 255],
      );
    },
  );
}

Future<BuildContext> _pumpContext(
  WidgetTester tester, {
  double devicePixelRatio = 1,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 852),
          devicePixelRatio: devicePixelRatio,
        ),
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

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump();
  }
  fail('Condition was not reached after asynchronous image work completed.');
}
