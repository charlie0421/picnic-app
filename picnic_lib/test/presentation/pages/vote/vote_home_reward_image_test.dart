import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/image_test_harness.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    initTestColors();
  });
  tearDown(tearDownMockSupabase);

  for (final dpr in [2.0, 3.0]) {
    testWidgets('home reward decodes at display resolution for DPR $dpr', (
      tester,
    ) async {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = Size(393 * dpr, 852 * dpr);
      addTearDown(tester.view.reset);
      const url = 'https://images.example.com/reward.png';
      setupMockSupabase({
        'vote': <dynamic>[],
        'pic_vote': <dynamic>[],
        'banner': <dynamic>[],
        'reward': [
          {
            'id': 901,
            'title': {'ko': '리워드'},
            'thumbnail': url,
            'overview_images': null,
            'location': null,
            'size_guide': null,
            'size_guide_images': null,
          },
        ],
      });
      final harness = await ImageTestHarness.create();
      addTearDown(harness.dispose);
      await tester.runAsync(
        () => harness.respondPng(
          url,
          width: 600,
          height: 500,
          color: const Color(0xffff8000),
        ),
      );
      await tester.pumpWidget(buildTestAppPage(const VoteHomePage()));
      final rawFinder = find.descendant(
        of: find.byKey(const ValueKey('reward_901')),
        matching: find.byType(RawImage),
      );
      for (var frame = 0; frame < 100; frame++) {
        if (tester
            .widgetList<RawImage>(rawFinder)
            .any((r) => r.image != null)) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)),
        );
        await tester.pump();
      }
      final context = tester.element(find.byKey(const ValueKey('reward_901')));
      final expected = PicnicImageRequest.resolve(
        context: context,
        imageUrl: url,
        width: 120,
        height: 100,
      );
      final decoded = tester
          .widgetList<RawImage>(rawFinder)
          .singleWhere((raw) => raw.image != null)
          .image!;
      expect(decoded.width, expected.decodeWidth);
      expect(decoded.height, expected.decodeHeight);
      expect(decoded.width, greaterThan(120 * 1.8));
      expect(decoded.width / decoded.height, closeTo(1.2, .02));
      expect(harness.requestsFor(url), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
