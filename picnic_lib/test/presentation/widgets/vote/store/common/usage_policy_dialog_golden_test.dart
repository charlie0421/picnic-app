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
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_environment.dart';

/// 소멸 예정 캔디 안내 팝업의 **기본(접힌) 화면** 골든.
///
/// 골든은 리디자인의 핵심인 "쉬는 상태" 를 고정한다 — 히어로 한 줄, 두 재화
/// 카드, 접힌 세 개의 공개 블록. 접힌 상태라 예시 문구(`DateTime.now()` 의 월에
/// 의존)는 렌더되지 않으므로 골든은 날짜에 흔들리지 않는다.
///
/// `prediction_month` 를 2099 로 둔 이유도 같다: `bonusExpiringToday` 는 매월
/// 15일에만 0 이 아닌 값을 돌려주므로, 실제 연월을 쓰면 그 달 15일에 히어로
/// 문구가 바뀌어 골든이 깨진다.
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

Widget _buildGoldenApp({required Locale locale, required double textScale}) {
  return ProviderScope(
    overrides: [
      ...defaultProviderOverrides(loggedIn: true),
      expireBonusProvider.overrideWith((ref) async => _bonusRows),
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
          // 프로덕션에서는 팝업이 스크림 위에 얹힌다. 골든은 팝업 자체의 경계만
          // 잡으면 되므로 RepaintBoundary 로 감싼다.
          home: const Material(
            color: Color(0xFF3C3C43),
            child: Center(
              child: RepaintBoundary(child: UsagePolicyPopup()),
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
}) async {
  await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _buildGoldenApp(locale: locale, textScale: textScale),
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

  // 320dp 다음으로 좁은 실사용 하한. 여기서는 기본 화면도 조금 스크롤되므로
  // 바닥 페이드가 함께 고정된다.
  testWidgets('collapsed default, ko, 360x640', (tester) async {
    await _pumpGolden(tester, size: const Size(360, 640), locale: const Locale('ko'));
    expect(find.byType(Image), findsNWidgets(2));
    await expectLater(
      find.byType(LargePopupWidget),
      matchesGoldenFile('../../../../../goldens/usage_policy_dialog_ko_360x640.png'),
    );
  });

  testWidgets('collapsed default, ko, 390x844', (tester) async {
    await _pumpGolden(tester, size: const Size(390, 844), locale: const Locale('ko'));
    expect(find.byType(Image), findsNWidgets(2));
    await expectLater(
      find.byType(LargePopupWidget),
      matchesGoldenFile('../../../../../goldens/usage_policy_dialog_ko_390x844.png'),
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
      find.byType(LargePopupWidget),
      matchesGoldenFile(
        '../../../../../goldens/usage_policy_dialog_ko_390x844_scale1_3.png',
      ),
    );
  });

  // 긴 번역 로케일. vi 는 wallet_* 키가 없어 영어로 폴백하므로
  // 'Cotton Candy' / 'Bonus Star Candy' 라벨 폭까지 같이 고정된다.
  testWidgets('collapsed default, vi, 390x844', (tester) async {
    await _pumpGolden(tester, size: const Size(390, 844), locale: const Locale('vi'));
    await expectLater(
      find.byType(LargePopupWidget),
      matchesGoldenFile('../../../../../goldens/usage_policy_dialog_vi_390x844.png'),
    );
  });
}
