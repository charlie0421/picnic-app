import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';
import 'common_banner_render_test.dart' show MutableBannerList, ordinaryBanner;

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({'banner': <dynamic>[]});
    resetSuccessfullyLoadedImageUrlsForTest();
  });

  tearDown(tearDownMockSupabase);

  testWidgets('constrained banners reuse prepared decode keys across slides', (
    tester,
  ) async {
    final previousInterval =
        VisibilityDetectorController.instance.updateInterval;
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
    addTearDown(() {
      VisibilityDetectorController.instance.updateInterval = previousInterval;
    });
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    MutableBannerList.items = [
      for (var id = 1; id <= 3; id++) ordinaryBanner(id, 'Banner $id'),
    ];
    for (var id = 1; id <= 3; id++) {
      await tester.runAsync(
        () => harness.respondPng(
          'https://example.com/$id.jpg',
          width: 800,
          height: 400,
        ),
      );
    }
    await tester.pumpWidget(
      buildTestApp(
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 240, child: CommonBanner('pic_home', 2)),
        ),
        locale: const Locale('en'),
        extraOverrides: [
          asyncBannerListProvider.overrideWith(MutableBannerList.new),
        ],
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    // No simulated 500 ms visibility interval has elapsed.
    final banner = tester.widget<PicnicCachedNetworkImage>(
      find.byKey(const ValueKey('banner_1')),
    );
    expect(banner.width, 240);
    expect(banner.height, 120);
    expect(banner.memCacheWidth, isNull);
    final request = banner.imageRequest!;
    final context = tester.element(find.byKey(const ValueKey('banner_1')));
    final configuration = createLocalImageConfiguration(context);
    final key = await request.obtainKey(configuration);
    final completer = request.provider.resolve(configuration).completer;
    final raw = tester
        .widgetList<RawImage>(
          find.descendant(
            of: find.byKey(const ValueKey('banner_1')),
            matching: find.byType(RawImage),
          ),
        )
        .singleWhere((image) => image.image != null)
        .image!;
    expect(raw.width / raw.height, closeTo(2, .02));
    expect(raw.width, request.decodeWidth);
    expect(harness.requestsFor(request.url), 1);

    final swiper = tester.widget<Swiper>(find.byType(Swiper));
    unawaited(swiper.controller!.move(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    unawaited(swiper.controller!.move(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final returned = tester.widget<PicnicCachedNetworkImage>(
      find.byKey(const ValueKey('banner_1')),
    );
    expect(await returned.imageRequest!.obtainKey(configuration), key);
    expect(
      returned.imageRequest!.provider.resolve(configuration).completer,
      same(completer),
    );
    expect(harness.requestsFor(request.url), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
