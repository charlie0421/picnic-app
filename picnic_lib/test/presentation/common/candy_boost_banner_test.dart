import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/common/candy_boost_banner.dart';
import '../../helpers/ignore_image_errors.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  testWidgets('uses requested locale and left-aligned title', (tester) async {
    initTestColors();
    final restore = suppressImageErrors();
    addTearDown(restore);
    final envelope = ActivePromotionCampaignsModel.fromJson(
      jsonDecode(
            File(
              'test/fixtures/wallet_contracts/promotion_surfaces_active_v1.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    await tester.pumpWidget(
      buildTestApp(
        CandyBoostBanner(campaign: envelope.items.single),
        locale: const Locale('en', 'US'),
      ),
    );
    await tester.pump();
    final text = tester.widget<Text>(find.text('Candy Boost Day'));
    expect(text.textAlign, TextAlign.left);
    expect(
      tester
          .widget<Align>(
            find
                .ancestor(
                  of: find.text('Candy Boost Day'),
                  matching: find.byType(Align),
                )
                .first,
          )
          .alignment,
      Alignment.centerLeft,
    );
  });
}
