import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/load_test_fonts.dart';

Map<String, dynamic> loadGoldenFixture(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

final activeCampaignFixture = ActivePromotionCampaignsModel.fromJson(
  loadGoldenFixture(
    'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
  ),
).visibleHomeItems('ko').single;

Widget buildCampaignGoldenApp(ActivePromotionCampaignModel campaign) =>
    MaterialApp(
      theme: ThemeData(fontFamily: 'packages/picnic_lib/Pretendard'),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SizedBox(
        height: 200,
        child: ColoredBox(
          color: const Color(0xFFFF7FA8),
          child: CandyBoostBanner(campaign: campaign),
        ),
      ),
    );

void main() {
  late Duration originalVisibilityInterval;

  setUpAll(() async {
    await loadTestFonts();
    originalVisibilityInterval =
        VisibilityDetectorController.instance.updateInterval;
    VisibilityDetectorController.instance.updateInterval =
        const Duration(hours: 1);
  });

  tearDownAll(() {
    VisibilityDetectorController.instance.updateInterval =
        originalVisibilityInterval;
  });

  testWidgets('left-aligned candy boost banner golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildCampaignGoldenApp(activeCampaignFixture));
    final title = tester.widget<Text>(find.text('캔디 부스트 데이'));
    expect(title.textAlign, TextAlign.left);
    await expectLater(
      find.byType(CandyBoostBanner),
      matchesGoldenFile('../../goldens/candy_boost_banner.png'),
    );
  });
}
