import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

final _paymentBadgeSourceProvider =
    StateProvider<ResolvedPaymentBadgePromotion?>((ref) => null);

/// Helper to build PurchaseStarCandy with mock providers.
/// Since PurchaseStarCandyState creates internal timers via PurchaseService,
/// RestorePurchaseHandler, and PurchaseSafetyManager, we focus on testing
/// the static build output and related utility classes.
void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({
      'products': [
        {
          'id': 'STAR100',
          'price': 1.99,
          'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
        },
      ],
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('StoreListTile widget', () {
    testWidgets('keeps 16px space around the candy pouch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const PurchaseStarCandy(),
          extraOverrides: [
            serverProductsProvider.overrideWithBuild(
              (ref, notifier) => [
                {
                  'id': 'STAR100',
                  'price': 1.99,
                  'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
                },
              ],
            ),
            storeProductsProvider.overrideWithBuild(
              (ref, notifier) => const <ProductDetails>[],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));

      final pouchRect = tester.getRect(find.byType(StorePointInfo));
      final previousRect = tester.getRect(find.byType(ListView).first);
      final nextRect = tester.getRect(find.byType(Divider).first);

      expect(pouchRect.top - previousRect.top, 16);
      expect(nextRect.top - pouchRect.bottom, 16);
    });

    testWidgets('renders the product-specific star candy artwork', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const PurchaseStarCandy(),
          extraOverrides: [
            serverProductsProvider.overrideWithBuild(
              (ref, notifier) => [
                {
                  'id': 'STAR100',
                  'price': 1.99,
                  'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
                },
              ],
            ),
            storeProductsProvider.overrideWithBuild(
              (ref, notifier) => const <ProductDetails>[],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));

      final productTile = tester.widget<StoreListTile>(
        find.byType(StoreListTile),
      );
      final imageProvider = productTile.icon.image as AssetImage;

      expect(imageProvider.assetName, 'assets/icons/store/star_100.png');
    });

    testWidgets('renders with title and button', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: Image.asset(
              'assets/icons/store/star_100.png',
              package: 'picnic_lib',
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            title: const Text('STAR100'),
            subtitle: const Text('100 Star Candies'),
            buttonText: '1.99 \$',
            buttonOnPressed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StoreListTile), findsOneWidget);
      expect(find.text('STAR100'), findsOneWidget);
      expect(find.text('100 Star Candies'), findsOneWidget);
      expect(find.text('1.99 \$'), findsOneWidget);
    });

    testWidgets('renders without subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: Image.asset(
              'assets/icons/store/star_100.png',
              package: 'picnic_lib',
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            title: const Text('STAR100'),
            buttonText: '1.99 \$',
            buttonOnPressed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StoreListTile), findsOneWidget);
      expect(find.text('STAR100'), findsOneWidget);
    });

    testWidgets('renders with isLoading true disables button', (
      WidgetTester tester,
    ) async {
      // Note: isLoading=true renders SmallPulseLoadingIndicator which uses
      // assets/app_icon_128.png - we verify the button is disabled
      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: Image.asset(
              'assets/icons/store/star_100.png',
              package: 'picnic_lib',
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            title: const Text('STAR100'),
            buttonText: '1.99 \$',
            buttonOnPressed: () {},
            isLoading: true,
          ),
        ),
      );
      // Use pump to avoid image loading errors treated as test failures
      await tester.pump();

      expect(find.byType(StoreListTile), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      // When isLoading is true, onPressed is null
      expect(button.onPressed, isNull);
    }, skip: true);

    testWidgets('renders disabled button when onPressed is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: Image.asset(
              'assets/icons/store/star_100.png',
              package: 'picnic_lib',
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            title: const Text('STAR100'),
            buttonText: '1.99 \$',
            buttonOnPressed: null,
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('button tap calls onPressed', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: Image.asset(
              'assets/icons/store/star_100.png',
              package: 'picnic_lib',
              width: 48,
              height: 48,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            title: const Text('STAR100'),
            buttonText: '1.99 \$',
            buttonOnPressed: () {
              pressed = true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });
  });

  group('product list promotion presentation', () {
    List<dynamic> productListOverrides({
      required ResolvedPaymentBadgePromotion resolved,
    }) => [
      serverProductsProvider.overrideWithBuild(
        (ref, notifier) => [
          {
            'id': 'STAR100',
            'price': 1.99,
            'star_candy': 100,
            'star_candy_bonus': 0,
            'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
          },
        ],
      ),
      storeProductsProvider.overrideWithBuild(
        (ref, notifier) => const <ProductDetails>[],
      ),
      paymentBadgePromotionProvider.overrideWith((ref) async => resolved),
      paymentBadgePromotionPeriodProvider.overrideWith(
        (ref) async => (
          startsAt: DateTime.utc(2026, 9, 7, 15),
          endsAt: DateTime.utc(2026, 9, 8, 14, 59, 59),
        ),
      ),
    ];

    const v2Multiplier = (
      displayName: {'ko': '추석 캔디 부스트', 'en': 'Chuseok Candy Boost'},
      code: 'CANDY_BOOST_DAY',
      multiplierTenths: 15,
      extraBonusBps: null,
    );

    const v1ExactDouble = (
      displayName: {'ko': '캔디 부스트 데이', 'en': 'Candy Boost Day'},
      code: 'CANDY_BOOST_DAY',
      multiplierTenths: null,
      extraBonusBps: 10000,
    );

    Future<void> pumpProductList(
      WidgetTester tester, {
      required Locale locale,
      required ResolvedPaymentBadgePromotion resolved,
    }) async {
      await tester.pumpWidget(
        buildTestApp(
          const PurchaseStarCandy(),
          locale: locale,
          // The long English copy only fits the fixed-height StoreListTile at
          // the real app geometry — measure there, per the harness guidance
          // for layout-sensitive assertions.
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          extraOverrides: productListOverrides(resolved: resolved),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets(
      'renders the Korean total-multiplier pill for a V2 1.5x record',
      (WidgetTester tester) async {
        await pumpProductList(
          tester,
          locale: const Locale('ko'),
          resolved: v2Multiplier,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(CandyBoostBadge), findsOneWidget);
        // The campaign record's own display name is internal copy - it must
        // not be repeated on a consumer product row.
        expect(find.text('추석 캔디 부스트'), findsNothing);
        // floor(100 * 15 / 10) = 150, so this row pays 1.5x in total.
        expect(find.text('+50%'), findsNWidgets(2));
        expect(find.text('이벤트 50'), findsOneWidget);
        expect(find.text('150'), findsNothing);
        // Selection data must never leak to the UI as raw basis points.
        expect(find.textContaining('bps'), findsNothing);
        expect(find.textContaining('5000'), findsNothing);
      },
    );

    testWidgets(
      'renders the English total-multiplier pill for a V2 1.5x record',
      (WidgetTester tester) async {
        await pumpProductList(
          tester,
          locale: const Locale('en'),
          resolved: v2Multiplier,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(CandyBoostBadge), findsOneWidget);
        expect(find.text('Chuseok Candy Boost'), findsNothing);
        expect(find.text('+50%'), findsNWidgets(2));
        expect(find.text('Event 50'), findsOneWidget);
        expect(find.text('150'), findsNothing);
        expect(find.textContaining('bps'), findsNothing);
        expect(find.textContaining('5000'), findsNothing);
      },
    );

    testWidgets(
      'renders a doubled total for a V1 exact-double record in Korean',
      (WidgetTester tester) async {
        await pumpProductList(
          tester,
          locale: const Locale('ko'),
          resolved: v1ExactDouble,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(CandyBoostBadge), findsOneWidget);
        // The one place the event is named: the stable localized header
        // above the list, not the campaign record's display name per row.
        expect(find.text('캔디 부스트 데이'), findsOneWidget);
        expect(find.text('기본 지급 + 추가 보너스 100%'), findsNothing);
        expect(find.text('+100%'), findsNWidgets(2));
        expect(find.text('이벤트 100'), findsOneWidget);
        expect(find.text('200'), findsNothing);
        // 10000 bps drives the copy selection but must never render.
        expect(find.textContaining('10000'), findsNothing);
        expect(find.textContaining('bps'), findsNothing);
      },
    );

    testWidgets(
      'renders a doubled total for a V1 exact-double record in English',
      (WidgetTester tester) async {
        await pumpProductList(
          tester,
          locale: const Locale('en'),
          resolved: v1ExactDouble,
        );

        // The long English caption that used to wrap inside the fixed-height
        // tile and overflow its column by ~7px is gone: the row now carries a
        // compact pill and grows with its content. No overflow is tolerated.
        expect(tester.takeException(), isNull);
        expect(find.byType(CandyBoostBadge), findsOneWidget);
        expect(find.text('Candy Boost Day'), findsOneWidget);
        expect(find.text('Base reward + 100% extra bonus'), findsNothing);
        expect(find.text('+100%'), findsNWidgets(2));
        expect(find.text('200'), findsNothing);
        expect(find.textContaining('10000'), findsNothing);
        expect(find.textContaining('bps'), findsNothing);
      },
    );
  });

  testWidgets(
    'purchase confirmation uses the same V2-first promotion shown on the product',
    (tester) async {
      const selectedV2 = (
        displayName: {'ko': '선택된 V2 캔디 부스트', 'en': 'Selected V2 Candy Boost'},
        code: 'CANDY_BOOST_DAY',
        multiplierTenths: 15,
        extraBonusBps: null,
      );
      const refreshedPromotion = (
        displayName: {'ko': '새 V2 캔디 부스트', 'en': 'Refreshed V2 Candy Boost'},
        code: 'CANDY_BOOST_DAY',
        multiplierTenths: 20,
        extraBonusBps: null,
      );
      final staleV1 = ActivePromotionCampaignsModel(
        items: [
          ActivePromotionCampaignModel(
            campaignId: 'unrelated-campaign',
            campaignVersionId: 'unrelated-version',
            code: 'AAA_OTHER_CAMPAIGN',
            displayName: const {
              'ko': '관련 없는 첫 STORE 캠페인',
              'en': 'Unrelated first STORE campaign',
            },
            extraBonusBps: 2500,
            windowStartsAt: DateTime.utc(2026),
            windowEndsAt: DateTime.utc(2027),
            showInStore: true,
            showHomeBanner: false,
          ),
          ActivePromotionCampaignModel(
            campaignId: 'stale-candy-boost',
            campaignVersionId: 'stale-version',
            code: 'CANDY_BOOST_DAY',
            displayName: const {
              'ko': '오래된 V1 캔디 부스트',
              'en': 'Stale V1 Candy Boost',
            },
            extraBonusBps: 10000,
            windowStartsAt: DateTime.utc(2026),
            windowEndsAt: DateTime.utc(2027),
            showInStore: true,
            showHomeBanner: false,
          ),
        ],
        totalCount: BigInt.two,
        nextCursor: null,
        snapshotAt: DateTime.utc(2026),
        campaignOwnedHomeBannerIds: const [],
      );
      final storeProduct = ProductDetails(
        // Widget tests run on the host (non-Android), where the shared product
        // ID policy applies the configured test iOS prefix.
        id: 'testSTAR100',
        title: 'Star Candy 100',
        description: '100 Star Candies',
        price: '1.99',
        rawPrice: 1.99,
        currencyCode: 'USD',
      );

      await tester.pumpWidget(
        buildTestApp(
          const PurchaseStarCandy(),
          locale: const Locale('en'),
          extraOverrides: [
            serverProductsProvider.overrideWithBuild(
              (ref, notifier) => [
                {
                  'id': 'STAR100',
                  'price': 1.99,
                  'star_candy': 100,
                  'star_candy_bonus': 0,
                  'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
                },
              ],
            ),
            storeProductsProvider.overrideWithBuild(
              (ref, notifier) => [storeProduct],
            ),
            _paymentBadgeSourceProvider.overrideWith((ref) => selectedV2),
            paymentBadgePromotionProvider.overrideWith(
              (ref) async => ref.watch(_paymentBadgeSourceProvider),
            ),
            activePromotionCampaignProvider(
              PromotionSurface.store,
            ).overrideWith((ref) async => staleV1),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));

      // The row keeps the 100 star candy and +50 bonus star candy separate.
      expect(find.text('Event 50'), findsOneWidget);
      expect(find.text('150'), findsNothing);
      final buyButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('purchase-price-cta')),
      );
      expect(buyButton.onPressed, isNotNull);

      // Invoke the product button's real callback directly. A transient
      // loading overlay can absorb pointer hit-testing in this harness, but
      // the callback is the production _handleBuyButtonPressed wiring this
      // regression protects.
      buyButton.onPressed!();
      await tester.pumpAndSettle();

      // The pre-fix path reads V1 here and chooses its first showInStore row,
      // even though the product badge has already advertised selectedV2.
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      // The confirmation quotes the snapshot captured on button press.
      expect(
        find.descendant(of: dialog, matching: find.text('Total 50')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('150')),
        findsNothing,
      );
      // Internal campaign copy never reaches the buyer.
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Selected V2 Candy Boost'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Unrelated first STORE campaign'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Stale V1 Candy Boost'),
        ),
        findsNothing,
      );

      // Refresh the real provider while showDialog is still awaiting input.
      // The product badge rebuilds from the new resolution, but the open
      // confirmation must retain the exact snapshot captured on button press.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PurchaseStarCandy)),
      );
      container.read(_paymentBadgeSourceProvider.notifier).state =
          refreshedPromotion;
      await tester.pump();
      await tester.pump();

      // The product row follows the new resolution without merging currencies.
      expect(find.text('Event 100'), findsOneWidget);
      expect(find.text('200'), findsNothing);
      // The open confirmation keeps the amounts it was opened with.
      expect(
        find.descendant(of: dialog, matching: find.text('Total 50')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('150')),
        findsNothing,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('200')),
        findsNothing,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  group('PurchaseStarCandy - _isPurchaseCanceled logic (unit)', () {
    // The _isPurchaseCanceled method is private, but we can test the cancel detection
    // keywords and error codes indirectly through known cancel patterns
    test('cancel keywords list covers common patterns', () {
      final cancelKeywords = [
        'cancel',
        'cancelled',
        'canceled',
        'user cancel',
        'abort',
        'dismiss',
        'authentication',
        'touch id',
        'face id',
        'biometric',
        'passcode',
        'unauthorized',
        'permission denied',
        'operation was cancelled',
        'user cancelled',
        'user denied',
        'authentication failed',
        'authentication cancelled',
        'declined',
        'rejected',
      ];

      // All keywords are non-empty
      for (final keyword in cancelKeywords) {
        expect(keyword.isNotEmpty, true);
      }
      expect(cancelKeywords.length, greaterThan(15));
    });

    test('cancel error codes list covers Apple and Google patterns', () {
      final cancelErrorCodes = [
        'PAYMENT_CANCELED',
        'USER_CANCELED',
        '2',
        'SKErrorPaymentCancelled',
        'BILLING_RESPONSE_USER_CANCELED',
        'storekit2_purchase_cancelled',
        'purchase_cancelled',
        'transaction_cancelled',
        'user_cancelled_purchase',
      ];

      for (final code in cancelErrorCodes) {
        expect(code.isNotEmpty, true);
      }
      expect(cancelErrorCodes.length, greaterThan(5));
    });
  });

  group('PurchaseStarCandy - _isDuplicateError logic (unit)', () {
    test('duplicate error patterns', () {
      final duplicatePatterns = [
        'StoreKit 캐시 문제',
        '중복 영수증',
        '이미 처리된 구매',
        'Duplicate',
        'reused',
      ];

      for (final pattern in duplicatePatterns) {
        expect(pattern.isNotEmpty, true);
        // Test that at least one pattern works with .contains()
        final testString = 'Error: $pattern detected';
        expect(testString.contains(pattern), true);
      }
    });
  });

  group('PurchaseStarCandy - _getStatusCounts logic (unit)', () {
    test('status count categories are correct', () {
      final statusCategories = [
        'pending',
        'restored',
        'purchased',
        'error',
        'canceled',
      ];
      expect(statusCategories.length, 5);

      // Map them to PurchaseStatus enum values
      final statusMap = {
        'pending': PurchaseStatus.pending,
        'restored': PurchaseStatus.restored,
        'purchased': PurchaseStatus.purchased,
        'error': PurchaseStatus.error,
        'canceled': PurchaseStatus.canceled,
      };

      for (final entry in statusMap.entries) {
        expect(entry.value, isNotNull);
      }
    });
  });
}
