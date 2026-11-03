import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';

import '../../helpers/image_test_harness.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_environment.dart';

Map<String, dynamic> loadGoldenFixture(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

final activeCampaignFixture = ActivePromotionCampaignsModel.fromJson(
  loadGoldenFixture(
    'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
  ),
).visibleHomeItems('ko').single.homeCreative!;

Widget buildCampaignGoldenApp(PromotionCreativeModel creative) => MaterialApp(
  theme: ThemeData(fontFamily: 'packages/picnic_lib/Pretendard'),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: SizedBox(
    height: 200,
    child: ColoredBox(
      color: const Color(0xFFFF7FA8),
      child: CandyBoostBanner(creative: creative),
    ),
  ),
);

void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  testWidgets('left-aligned candy boost banner golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await ImageTestHarness.create();
    addTearDown(harness.dispose);
    // Hold bytes so the existing golden continues to verify the loading
    // surface, even though campaign images now start loading immediately.
    await tester.runAsync(
      () => harness.respondPng(
        activeCampaignFixture.localizedImage('ko')!,
        held: true,
      ),
    );
    await tester.pumpWidget(buildCampaignGoldenApp(activeCampaignFixture));
    final title = tester.widget<Text>(find.text('캔디 부스트 데이'));
    expect(title.textAlign, TextAlign.left);
    await expectLater(
      find.byType(CandyBoostBanner),
      matchesGoldenFile('../../goldens/candy_boost_banner.png'),
    );
    harness.release(activeCampaignFixture.localizedImage('ko')!);
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
