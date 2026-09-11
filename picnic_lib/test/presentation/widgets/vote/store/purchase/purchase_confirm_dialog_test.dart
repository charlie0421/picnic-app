import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_confirm_dialog.dart';

import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

const Map<String, dynamic> star100 = {
  'id': 'STAR100',
  'price': 1.99,
  'star_candy': 100,
  'star_candy_bonus': 0,
  'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
};

const Map<String, dynamic> star200 = {
  'id': 'STAR200',
  'price': 3.99,
  'star_candy': 200,
  'star_candy_bonus': 25,
  'description': {'ko': '스타 캔디 200개 + 보너스 25개', 'en': '200 + 25 bonus'},
};

const doubleCampaign = (
  displayName: {'ko': '내부 캠페인 이름', 'en': 'Internal campaign name'},
  code: 'CANDY_BOOST_DAY',
  multiplierTenths: 20,
  extraBonusBps: null,
);

const fractionalLegacyCampaign = (
  displayName: {'ko': '캔디 부스트 데이', 'en': 'Candy Boost Day'},
  code: 'CANDY_BOOST_DAY',
  multiplierTenths: null,
  extraBonusBps: 1500,
);

/// Widget tests run on the host (non-Android), where the shared product ID
/// policy applies the configured test iOS prefix.
final storeStar200 = ProductDetails(
  id: 'testSTAR200',
  title: 'Star Candy 200',
  description: '200 Star Candies',
  price: 'US\$3.99',
  rawPrice: 3.99,
  currencyCode: 'USD',
);

final walletBeforePurchase = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(1000),
  bonus: BigInt.from(500),
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026),
);

void main() {
  bool? confirmed;

  setUp(() {
    initTestColors();
    confirmed = null;
  });

  Future<void> openConfirmation(
    WidgetTester tester, {
    required Map<String, dynamic> product,
    ResolvedPaymentBadgePromotion? promotion,
    List<ProductDetails> storeProducts = const <ProductDetails>[],
    Locale locale = const Locale('ko'),
    TextScaler? textScaler,
    WalletSummaryModel? currentWallet,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => PurchaseConfirmDialog(
                  serverProduct: product,
                  storeProducts: storeProducts,
                  displayedPromotion: promotion,
                  currentWallet: currentWallet,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
        locale: locale,
        textScaler: textScaler,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('quotes star candy and bonus star candy separately for STAR100', (
    tester,
  ) async {
    await openConfirmation(tester, product: star100, promotion: doubleCampaign);

    expect(tester.takeException(), isNull);
    expect(find.text('스타캔디'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('보너스 스타캔디'), findsOneWidget);
    expect(find.text('합계 100'), findsOneWidget);
    expect(find.text('이벤트 100'), findsOneWidget);
    expect(find.text('예상 합계'), findsNothing);
    expect(find.text('200'), findsNothing);
    // STAR100 has no catalog bonus, so that row is omitted entirely.
    expect(find.text('기본 보너스'), findsNothing);
  });

  testWidgets('shows current and expected post-purchase balances per wallet', (
    tester,
  ) async {
    await openConfirmation(
      tester,
      product: star200,
      promotion: doubleCampaign,
      currentWallet: walletBeforePurchase,
    );

    expect(find.text('현재 잔액 1,000'), findsOneWidget);
    expect(find.text('구매 후 예상 1,200'), findsOneWidget);
    expect(find.text('현재 잔액 500'), findsOneWidget);
    expect(find.text('구매 후 예상 750'), findsOneWidget);

    for (final key in const [
      Key('purchase-confirm-star-balance'),
      Key('purchase-confirm-bonus-balance'),
    ]) {
      final projection = find.descendant(
        of: find.byKey(key),
        matching: find.byType(FittedBox),
      );
      expect(
        tester.widget<FittedBox>(projection).alignment,
        AlignmentDirectional.centerStart,
      );
    }

    final starAmountRight = tester.getTopRight(find.text('200')).dx;
    final bonusAmountRight = tester
        .getTopRight(find.byKey(const Key('purchase-confirm-bonus-total')))
        .dx;
    expect(starAmountRight, closeTo(bonusAmountRight, 0.5));
  });

  testWidgets('splits catalog bonus from event bonus for STAR200', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openConfirmation(tester, product: star200, promotion: doubleCampaign);

    expect(find.text('200'), findsOneWidget);
    expect(find.text('기본 25'), findsOneWidget);
    expect(find.text('이벤트 225'), findsOneWidget);
    expect(find.text('보너스 스타캔디'), findsOneWidget);
    expect(find.text('합계 250'), findsOneWidget);
    expect(find.text('450'), findsNothing);
    final baseCapsule = tester.widget<Container>(
      find.byKey(const Key('purchase-confirm-product-bonus')),
    );
    final eventCapsule = tester.widget<Container>(
      find.byKey(const Key('purchase-confirm-event-bonus')),
    );
    final baseDecoration = baseCapsule.decoration! as BoxDecoration;
    final eventDecoration = eventCapsule.decoration! as BoxDecoration;
    expect(baseCapsule.padding, eventCapsule.padding);
    expect(baseDecoration.borderRadius, eventDecoration.borderRadius);
    expect(baseDecoration.border, isA<Border>());
    expect(eventDecoration.border, isA<Border>());
    expect(
      (baseDecoration.border! as Border).top.width,
      (eventDecoration.border! as Border).top.width,
    );
    expect(find.byKey(const Key('purchase-confirm-hero')), findsOneWidget);
    final hero = tester.widget<Container>(
      find.byKey(const Key('purchase-confirm-hero')),
    );
    final heroDecoration = hero.decoration! as BoxDecoration;
    expect(heroDecoration.gradient, isNull);
    expect(heroDecoration.boxShadow, isNull);
    expect(
      find.byKey(const Key('purchase-confirm-star-candy-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('purchase-confirm-bonus-benefit-panel')),
      findsOneWidget,
    );
    final bonusPanel = tester.widget<Container>(
      find.byKey(const Key('purchase-confirm-bonus-benefit-panel')),
    );
    final bonusDecoration = bonusPanel.decoration! as BoxDecoration;
    expect(bonusDecoration.gradient, isNull);
    expect(bonusDecoration.boxShadow, isNull);
    expect(find.byKey(const Key('purchase-confirm-cta')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('purchase-confirm-cta'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('labels the amounts an estimate the server will confirm', (
    tester,
  ) async {
    await openConfirmation(tester, product: star200, promotion: doubleCampaign);

    expect(
      find.byKey(const Key('purchase-confirm-estimate-info')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the event hero when a legacy rate has no exact pill', (
    tester,
  ) async {
    await openConfirmation(
      tester,
      product: star200,
      promotion: fractionalLegacyCampaign,
    );

    expect(find.byKey(const Key('purchase-confirm-hero')), findsOneWidget);
    expect(find.text('캔디 부스트 데이'), findsOneWidget);
    expect(find.text('이벤트 33'), findsOneWidget);
  });

  testWidgets('shows no event row and no pill without a campaign', (
    tester,
  ) async {
    await openConfirmation(tester, product: star200);

    expect(find.text('이벤트 보너스'), findsNothing);
    expect(find.byKey(const Key('purchase-confirm-event-bonus')), findsNothing);
    expect(find.text('총 2배'), findsNothing);
    expect(find.text('보너스 스타캔디'), findsOneWidget);
    expect(find.text('합계 25'), findsNothing);
    expect(
      find.byKey(const Key('purchase-confirm-product-bonus')),
      findsNothing,
    );
    expect(find.text('25'), findsOneWidget);
    expect(find.text('225'), findsNothing);
  });

  testWidgets('prefers the matching store product localized price', (
    tester,
  ) async {
    await openConfirmation(
      tester,
      product: star200,
      storeProducts: [storeStar200],
    );

    expect(find.text('US\$3.99'), findsOneWidget);
    expect(find.text('3.99 \$'), findsNothing);
  });

  testWidgets('falls back to the catalog price when the store has no match', (
    tester,
  ) async {
    await openConfirmation(tester, product: star200);

    expect(find.text('3.99 \$'), findsOneWidget);
  });

  testWidgets('keeps cancel and confirm usable on a tiny viewport at 2x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openConfirmation(
      tester,
      product: star200,
      promotion: doubleCampaign,
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    // The breakdown is reachable by scrolling the dialog body...
    await tester.scrollUntilVisible(find.text('보너스 스타캔디'), 60);
    expect(find.text('합계 250'), findsOneWidget);
    expect(find.text('450'), findsNothing);
    // ...and the decision buttons never scroll away with it.
    await tester.tap(find.text('구매'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    await openConfirmation(tester, product: star100, promotion: doubleCampaign);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
  });
}
