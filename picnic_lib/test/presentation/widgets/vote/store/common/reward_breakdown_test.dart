import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/reward_breakdown.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/test_environment.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/load_test_fonts.dart';

Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  testWidgets('renders base and bonus amounts with icons', (tester) async {
    await tester.pumpWidget(
      testApp(const RewardBreakdown(baseAmount: 200, bonusAmount: 25)),
    );

    expect(find.text('200'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('+'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('hides bonus section when amount is zero', (tester) async {
    await tester.pumpWidget(
      testApp(const RewardBreakdown(baseAmount: 100, bonusAmount: 0)),
    );

    expect(find.text('100'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('+'),
      ),
      findsNothing,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('purchase row visual capture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 220));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildTestApp(
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

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../../../../../goldens/purchase_reward_breakdown.png'),
    );
  });

  testWidgets('purchase screen full visual capture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildTestApp(
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

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../../../../../goldens/purchase_reward_breakdown_fullscreen.png',
      ),
    );
  });
}
