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
/// 두 가지를 고정한다.
/// 1. **쉬는 상태** — 히어로 한 줄, 두 재화 카드, 소멸 시점 안내 · 예시는 접힘,
///    정책은 펼침(소비자 고지라 기본 노출).
/// 2. **펼친 상태 + 넘치는 상태** — 리디자인의 두 결함(잘림이 카드 테두리가
///    아니라 그보다 56px 위에서 일어나던 것, 펼쳐도 스크롤이 안 되던 것)은
///    전부 여기서만 보이므로 접힌 골든만으로는 회귀를 잡을 수 없었다.
///
/// **예시 블록은 어떤 골든에서도 펼치지 않는다.** 예시 문구는
/// `DateTime.now().month` 로 만들어지므로 펼치면 골든이 매달 깨진다.
/// `prediction_month` 를 2099 로 둔 이유도 같다: `bonusExpiringToday` 는 매월
/// 15일에만 0 이 아닌 값을 돌려주므로, 실제 연월을 쓰면 그 달 15일에 히어로
/// 문구가 바뀌어 골든이 깨진다.
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
          home: const RepaintBoundary(child: UsagePolicyPopup()),
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

/// 소멸 시점 안내를 펼친다. 예시는 날짜 의존 때문에 건드리지 않는다.
///
/// 탭 뒤에 `pumpAndSettle` 만 하면 부족하다 — 펼침이 끝난 뒤 스크롤을 걸기 위해
/// 232ms 타이머를 쓰는데, 그 사이 예약된 프레임이 없으면 가짜 시계가 거기까지
/// 흐르지 않는다.
Future<void> _openTimingRules(WidgetTester tester) async {
  final l = AppLocalizations.of(tester.element(find.byType(UsagePolicyPopup)));
  await tester.tap(find.text(l.bonus_candy_expiration_time_title));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
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

  // 320dp 다음으로 좁은 실사용 하한. 이 크기에서는 기본 화면이 이미
  // 117.5px 넘치므로 바닥 신호(그라디언트 + 아래 화살표)가 함께 고정된다.
  testWidgets('collapsed default, ko, 360x640', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(360, 640),
      locale: const Locale('ko'),
    );
    expect(find.byType(Image), findsNWidgets(2));
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_360x640.png',
      ),
    );
  });

  testWidgets('collapsed default, ko, 390x844', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      locale: const Locale('ko'),
    );
    expect(find.byType(Image), findsNWidgets(2));
    await expectLater(
      find.byType(FullScreenDialog),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_390x844.png',
      ),
    );
  });

  // OS 큰 글씨. 카드가 내용에 붙으므로 높이만 자라고 잘리지 않아야 한다.
  testWidgets('collapsed default, ko, 390x844, textScaler 1.3', (tester) async {
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
  testWidgets('collapsed default, vi, 390x844', (tester) async {
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
  testWidgets('collapsed default, ko, 320x568 (overflowing)', (tester) async {
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

  // 펼친 상태를 스크롤 양끝에서 고정한다.
  //
  // 360x640 에서는 펼친 블록이 뷰포트 안에 들어가서 자동 스크롤이 **일어나지
  // 않는다**(pixels == 0). 그래도 아래로 밀려난 예시 · 정책이 생기므로 바닥
  // 신호는 켜져야 한다 — 이 골든이 그 조합을 고정한다. 아래쪽 골든은 끝까지
  // 내렸을 때 마지막 줄이 코너 곡선에 씹히지 않고 신호가 사라지는 걸 잡는다.
  testWidgets('timing rules expanded, ko, 360x640 (top / bottom)', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      size: const Size(360, 640),
      locale: const Locale('ko'),
    );
    await _openTimingRules(tester);
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
  // 로그인 사용자 전부 + 비로그인)라서 골든으로 못박는다. 이 상태에서는 소멸
  // 시점 안내가 처음부터 펼쳐진다(개인 행이 없으면 그 매뉴얼이 곧 답이다).
  testWidgets('no upcoming rows, ko, 390x844', (tester) async {
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

  // 가장 작은 지원 화면에서 펼친 본문과 남은 스크롤 영역을 고정한다.
  testWidgets('timing rules expanded, ko, 320x568', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(320, 568),
      locale: const Locale('ko'),
    );
    await _openTimingRules(tester);
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
