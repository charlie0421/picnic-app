import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/reward_breakdown.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/test_environment.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/picnic_ui_test_environment.dart';

Widget _visualApp(Widget child) => buildTestApp(
  DefaultTextStyle.merge(
    style: const TextStyle(fontFamily: 'packages/picnic_lib/Pretendard'),
    child: child,
  ),
);

void _useProductionPalette() {
  final colors = PicnicUiColorFixture.install(
    PicnicUiTestPalette.fromProductionConfig('picnic_app'),
  );
  addTearDown(colors.restore);
}

Future<void> _warmCaptureAssets(WidgetTester tester) async {
  // Inline image spans must be decoded before their first paragraph layout.
  await tester.pumpWidget(_visualApp(const SizedBox.shrink()));
  final context = tester.element(find.byType(Scaffold));
  await tester.runAsync(() async {
    for (final asset in [
      'currency_star_candy.png',
      'currency_bonus_star_candy.png',
    ]) {
      await precacheImage(
        AssetImage('assets/icons/store/$asset', package: 'picnic_lib'),
        context,
      );
    }
  });
}

Future<void> _prepareCapture(WidgetTester tester) async {
  // Asset decoding is asynchronous and may not schedule a frame until after
  // pumpAndSettle returns; cold and warm image caches must produce the same image.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  testWidgets('purchase row visual capture', (tester) async {
    _useProductionPalette();
    await tester.binding.setSurfaceSize(const Size(375, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _warmCaptureAssets(tester);
    await tester.pumpWidget(
      _visualApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StoreListTile(
                icon: Image.asset(
                  'assets/icons/store/currency_star_candy.png',
                  package: 'picnic_lib',
                  width: 48,
                  height: 48,
                ),
                title: const Text('STAR200'),
                subtitle: const RewardBreakdown(
                  baseAmount: 200,
                  bonusAmount: 25,
                ),
                buttonText: '\$1.99',
                buttonOnPressed: () {},
              ),
              const Divider(height: 24),
              StoreListTile(
                icon: Image.asset(
                  'assets/icons/store/currency_star_candy.png',
                  package: 'picnic_lib',
                  width: 48,
                  height: 48,
                ),
                title: const Text('STAR100'),
                subtitle: const RewardBreakdown(
                  baseAmount: 100,
                  bonusAmount: 0,
                ),
                buttonText: '\$0.99',
                buttonOnPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _prepareCapture(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../../../../../goldens/purchase_reward_breakdown.png'),
    );
  });

  testWidgets('purchase screen full visual capture', (tester) async {
    _useProductionPalette();
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _warmCaptureAssets(tester);
    await tester.pumpWidget(
      _visualApp(
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              color: Colors.white,
              child: const Text(
                '별사탕 구매',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/store/currency_star_candy.png',
                            package: 'picnic_lib',
                            width: 44,
                            height: 44,
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('별사탕 파우치'),
                              SizedBox(height: 4),
                              Text('보유 별사탕을 확인하세요'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StoreListTile(
                      icon: Image.asset(
                        'assets/icons/store/currency_star_candy.png',
                        package: 'picnic_lib',
                        width: 48,
                        height: 48,
                      ),
                      title: const Text('STAR200'),
                      subtitle: const RewardBreakdown(
                        baseAmount: 200,
                        bonusAmount: 25,
                      ),
                      buttonText: '\$1.99',
                      buttonOnPressed: () {},
                    ),
                    const Divider(height: 24),
                    StoreListTile(
                      icon: Image.asset(
                        'assets/icons/store/currency_star_candy.png',
                        package: 'picnic_lib',
                        width: 48,
                        height: 48,
                      ),
                      title: const Text('STAR100'),
                      subtitle: const RewardBreakdown(
                        baseAmount: 100,
                        bonusAmount: 0,
                      ),
                      buttonText: '\$0.99',
                      buttonOnPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _prepareCapture(tester);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../../../../../goldens/purchase_reward_breakdown_fullscreen.png',
      ),
    );
  });
}
