import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_confirm_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_environment.dart';

// Visual QA uses real purchase widgets with deterministic catalog/settlement
// fixtures, production ScreenUtil geometry, and the loaded design-system font.
// No live purchases, production data, or simulated artwork are involved.
const _canvas = Key('candy-boost-visual-canvas');
const _openDialog = Key('open-visual-dialog');

class _VisualStorePlatform extends InAppPurchasePlatform {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => true;
}

const _products = <Map<String, dynamic>>[
  {
    'id': 'STAR100',
    'price': 0.99,
    'star_candy': 100,
    'star_candy_bonus': 0,
    'description': {'ko': '스타 캔디 100개', 'en': '100 Star Candies'},
  },
  {
    'id': 'STAR200',
    'price': 1.99,
    'star_candy': 200,
    'star_candy_bonus': 25,
    'description': {'ko': '스타 캔디 200개 + 보너스 25개', 'en': '200 + 25 bonus'},
  },
  {
    'id': 'STAR600',
    'price': 5.99,
    'star_candy': 600,
    'star_candy_bonus': 85,
    'description': {'ko': '스타 캔디 600개 + 보너스 85개'},
  },
  {
    'id': 'STAR1000',
    'price': 9.99,
    'star_candy': 1000,
    'star_candy_bonus': 150,
    'description': {'ko': '스타 캔디 1000개 + 보너스 150개'},
  },
  {
    'id': 'STAR2000',
    'price': 19.99,
    'star_candy': 2000,
    'star_candy_bonus': 320,
    'description': {'ko': '스타 캔디 2000개 + 보너스 320개'},
  },
  {
    'id': 'STAR3000',
    'price': 29.99,
    'star_candy': 3000,
    'star_candy_bonus': 540,
    'description': {'ko': '스타 캔디 3000개 + 보너스 540개'},
  },
  {
    'id': 'STAR4000',
    'price': 39.99,
    'star_candy': 4000,
    'star_candy_bonus': 760,
    'description': {'ko': '스타 캔디 4000개 + 보너스 760개'},
  },
  {
    'id': 'STAR5000',
    'price': 49.99,
    'star_candy': 5000,
    'star_candy_bonus': 1000,
    'description': {'ko': '스타 캔디 5000개 + 보너스 1000개'},
  },
  {
    'id': 'STAR7000',
    'price': 69.99,
    'star_candy': 7000,
    'star_candy_bonus': 1500,
    'description': {'ko': '스타 캔디 7000개 + 보너스 1500개'},
  },
  {
    'id': 'STAR10000',
    'price': 99.99,
    'star_candy': 10000,
    'star_candy_bonus': 2100,
    'description': {'ko': '스타 캔디 10000개 + 보너스 2100개'},
  },
];

final _storeProducts = List<ProductDetails>.unmodifiable(
  _products.map(
    (product) => ProductDetails(
      id: 'test${product['id']}',
      title: product['id'] as String,
      description: 'Store product ${product['id']}',
      price: 'US\$${product['price']}',
      rawPrice: (product['price'] as num).toDouble(),
      currencyCode: 'USD',
    ),
  ),
);
const _promotion = (
  displayName: {
    'ko': '캔디 부스트 데이 내부테스트 2배 - 매우 긴 관리자 설정 이름',
    'en': 'An internal campaign name that must never stretch a product row',
  },
  code: 'CANDY_BOOST_DAY',
  multiplierTenths: 20,
  extraBonusBps: null,
);

CandyRewardReceipt _settledReceipt() => receiptFromPurchase(
  PurchaseSettlementResultModel(
    contractVersion: 'wallet.v1',
    operationId: 'visual-star200',
    replayed: false,
    baseStarAmount: BigInt.from(200),
    baseBonusAmount: BigInt.from(25),
    promotion: PurchasePromotionResultModel(
      resolutionId: 'visual-grant',
      state: PurchasePromotionState.granted,
      campaignVersionId: 'visual-campaign',
      promoBonusAmount: BigInt.from(225),
      domainCode: null,
    ),
    wallet: WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.from(7401),
      bonus: BigInt.from(1814),
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: DateTime.utc(2026, 9, 10),
    ),
  ),
)!;

Widget _app(Widget child, {Locale locale = const Locale('ko')}) =>
    ProviderScope(
      overrides: [
        ...defaultProviderOverrides(),
        serverProductsProvider.overrideWithBuild((ref, notifier) => _products),
        storeProductsProvider.overrideWithBuild(
          (ref, notifier) => _storeProducts,
        ),
        paymentBadgePromotionProvider.overrideWith((ref) async => _promotion),
      ],
      child: ScreenUtilInit(
        designSize: kAppDesignSize,
        minTextAdapt: true,
        splitScreenMode: kAppSplitScreenMode,
        builder: (context, _) => RepaintBoundary(
          key: _canvas,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: voteThemeLight.copyWith(
              textTheme: voteThemeLight.textTheme.apply(
                fontFamily: 'packages/picnic_lib/Pretendard',
              ),
            ),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: child),
          ),
        ),
      ),
    );

void _viewport(WidgetTester tester, {double height = 852}) {
  tester.view.physicalSize = Size(393, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _capture(WidgetTester tester, String name) async {
  // Asset decoding uses real async work, unlike the fake animation clock.
  // Precache the actual Image widgets so a golden cannot capture an empty
  // placeholder while the icon is still decoding.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final provider = (element.widget as Image).image;
      if (provider is AssetImage) await precacheImage(provider, element);
    }
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byKey(_canvas),
    matchesGoldenFile(
      '../../../../../goldens/candy_boost_purchase_ui_$name.png',
    ),
  );
}

void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
    // As in the existing purchase platform tests, initialize the singleton
    // on a non-native platform so it cannot register a real billing channel.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = _VisualStorePlatform();
    InAppPurchase.instance;
    debugDefaultTargetPlatformOverride = null;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupMockSupabase({'products': _products});
  });
  tearDown(tearDownMockSupabase);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('promoted product list through STAR10000 visual', (tester) async {
    const captureHeight = 2900.0;
    _viewport(tester, height: captureHeight);
    await tester.pumpWidget(_app(const PurchaseStarCandy()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('+250'), findsOneWidget);
    expect(find.text('450'), findsNothing);
    expect(find.text('+100'), findsOneWidget);
    expect(find.textContaining('이벤트 보너스 +225'), findsOneWidget);
    for (final product in _products) {
      final id = product['id'] as String;
      final title = find.text(id);
      expect(title, findsOneWidget);
      // Finding the full text alone misses mid-token line breaks such as
      // "STAR100" / "00". Inspect the real, design-font glyph layout too.
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: id.length),
      );
      expect(boxes.map((box) => box.top).toSet(), hasLength(1), reason: id);
      expect(paragraph.didExceedMaxLines, isFalse, reason: id);
      // Allow the font's subpixel glyph overhang, not a truncated title.
      expect(
        boxes.last.right,
        lessThanOrEqualTo(paragraph.size.width + 1),
        reason: id,
      );
    }
    expect(find.text('+14,200'), findsOneWidget);
    expect(find.text('24,200'), findsNothing);
    expect(find.textContaining('이벤트 보너스 +12,100'), findsOneWidget);
    expect(
      tester.getBottomRight(find.text('STAR10000')).dy,
      lessThan(captureHeight),
    );
    expect(
      tester.getBottomRight(find.textContaining('이벤트 보너스 +12,100')).dy,
      lessThan(captureHeight),
    );
    expect(find.textContaining('내부테스트'), findsNothing);
    final purchaseCtas = find.byKey(const Key('purchase-price-cta'));
    expect(purchaseCtas, findsNWidgets(_products.length));
    expect(purchaseCtas.hitTestable(), findsNWidgets(_products.length));
    final purchaseButtons = find.descendant(
      of: purchaseCtas,
      matching: find.byType(ElevatedButton),
    );
    expect(purchaseButtons, findsNWidgets(_products.length));
    for (final button in tester.widgetList<ElevatedButton>(purchaseButtons)) {
      expect(button.onPressed, isNotNull);
    }
    await _capture(tester, 'list_ko');
  });

  testWidgets('STAR200 estimated purchase confirmation visual', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            key: _openDialog,
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => PurchaseConfirmDialog(
                serverProduct: _products[1],
                storeProducts: _storeProducts,
                displayedPromotion: _promotion,
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openDialog));
    await tester.pumpAndSettle();
    expect(find.text('+250'), findsOneWidget);
    expect(find.text('450'), findsNothing);
    expect(find.text('기본 보너스'), findsOneWidget);
    expect(find.text('이벤트 보너스'), findsOneWidget);
    await _capture(tester, 'confirmation_ko');
  });

  testWidgets('STAR200 server-confirmed split receipt visual', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            key: _openDialog,
            onPressed: () =>
                showCandyRewardReceiptDialog(context, _settledReceipt()),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openDialog));
    await tester.pumpAndSettle();
    expect(find.text('총 적립 450'), findsNothing);
    expect(find.text('+200'), findsOneWidget);
    expect(find.text('+250'), findsOneWidget);
    expect(find.text('+25'), findsOneWidget);
    expect(find.text('+225'), findsOneWidget);
    await _capture(tester, 'receipt_ko');
  });
}
