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

  test('shared variants pin one width and quality per use case', () {
    expect(
      [for (final variant in _sharedVariants) (variant.width, variant.quality)],
      [(180, 85), (500, 80), (1000, 80), (1600, 80)],
    );
  });

  // CDN 은 query 가 하나라도 붙으면 리사이저를 거치고, 새 변형의 첫 요청은
  // 수 초 느리다(2026-09-19 실측). 기기마다 다른 w 는 변형을 기기 수만큼
  // 쪼개 모든 사용자가 콜드를 맞게 하므로, 변형은 용도별 상수 하나다. 용도를
  // 고르지 않으면 썸네일 변형이다. 레이아웃·DPR 은 로컬 디코드 크기에만 쓴다.
  testWidgets(
    'omitted variant requests the thumbnail variant on every device',
    (tester) async {
      final urls = <String>{};
      final decodeWidths = <double, int>{};
      for (final device in _devices) {
        final context = await _pumpContext(
          tester,
          size: device.size,
          devicePixelRatio: device.devicePixelRatio,
        );

        final request = PicnicImageRequest.resolve(
          context: context,
          imageUrl: '/images/hero.jpg?stale=1',
          width: 320,
          height: 180,
        );

        urls.add(request.url);
        decodeWidths[device.devicePixelRatio] = request.decodeWidth;
      }

      expect(urls, {'https://test-cdn.example.com/images/hero.jpg?q=80&w=500'});
      // 로컬 디코드 보호는 그대로 기기 해상도를 따른다.
      expect(decodeWidths, {1.0: 384, 2.0: 768, 3.0: 800, 3.5: 800});
    },
  );

  testWidgets('variant URL ignores layout size, DPR, and resolution cap', (
    tester,
  ) async {
    final urlsByWidth = <int, Set<String>>{};
    for (final device in _devices) {
      final context = await _pumpContext(
        tester,
        size: device.size,
        devicePixelRatio: device.devicePixelRatio,
      );
      for (final variant in _sharedVariants) {
        for (final logical in const [24.0, 72.0, 390.0]) {
          for (final cap in const [null, 1.0]) {
            final request = PicnicImageRequest.resolve(
              context: context,
              imageUrl: 'https://test-cdn.example.com/artist/1.png?fit=cover',
              width: logical,
              height: logical,
              maxResolutionMultiplierCap: cap,
              cdnVariant: variant,
            );
            urlsByWidth.putIfAbsent(variant.width, () => {}).add(request.url);
          }
        }
      }
    }

    expect(urlsByWidth, {
      180: {'https://test-cdn.example.com/artist/1.png?q=85&w=180'},
      500: {'https://test-cdn.example.com/artist/1.png?q=80&w=500'},
      1000: {'https://test-cdn.example.com/artist/1.png?q=80&w=1000'},
      1600: {'https://test-cdn.example.com/artist/1.png?q=80&w=1600'},
    });
  });

  testWidgets('every variant keeps signed external URLs verbatim', (
    tester,
  ) async {
    final context = await _pumpContext(tester, devicePixelRatio: 3);
    const signedUrl =
        'https://external.example.com/photo.png?signature=a%2Bb&expires=9';

    final urls = [
      PicnicImageRequest.resolve(
        context: context,
        imageUrl: signedUrl,
        width: 72,
        height: 72,
      ).url,
      for (final variant in _sharedVariants)
        PicnicImageRequest.resolve(
          context: context,
          imageUrl: signedUrl,
          width: 72,
          height: 72,
          cdnVariant: variant,
        ).url,
    ];

    expect(urls, everyElement(signedUrl));
  });

  testWidgets(
    'missing or invalid axes keep the default variant and safe decode',
    (tester) async {
      final context = await _pumpContext(tester, devicePixelRatio: double.nan);

      final request = PicnicImageRequest.resolve(
        context: context,
        imageUrl: '/images/unknown.png',
        width: double.nan,
        height: -20,
        maxResolutionMultiplierCap: double.nan,
      );

      expect(
        request.url,
        'https://test-cdn.example.com/images/unknown.png?q=80&w=500',
      );
      expect(request.decodeWidth, 400);
      expect(request.decodeHeight, 400);
    },
  );

  testWidgets('fixed variant still caps decode to the requested width', (
    tester,
  ) async {
    final context = await _pumpContext(tester, devicePixelRatio: 3);

    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/reward/1.png',
      width: 1000,
      maxResolutionMultiplierCap: 1,
      cdnVariant: PicnicCdnImageVariant.large,
    );

    expect(
      request.url,
      'https://test-cdn.example.com/reward/1.png?q=80&w=1000',
    );
    expect(request.decodeWidth, 1000);
    expect(request.decodeHeight, 2000);
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

    expect(capped.decodeWidth, 50);
    expect(invalidCap.decodeWidth, 250);
  });

  testWidgets('two decode axes are proportionally capped at two megapixels', (
    tester,
  ) async {
    final context = await _pumpContext(tester);

    final request = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/large.jpg',
      width: 2000,
      height: 2000,
    );

    expect(request.decodeWidth, 1414);
    expect(request.decodeHeight, 1414);
    expect(
      request.decodeWidth * request.decodeHeight,
      lessThanOrEqualTo(2000000),
    );
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

      expect(fixed.decodeWidth, 78);
      expect(fixed.decodeHeight, 78);
      expect(mixed.decodeWidth, 1800);
      expect(mixed.decodeHeight, 1111);
    },
  );

  testWidgets('GIF sources keep q80 while other sources keep variant q', (
    tester,
  ) async {
    final context = await _pumpContext(tester);
    const variant = PicnicCdnImageVariant(width: 78, quality: 55);
    const gifUrl = 'https://test-cdn.example.com/animation.gif?token=old';

    final gif = PicnicImageRequest.resolve(
      context: context,
      imageUrl: gifUrl,
      width: 39,
      height: 39,
      cdnVariant: variant,
    );
    final defaultGif = PicnicImageRequest.resolve(
      context: context,
      imageUrl: gifUrl,
      width: 39,
      height: 39,
    );
    final avatarGif = PicnicImageRequest.resolve(
      context: context,
      imageUrl: gifUrl,
      width: 39,
      height: 39,
      cdnVariant: PicnicCdnImageVariant.avatar,
    );
    final low = PicnicImageRequest.resolve(
      context: context,
      imageUrl: '/images/low.jpg',
      width: 39,
      height: 39,
      cdnVariant: variant,
    );

    expect(Uri.parse(gif.url).queryParameters, {'q': '80', 'w': '78'});
    expect(
      defaultGif.url,
      'https://test-cdn.example.com/animation.gif?q=80&w=500',
    );
    expect(
      avatarGif.url,
      'https://test-cdn.example.com/animation.gif?q=80&w=180',
    );
    expect(Uri.parse(low.url).queryParameters, {'q': '55', 'w': '78'});
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

const _sharedVariants = [
  PicnicCdnImageVariant.avatar,
  PicnicCdnImageVariant.thumbnail,
  PicnicCdnImageVariant.large,
  PicnicCdnImageVariant.fullscreen,
];

/// Phone, small phone, and tablet layouts across the DPR range.
const _devices = [
  MediaQueryData(size: Size(393, 852), devicePixelRatio: 1),
  MediaQueryData(size: Size(360, 780), devicePixelRatio: 2),
  MediaQueryData(size: Size(393, 852), devicePixelRatio: 3),
  MediaQueryData(size: Size(1024, 1366), devicePixelRatio: 3.5),
];

Future<BuildContext> _pumpContext(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  double devicePixelRatio = 1,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: devicePixelRatio),
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
