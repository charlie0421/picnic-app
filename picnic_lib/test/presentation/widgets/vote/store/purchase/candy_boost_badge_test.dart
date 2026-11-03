import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview_view.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  group('CandyBoostBadge', () {
    testWidgets('describes a doubled campaign as 100 percent event bonus', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const CandyBoostBadge(totalMultiplierTenths: 20)),
      );

      expect(find.text('+100%'), findsOneWidget);
      final decorated = tester.widget<Container>(
        find.descendant(
          of: find.byType(CandyBoostBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = decorated.decoration! as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.border, isNotNull);
    });

    testWidgets('describes the event bonus percentage in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const CandyBoostBadge(totalMultiplierTenths: 20),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('+100%'), findsOneWidget);
    });

    testWidgets('keeps a fractional multiplier exact', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const CandyBoostBadge(totalMultiplierTenths: 15)),
      );

      expect(find.text('+50%'), findsOneWidget);
    });

    testWidgets('stays inside a narrow slot at 2x text scale', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const SizedBox(
              width: 72,
              child: CandyBoostBadge(totalMultiplierTenths: 30),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CandyBoostBadge)).width,
        lessThanOrEqualTo(72),
      );
    });

    test(
      'formatCandyBoostBonusPercent converts total tenths to bonus percent',
      () {
        expect(formatCandyBoostBonusPercent(20), '100');
        expect(formatCandyBoostBonusPercent(15), '50');
        expect(formatCandyBoostBonusPercent(21), '110');
        expect(formatCandyBoostBonusPercent(11), '10');
      },
    );
  });

  group('PurchaseRewardPreviewView', () {
    Widget view(PurchaseRewardPreview preview, {double width = 220}) =>
        SizedBox(
          width: width,
          child: PurchaseRewardPreviewView(preview: preview),
        );

    testWidgets('keeps star candy and bonus star candy separate', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          view(
            PurchaseRewardPreview(
              base: BigInt.from(200),
              productBonus: BigInt.from(25),
              multiplierTenths: 20,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('purchase-star-candy-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('purchase-bonus-components')),
        findsOneWidget,
      );
      expect(find.text('200'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('이벤트 225'), findsOneWidget);
      expect(find.text('450'), findsNothing);
      expect(
        find.byKey(const Key('purchase-provenance-chip-product')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('purchase-provenance-chip-event')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('purchase-expected-total')), findsNothing);
    });

    testWidgets(
      'emphasizes the bonus wallet amount without merging currencies',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            view(
              PurchaseRewardPreview(
                base: BigInt.from(200),
                productBonus: BigInt.from(25),
                multiplierTenths: 20,
              ),
            ),
          ),
        );

        final total = tester.widget<Text>(
          find.byKey(const Key('purchase-provenance-chip-event')),
        );
        final catalog = tester.widget<Text>(
          find.byKey(const Key('purchase-star-candy-panel')),
        );
        expect(total.style!.color, catalog.style!.color);
      },
    );

    testWidgets('keeps the largest catalog bonus amount fully visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          view(
            PurchaseRewardPreview(
              base: BigInt.from(10000),
              productBonus: BigInt.from(2100),
              multiplierTenths: 20,
            ),
            width: 340,
          ),
        ),
      );

      final amount = find.text('이벤트 12,100');
      expect(amount, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(amount);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(boxes.last.right, lessThanOrEqualTo(paragraph.size.width + 1));
    });

    testWidgets('falls back to the plain catalog line with no campaign', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          view(
            PurchaseRewardPreview(
              base: BigInt.from(200),
              productBonus: BigInt.from(25),
            ),
          ),
        ),
      );

      expect(find.text('200'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byKey(const Key('purchase-expected-total')), findsNothing);
      expect(find.byKey(const Key('purchase-event-bonus')), findsNothing);
    });

    testWidgets('wraps instead of overflowing at 320dp and 2x text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: view(
              PurchaseRewardPreview(
                base: BigInt.from(200),
                productBonus: BigInt.from(25),
                multiplierTenths: 20,
              ),
              width: 160,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
