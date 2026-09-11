import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_reward_preview_view.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/mock_supabase.dart';
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
  'description': {'ko': '스타 캔디 200개', 'en': '200 Star Candies'},
};

const Map<String, dynamic> star777 = {
  'id': 'STAR777',
  'price': 7.77,
  'star_candy': 777,
  'star_candy_bonus': 0,
  'description': {'ko': '스타 캔디 777개', 'en': '777 Star Candies'},
};

/// Widget tests run on the host (non-Android), where the configured test iOS
/// prefix is part of the effective store product ID.
final localizedStoreStar200 = ProductDetails(
  id: 'testSTAR200',
  title: 'Star Candy 200',
  description: '200 Star Candies',
  price: '₩5,500',
  rawPrice: 5500,
  currencyCode: 'KRW',
);

final unregisteredStoreStar777 = ProductDetails(
  id: 'testSTAR777',
  title: 'Star Candy 777',
  description: '777 Star Candies',
  price: 'US\$7.77',
  rawPrice: 7.77,
  currencyCode: 'USD',
);

/// A campaign whose own display name is internal copy long enough to break a
/// product row - exactly what must never be repeated per row.
const doubleCampaign = (
  displayName: {
    'ko': '내부 테스트 캔디 부스트 캠페인 이름',
    'en': 'Super Long Candy Boost Campaign Name That Must Not Break A Row',
  },
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

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({
      'products': [star100, star200],
    });
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpStore(
    WidgetTester tester, {
    required FutureOr<ResolvedPaymentBadgePromotion?> Function() promotion,
    PaymentBadgePromotionPeriod? promotionPeriod,
    Locale locale = const Locale('ko'),
    List<Map<String, dynamic>> serverProducts = const [star100, star200],
    List<ProductDetails> storeProducts = const <ProductDetails>[],
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        const PurchaseStarCandy(),
        locale: locale,
        // Layout-sensitive assertions have to be measured at the real app
        // geometry, per the harness guidance.
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        extraOverrides: [
          serverProductsProvider.overrideWithBuild(
            (ref, notifier) => serverProducts,
          ),
          storeProductsProvider.overrideWithBuild(
            (ref, notifier) => storeProducts,
          ),
          paymentBadgePromotionProvider.overrideWith((ref) => promotion()),
          paymentBadgePromotionPeriodProvider.overrideWith(
            (ref) async => promotionPeriod,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets(
    'uses a matching store-localized price and keeps the server USD fallback',
    (tester) async {
      await pumpStore(
        tester,
        promotion: () => null,
        storeProducts: [localizedStoreStar200],
      );

      final star200Tile = find.byType(StoreListTile).at(1);
      expect(
        find.descendant(of: star200Tile, matching: find.text('₩5,500')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: star200Tile, matching: find.text('3.99 \$')),
        findsNothing,
      );
      final star100Tile = find.byType(StoreListTile).at(0);
      expect(
        find.descendant(of: star100Tile, matching: find.text('1.99 \$')),
        findsOneWidget,
      );
      final purchaseButton = find.descendant(
        of: star200Tile,
        matching: find.byType(ElevatedButton),
      );
      expect(
        tester.widget<ElevatedButton>(purchaseButton).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('falls back to the generic star candy icon for an unknown SKU', (
    tester,
  ) async {
    await pumpStore(
      tester,
      promotion: () => null,
      serverProducts: const [star777],
      storeProducts: [unregisteredStoreStar777],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final fallback = find.byKey(
      const Key('purchase-product-image-fallback-STAR777'),
    );
    expect(fallback, findsOneWidget);
    final image = tester.widget<Image>(fallback).image;
    expect(image, isA<AssetImage>());
    expect(
      (image as AssetImage).assetName,
      'assets/icons/store/currency_star_candy.png',
    );
  });

  testWidgets('keeps each product star and bonus balances separate', (
    tester,
  ) async {
    await pumpStore(tester, promotion: () => doubleCampaign);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('candy-boost-purchase-card')), findsNothing);
    expect(find.byKey(const Key('candy-boost-promo-ribbon')), findsNothing);
    expect(find.byKey(const Key('candy-boost-inline-badge')), findsNWidgets(2));
    expect(
      find.byKey(const Key('purchase-reward-extension')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('purchase-star-candy-panel')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('purchase-bonus-components')),
      findsNWidgets(2),
    );

    final star100Tile = find.byType(StoreListTile).at(0);
    expect(
      find.descendant(
        of: star100Tile,
        matching: find.byKey(const Key('purchase-bonus-components')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: star100Tile, matching: find.text('200')),
      findsNothing,
    );
    expect(
      find.descendant(of: star100Tile, matching: find.text('100')),
      findsOneWidget,
    );

    // 200 + 25 = 225 catalog candy, doubled to 450.
    final star200Tile = find.byType(StoreListTile).at(1);
    expect(
      find.descendant(of: star200Tile, matching: find.text('이벤트 225')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: star200Tile,
        matching: find.byKey(const Key('purchase-provenance-chip-product')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: star200Tile, matching: find.text('450')),
      findsNothing,
    );
  });

  testWidgets('keeps the inline benefit when a legacy rate has no exact pill', (
    tester,
  ) async {
    await pumpStore(tester, promotion: () => fractionalLegacyCampaign);

    expect(
      find.byKey(const Key('purchase-reward-extension')),
      findsNWidgets(2),
    );
    expect(find.byKey(const Key('candy-boost-inline-badge')), findsNWidgets(2));
    expect(find.byType(CandyBoostBadge), findsNothing);
    expect(find.text('캔디 부스트 데이'), findsNWidgets(2));
    expect(
      find.byKey(const Key('purchase-bonus-components')),
      findsNWidgets(2),
    );
  });

  testWidgets('names the event once above the list, never per row', (
    tester,
  ) async {
    await pumpStore(
      tester,
      promotion: () => doubleCampaign,
      promotionPeriod: (
        startsAt: DateTime.utc(2026, 9, 7, 15),
        endsAt: DateTime.utc(2026, 9, 8, 14, 59, 59),
      ),
    );

    expect(find.byKey(const Key('candy-boost-period-banner')), findsOneWidget);
    expect(
      find.byKey(const Key('candy-boost-banner-bonus-icon')),
      findsOneWidget,
    );
    expect(find.text('캔디 부스트 데이'), findsOneWidget);
    expect(find.text('내부 테스트 캔디 부스트 캠페인 이름'), findsNothing);
    expect(find.text('CANDY_BOOST_DAY'), findsNothing);
    // Every eligible row still carries its multiplier.
    expect(find.text('+100%'), findsNWidgets(3));
  });

  testWidgets('keeps the plain catalog rows when no campaign resolves', (
    tester,
  ) async {
    await pumpStore(tester, promotion: () => null);

    expect(tester.takeException(), isNull);
    expect(find.byType(CandyBoostBadge), findsNothing);
    expect(find.byKey(const Key('candy-boost-period-banner')), findsNothing);
    expect(find.byKey(const Key('purchase-expected-total')), findsNothing);
    expect(find.byKey(const Key('purchase-event-bonus')), findsNothing);
    // The catalog amounts are still there, unchanged.
    expect(find.text('100'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('advertises nothing while the resolver has not settled', (
    tester,
  ) async {
    // Riverpod retains the previous value through a refresh; promotion UI has
    // to fail closed instead of promising a campaign nobody has confirmed.
    await pumpStore(
      tester,
      promotion: () => Completer<ResolvedPaymentBadgePromotion?>().future,
    );

    expect(find.byType(CandyBoostBadge), findsNothing);
    expect(find.byKey(const Key('candy-boost-period-banner')), findsNothing);
    expect(find.byKey(const Key('purchase-expected-total')), findsNothing);
  });

  testWidgets('a promoted tile survives 320dp at 2x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        StoreListTile(
          icon: Image.asset(
            'assets/icons/store/currency_star_candy.png',
            package: 'picnic_lib',
            width: 48,
            height: 48,
            errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
          ),
          title: const Text('STAR200'),
          subtitle: PurchaseRewardPreviewView(
            preview: PurchaseRewardPreview(
              base: BigInt.from(200),
              productBonus: BigInt.from(25),
              multiplierTenths: 20,
            ),
          ),
          badge: const CandyBoostBadge(totalMultiplierTenths: 20),
          isPromoted: true,
          buttonText: '3.99 \$',
          buttonOnPressed: () {},
          flexibleHeight: true,
        ),
        textScaler: const TextScaler.linear(2),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('purchase-bonus-components')), findsOneWidget);
    expect(find.text('450'), findsNothing);
    expect(find.text('+100%'), findsOneWidget);
    expect(find.byKey(const Key('purchase-price-cta')), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
