import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/avatar_url_resolver.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('resolveAvatarImageUrl', () {
    test('returns empty string for null', () {
      expect(resolveAvatarImageUrl(null), '');
    });

    test('returns empty string for empty string', () {
      expect(resolveAvatarImageUrl(''), '');
    });

    test('returns empty string for whitespace only', () {
      expect(resolveAvatarImageUrl('   '), '');
    });

    test('trims whitespace from URLs', () {
      expect(
        resolveAvatarImageUrl('  https://example.com/img.png  '),
        'https://example.com/img.png',
      );
    });

    test('prepends https: for scheme-less URLs', () {
      expect(
        resolveAvatarImageUrl('//example.com/img.png'),
        'https://example.com/img.png',
      );
    });

    test('returns http URLs as-is', () {
      expect(
        resolveAvatarImageUrl('http://example.com/img.png'),
        'http://example.com/img.png',
      );
    });

    test('returns https URLs as-is', () {
      expect(
        resolveAvatarImageUrl('https://example.com/img.png'),
        'https://example.com/img.png',
      );
    });

    test('returns non-http URLs as-is', () {
      expect(
        resolveAvatarImageUrl('file:///local/path.png'),
        'file:///local/path.png',
      );
    });
  });

  group('ProfileImageContainer widget', () {
    test('can be constructed with required parameters', () {
      const widget = ProfileImageContainer(
        avatarUrl: 'https://example.com/avatar.png',
        borderRadius: 20,
        width: 40,
        height: 40,
      );
      expect(widget, isA<ProfileImageContainer>());
      expect(widget.avatarUrl, 'https://example.com/avatar.png');
      expect(widget.borderRadius, 20);
      expect(widget.width, 40);
      expect(widget.height, 40);
    });

    test('can be constructed with null avatarUrl', () {
      const widget = ProfileImageContainer(
        avatarUrl: null,
        borderRadius: 10,
        width: 36,
        height: 36,
      );
      expect(widget.avatarUrl, isNull);
    });

    test('can be constructed with optional border', () {
      final widget = ProfileImageContainer(
        avatarUrl: 'https://example.com/avatar.png',
        borderRadius: 20,
        width: 40,
        height: 40,
        border: Border.all(color: Colors.red),
      );
      expect(widget.border, isNotNull);
    });

    testWidgets('renders with null avatarUrl', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ProfileImageContainer(
            avatarUrl: null,
            borderRadius: 20,
            width: 40,
            height: 40,
          ),
        ),
      );
      await tester.pump();

      // Should show NoAvatar fallback
      expect(find.byType(ProfileImageContainer), findsOneWidget);
    });

    testWidgets('renders with empty avatarUrl', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ProfileImageContainer(
            avatarUrl: '',
            borderRadius: 20,
            width: 40,
            height: 40,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileImageContainer), findsOneWidget);
    });

    testWidgets('signed HTTP avatar keeps its URL and uses DPR-aware decode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final previousInterval =
          VisibilityDetectorController.instance.updateInterval;
      VisibilityDetectorController.instance.updateInterval = const Duration(
        milliseconds: 500,
      );
      addTearDown(() {
        VisibilityDetectorController.instance.updateInterval = previousInterval;
      });
      PicnicCachedNetworkImage.disableTimeoutForTest = true;
      addTearDown(() {
        PicnicCachedNetworkImage.disableTimeoutForTest = false;
      });
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      const signedUrl =
          'https://external.example.com/avatar.png?X-Amz-Signature=a%2Bb&expires=9';
      await tester.runAsync(
        () => harness.respondPng(
          signedUrl,
          width: 400,
          height: 200,
          color: const Color(0xffff00ff),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          const ProfileImageContainer(
            avatarUrl: signedUrl,
            borderRadius: 20,
            width: 40,
            height: 40,
          ),
        ),
      );
      await _pumpUntil(tester, () => harness.requestsFor(signedUrl) == 1);
      await _pumpUntil(
        tester,
        () => tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((raw) => raw.image != null),
      );

      final loader = tester.widget<PicnicCachedNetworkImage>(
        find.byType(PicnicCachedNetworkImage),
      );
      expect(loader.imageUrl, signedUrl);
      expect(loader.lazyLoadingStrategy, LazyLoadingStrategy.none);
      expect(loader.memCacheWidth, isNull);
      expect(loader.memCacheHeight, isNull);

      final loaderContext = tester.element(
        find.byType(PicnicCachedNetworkImage),
      );
      final expected = PicnicImageRequest.resolve(
        context: loaderContext,
        imageUrl: signedUrl,
        width: 40,
        height: 40,
      );
      expect(expected.url, signedUrl);
      expect(expected.decodeWidth, greaterThan(40));
      expect(expected.decodeHeight, greaterThan(40));
      final displayed = tester.widget<Image>(
        find.descendant(
          of: find.byType(PicnicCachedNetworkImage),
          matching: find.byType(Image),
        ),
      );
      final configuration = createLocalImageConfiguration(loaderContext);
      expect(
        await displayed.image.obtainKey(configuration),
        await expected.obtainKey(configuration),
      );
      final resize = displayed.image as ResizeImage;
      final network = resize.imageProvider as CachedNetworkImageProvider;
      expect(network.url, signedUrl);
      expect(network.cacheKey, signedUrl);

      final decoded = tester
          .widgetList<RawImage>(find.byType(RawImage))
          .singleWhere((raw) => raw.image != null)
          .image!;
      expect(decoded.width, expected.decodeWidth);
      expect(decoded.width / decoded.height, closeTo(2, 0.02));
      expect(await _centerRgba(tester, decoded), [255, 0, 255, 255]);
      expect(harness.requestsFor(signedUrl), 1);
    });

    for (final dpr in [2.0, 3.0]) {
      testWidgets(
        'relative avatar decodes at display resolution for DPR $dpr',
        (tester) async {
          resetSuccessfullyLoadedImageUrlsForTest();
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = Size(375 * dpr, 812 * dpr);
          addTearDown(tester.view.reset);
          final interval = VisibilityDetectorController.instance.updateInterval;
          VisibilityDetectorController.instance.updateInterval = const Duration(
            milliseconds: 500,
          );
          addTearDown(() {
            VisibilityDetectorController.instance.updateInterval = interval;
          });
          final harness = await ImageTestHarness.create();
          addTearDown(harness.dispose);
          await tester.pumpWidget(
            buildTestApp(
              const ProfileImageContainer(
                avatarUrl: 'avatars/relative.png',
                borderRadius: 24,
                width: 48,
                height: 48,
              ),
            ),
          );
          final context = tester.element(find.byType(ProfileImageContainer));
          final expected = PicnicImageRequest.resolve(
            context: context,
            imageUrl: 'avatars/relative.png',
            width: 48,
            height: 48,
          );
          await tester.runAsync(
            () => harness.respondPng(
              expected.url,
              width: 400,
              height: 400,
              color: const Color(0xff00ff00),
            ),
          );
          VisibilityDetectorController.instance.notifyNow();
          await tester.pump();
          await _pumpUntil(
            tester,
            () => tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((raw) => raw.image != null),
          );
          final decoded = tester
              .widgetList<RawImage>(find.byType(RawImage))
              .singleWhere((raw) => raw.image != null)
              .image!;
          expect(decoded.width, expected.decodeWidth);
          expect(decoded.height, expected.decodeHeight);
          expect(decoded.width, greaterThan(48 * 1.8));
          expect(await _centerRgba(tester, decoded), [0, 255, 0, 255]);
          expect(harness.requestsFor(expected.url), 1);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  });

  group('DefaultAvatar widget', () {
    test('can be const-constructed', () {
      const widget = DefaultAvatar();
      expect(widget, isA<DefaultAvatar>());
    });
  });

  group('NoAvatar widget', () {
    test('can be const-constructed', () {
      const widget = NoAvatar(width: 40, height: 40, borderRadius: 20);
      expect(widget, isA<NoAvatar>());
      expect(widget.width, 40);
      expect(widget.height, 40);
      expect(widget.borderRadius, 20);
    });
  });
}

Future<List<int>> _centerRgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (bytes == null) fail('Decoded avatar did not expose RGBA bytes.');
  final center = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      bytes.getUint8(center + channel),
  ];
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
