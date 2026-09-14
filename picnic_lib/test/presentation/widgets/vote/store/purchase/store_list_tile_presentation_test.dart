import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  for (final scale in [1.0, 2.0]) {
    testWidgets('store price is readable and actionable at 320px/$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var purchases = 0;
      Widget app(bool busy) => buildTestApp(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StoreListTile(
                icon: Image.asset(
                  'assets/icons/store/currency_bonus_star_candy.png',
                  package: 'picnic_lib',
                  width: 48,
                  height: 48,
                ),
                title: Text(
                  'STAR CANDY 100000',
                  style: PicnicUi.text(size: 16, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  '보너스 스타캔디를 포함한 구매 보상',
                  style: PicnicUi.text(size: 12),
                ),
                buttonText: 'CHF 1’234.50',
                buttonOnPressed: () => purchases++,
                isLoading: busy,
                flexibleHeight: true,
              ),
            ),
          ),
        ),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(scale),
      );
      final button = find.byWidgetPredicate((w) => w is ButtonStyleButton);
      await tester.pumpWidget(app(false));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bounds = tester.getRect(button);
      expect(bounds.height, greaterThanOrEqualTo(48));
      expect(bounds.left, greaterThanOrEqualTo(16));
      expect(bounds.right, lessThanOrEqualTo(304));
      expect(
        find.ancestor(
          of: find.text('CHF 1’234.50'),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      await tester.tap(button);
      expect(purchases, 1);
      await tester.pumpWidget(app(true));
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      expect(purchases, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
