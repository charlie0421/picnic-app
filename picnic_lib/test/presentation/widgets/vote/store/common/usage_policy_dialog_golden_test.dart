import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_environment.dart';

/// 소멸 예정 캔디 안내 팝업 골든.
///
/// 모든 정책 본문이 처음부터 보이는 상태와, 작은 화면의 상단·하단 스크롤
/// 상태를 고정한다. `prediction_month` 를 2099 로 둔 이유는
/// `bonusExpiringToday` 가 매월 15일에만 0 이 아닌 값을 돌려주므로, 실제 연월을
/// 쓰면 그 달 15일에 히어로 문구가 바뀌어 골든이 깨지기 때문이다.
///
/// vi 골든은 비 ko/en 로케일의 레이아웃 회귀를 대표로 잡는다. 코튼캔디·지갑
/// 계열 키는 한때 ko/en ARB 에만 있어 vi 화면이 반영어로 고정돼 있었지만,
/// 2026-07 재번역으로 전 로케일 번역이 채워져 현재 골든은 완전한 vi 화면이다.
class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository.value(WalletSummaryModel summary)
    : loadSummary = (() async => summary),
      super(_UnusedClient());

  final Future<WalletSummaryModel> Function() loadSummary;

  @override
  Future<WalletSummaryModel> getSummary() => loadSummary();

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// 패키지 PNG 를 디스크에서 직접 읽는다 (wallet_summary_panel_golden_test 와
/// 같은 패턴). 이 다이얼로그가 쓰는 두 아이콘은 둘 다
/// `assets/icons/store/currency_` 접두사라 기존 술어와 그대로 맞는다.
class _GoldenAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (!key.contains('assets/icons/store/currency_')) {
      return rootBundle.load(key);
    }
    final relativePath = key.replaceFirst('packages/picnic_lib/', '');
    final bytes = await File(relativePath).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

final _goldenAssetBundle = _GoldenAssetBundle();

final _summary = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(320),
  bonus: BigInt.from(1500),
  cotton: BigInt.from(50),
  cottonExpiringAmount: BigInt.from(10),
  cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
  snapshotAt: DateTime.utc(2026, 7, 23),
);

const _bonusRows = [
  {'prediction_month': '2099-09', 'expiring_amount': 300},
  {'prediction_month': '2099-08', 'expiring_amount': 1200},
];

final _goldenExampleReferenceDate = DateTime.utc(2026, 7, 1);

Widget _buildGoldenApp({
  required Locale locale,
  required double textScale,
  required List<Map<String, dynamic>> bonusRows,
}) {
  return ProviderScope(
    overrides: [
      ...defaultProviderOverrides(loggedIn: true),
      expireBonusProvider.overrideWith((ref) async => bonusRows),
      walletRepositoryProvider.overrideWithValue(
        _WalletRepository.value(_summary),
      ),
    ],
    child: DefaultAssetBundle(
      bundle: _goldenAssetBundle,
      child: ScreenUtilInit(
        designSize: kAppDesignSize,
        minTextAdapt: true,
        splitScreenMode: kAppSplitScreenMode,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(fontFamily: 'packages/picnic_lib/Pretendard'),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          // 전체 화면 다이얼로그 자체를 화면 경계까지 캡처한다.
          home: RepaintBoundary(
            child: UsagePolicyPopup(
              exampleReferenceDate: _goldenExampleReferenceDate,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpGolden(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  double textScale = 1.0,
  List<Map<String, dynamic>> bonusRows = _bonusRows,
}) async {
  await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _buildGoldenApp(locale: locale, textScale: textScale, bonusRows: bonusRows),
  );

  final context = tester.element(find.byType(UsagePolicyPopup));
  for (final asset in const [
    'assets/icons/store/currency_cotton_candy.png',
    'assets/icons/store/currency_bonus_star_candy.png',
  ]) {
    await tester.runAsync(
      () => precacheImage(
        AssetImage(asset, package: 'picnic_lib', bundle: _goldenAssetBundle),
        context,
      ),
    );
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// 통화 아이콘이 렌더됐는지 자산 이름으로 확인한다.
///
/// 예전에는 `find.byType(Image)` 개수를 2 로 못박았는데, 소멸 안내가 표
/// 레이아웃으로 개편되면서(2026-08-04) 행마다 아이콘이 붙어 개수가 데이터에
/// 따라 변한다. 개수 자체는 이 골든이 지키려는 성질이 아니다 - 지켜야 하는
/// 것은 "두 통화 아이콘이 실제로 그려진다" 이므로 그렇게 단언한다.
Finder _currencyIcon(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName.contains(assetName),
    );

void _expectCurrencyIconsRendered() {
  expect(_currencyIcon('currency_cotton_candy.png'), findsWidgets);
  expect(_currencyIcon('currency_bonus_star_candy.png'), findsWidgets);
}

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  // 320dp 다음으로 좁은 실사용 하한. 정적 정책 본문 때문에 바닥 신호
  // (그라디언트 + 아래 화살표)가 함께 고정된다.
  testWidgets('static initial content, ko, 360x640', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(360, 640),
      locale: const Locale('ko'),
    );
    _expectCurrencyIconsRendered();
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_360x640.png',
      ),
    );
  });

  testWidgets('static initial content, ko, 390x844', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ko'),
    );
    _expectCurrencyIconsRendered();
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_390x844.png',
      ),
    );
  });

  // OS 큰 글씨. 카드가 내용에 붙으므로 높이만 자라고 잘리지 않아야 한다.
  testWidgets('static initial content, ko, 390x844, textScaler 1.3', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ko'),
      textScale: 1.3,
    );
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_390x844_scale1_3.png',
      ),
    );
  });

  // 긴 번역 로케일. vi 는 wallet_* 키가 없어 영어로 폴백하므로
  // 'Cotton Candy' / 'Bonus Star Candy' 라벨 폭까지 같이 고정된다.
  testWidgets('static initial content, vi, 390x844', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      locale: const Locale('vi'),
    );
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_vi_390x844.png',
      ),
    );
  });

  // 레포가 하한으로 못박아 둔 가장 좁고 낮은 기기. **기본 화면이 넘치는 유일한
  // 크기대**라서, 잘림이 카드 테두리에서 일어나는지와 바닥 신호가 켜지는지를
  // 이 골든이 잡는다(리뷰에서 지적된, 픽셀 커버리지가 비어 있던 자리).
  testWidgets('static initial content, ko, 320x568 (overflowing)', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      size: const Size(320, 568),
      locale: const Locale('ko'),
    );
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .extentAfter,
      greaterThan(1.0),
      reason: 'this golden is meant to pin the overflowing state',
    );
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_320x568_collapsed.png',
      ),
    );
  });

  // 정적 본문의 스크롤 양끝을 고정한다. 아래쪽 골든은 끝까지 내렸을 때 마지막
  // 줄이 코너 곡선에 씹히지 않고 바닥 신호가 사라지는 걸 잡는다.
  testWidgets('static content, ko, 360x640 (top / bottom)', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(360, 640),
      locale: const Locale('ko'),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, 0.0);
    expect(position.extentAfter, greaterThan(1.0));
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_360x640_expanded.png',
      ),
    );

    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(position.extentAfter, lessThan(1.0));
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_360x640_expanded_bottom.png',
      ),
    );
  });

  // 소멸 예정 행이 하나도 없는 상태. 예전에는 보너스 카드가 아이콘 + 레이블만
  // 남은 빈 분홍 막대로 렌더돼 로딩 스켈레톤처럼 보였다 — 흔한 상태(예정 없는
  // 로그인 사용자 전부 + 비로그인)라서 골든으로 못박는다.
  testWidgets('static content with no upcoming rows, ko, 390x844', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ko'),
      bonusRows: const [],
    );
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_390x844_no_rows.png',
      ),
    );
  });

  // 가장 작은 지원 화면에서 정적 본문과 남은 스크롤 영역을 고정한다.
  testWidgets('static content, ko, 320x568', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(320, 568),
      locale: const Locale('ko'),
    );
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .extentAfter,
      greaterThan(0),
    );
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_320x568_expanded.png',
      ),
    );
  });
}
