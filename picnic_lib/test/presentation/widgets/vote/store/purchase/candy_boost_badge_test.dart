import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  testWidgets('renders localized campaign and exact-double copy on two lines', (
    tester,
  ) async {
    initTestColors();
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
        CandyBoostBadge(campaign: envelope.items.single),
        locale: const Locale('en', 'US'),
      ),
    );
    expect(find.text('Candy Boost Day'), findsOneWidget);
    expect(find.text('Base reward + 100% extra bonus'), findsOneWidget);
  });
}
