import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

/// 소멸 예정 캔디 안내 팝업의 **기하 회귀** 테스트.
///
/// 기존 `usage_policy_dialog_test.dart` 는 `buildTestAppPage` 를 쓰는데 그쪽은
/// 375x812 / `splitScreenMode: false` 를 하드코딩한다(test_app.dart:114-116).
/// 프로덕션은 `kAppDesignSize` 393x892 + `splitScreenMode: true` 이고 그 차이가
/// `.h` 환산을 바꾸므로, 레이아웃은 여기서 프로덕션 기하로만 측정한다.
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

final _summary = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.from(1500),
  cotton: BigInt.from(50),
  cottonExpiringAmount: BigInt.from(10),
  cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
  snapshotAt: DateTime.utc(2026, 7, 23),
);

/// 일부러 월 오름차순이 아니게 둔다 — 화면이 정렬하는지 보려고.
const _bonusRows = [
  {'prediction_month': '2026-09', 'expiring_amount': 300},
  {'prediction_month': '2026-08', 'expiring_amount': 1200},
];

/// 실기기에서 보고된 기기(1080x2400 @ DPR 3.0 = 360x800)와 레포가 이미 하한으로
/// 못박아 둔 320dp 를 포함한다.
const _devices = <Size>[
  Size(320, 568),
  Size(320, 640),
  Size(360, 800),
  Size(375, 667),
  Size(393, 873),
  Size(411.4, 914.3),
];

Future<void> _pumpPopup(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('ko'),
  double textScale = 1.0,
  bool loggedIn = true,
  List<Map<String, dynamic>>? bonusRows = _bonusRows,
  Object? bonusError,
}) async {
  if (loggedIn) {
    await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  }
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    buildTestApp(
      const Material(color: Colors.transparent, child: UsagePolicyPopup()),
      loggedIn: loggedIn,
      locale: locale,
      // 프로덕션과 같은 ScreenUtil 기하.
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      extraOverrides: [
        expireBonusProvider.overrideWith(
          (ref) async =>
              bonusError != null ? throw bonusError : (bonusRows ?? const []),
        ),
        walletRepositoryProvider.overrideWithValue(
          _WalletRepository.value(_summary),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(UsagePolicyPopup)));

/// 접힘 헤더는 스크롤 밖에 있을 수 있다. 눌러야 하면 먼저 화면 안으로 끌어온다.
Future<void> _openDisclosure(WidgetTester tester, String title) async {
  final header = find.text(title);
  expect(header, findsOneWidget, reason: 'disclosure header "$title"');
  await tester.ensureVisible(header);
  await tester.pumpAndSettle();
  await tester.tap(header);
  await tester.pumpAndSettle();
}

Future<void> _openAllDisclosures(WidgetTester tester) async {
  final l = _l10n(tester);
  for (final title in [
    l.bonus_candy_expiration_time_title,
    l.bonus_candy_example_title,
    l.bonus_candy_policy_title,
  ]) {
    // 소멸 시점 안내는 소멸 예정 행이 없을 때 이미 펼쳐져 있다.
    final alreadyOpen =
        title == l.bonus_candy_expiration_time_title &&
        find.text(l.bonus_candy_expiration_policy_earn_period).evaluate().isNotEmpty;
    if (alreadyOpen) continue;
    await _openDisclosure(tester, title);
  }
}

Finder get _shellFinder => find.descendant(
  of: find.byType(LargePopupWidget),
  // 셸의 카드 Container 만 antiAlias 클립을 켠다 (large_popup.dart:38).
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.clipBehavior == Clip.antiAlias,
  ),
);

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

void main() {
  // 이 패키지에는 flutter_test_config.dart 가 없어서 파일마다 직접 폰트를
  // 실어야 한다. 폴백 폰트로 재면 오버플로 측정이 전부 어긋난다.
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

  group('T1 오버플로 없음', () {
    // 설정마다 새 위젯 트리여야 한다 — RenderFlex 는 렌더 오브젝트당 오버플로를
    // 한 번만 보고하므로, 트리를 공유하면 두 번째 설정부터 조용해진다.
    for (final size in _devices) {
      for (final locale in const [
        Locale('ko'),
        Locale('en'),
        Locale('fil'),
        Locale('bn'),
      ]) {
        for (final scale in const [1.0, 1.5, 2.0]) {
          testWidgets(
            '${size.width}x${size.height} ${locale.languageCode} x$scale',
            (tester) async {
              await _pumpPopup(
                tester,
                size: size,
                locale: locale,
                textScale: scale,
              );
              expect(tester.takeException(), isNull);
              await _openAllDisclosures(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });

  group('T2 코너 클립 안전 여백', () {
    // 셸은 BorderRadius.circular(120.r) 로 antiAlias 클립한다. 스크롤 뷰포트가
    // 카드 바닥에서 56px 이상 떨어져 있어야 어떤 스크롤 위치에서도 글자가 코너
    // 웨지에 들어가지 않는다.
    for (final size in const [Size(320, 640), Size(411.4, 914.3)]) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpPopup(tester, size: size);

        final shellRect = tester.getRect(_shellFinder);
        final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
        expect(
          shellRect.bottom - scrollRect.bottom,
          greaterThanOrEqualTo(55.0),
          reason: 'viewport bottom must sit >= 56px above the card edge',
        );

        // 끝까지 스크롤해도 뷰포트 자체는 그대로다(패딩이 스크롤 뷰 밖이므로).
        final position = _position(tester);
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        final scrolledRect = tester.getRect(find.byType(SingleChildScrollView));
        expect(
          tester.getRect(_shellFinder).bottom - scrolledRect.bottom,
          greaterThanOrEqualTo(55.0),
        );
      });
    }
  });

  group('T3 점진적 공개', () {
    testWidgets('소멸 예정 행이 있으면 예시는 접혀 있고, 눌러야 열린다', (
      tester,
    ) async {
      await _pumpPopup(tester, size: const Size(393, 873));
      final l = _l10n(tester);

      // 접힌 본문은 트리에서 아예 빠진다(Offstage 가 아니다).
      expect(find.text(l.bonus_candy_example_earn_date), findsNothing);
      expect(find.text(l.bonus_candy_expiration_policy_earn_period), findsNothing);
      // 헤더는 접혀 있어도 보인다.
      expect(find.text(l.bonus_candy_example_title), findsOneWidget);
      expect(find.byKey(const Key('candy-policy-section')), findsOneWidget);
      expect(find.text(l.bonus_candy_policy_1.substring(2)), findsNothing);

      await _openDisclosure(tester, l.bonus_candy_example_title);
      // 레이블은 그룹마다 반복돼 행이 스스로를 설명한다.
      expect(find.text(l.bonus_candy_example_earn_date), findsNWidgets(2));
      expect(
        find.text(l.bonus_candy_example_expiration_date),
        findsNWidgets(2),
      );
    });

    testWidgets('소멸 예정 행이 없으면 소멸 시점 안내가 처음부터 펼쳐진다', (
      tester,
    ) async {
      await _pumpPopup(
        tester,
        size: const Size(393, 873),
        bonusRows: const [],
      );
      final l = _l10n(tester);
      expect(
        find.text(l.bonus_candy_expiration_policy_earn_period),
        findsNWidgets(2),
      );
      expect(find.text(l.bonus_candy_earn_period_1_to_14), findsOneWidget);
      expect(find.text(l.bonus_candy_earn_period_15_to_end), findsOneWidget);
      // 예시는 그대로 접혀 있다.
      expect(find.text(l.bonus_candy_example_earn_date), findsNothing);
    });

    testWidgets('소멸 예정 행은 prediction_month 오름차순으로 정렬된다', (
      tester,
    ) async {
      await _pumpPopup(tester, size: const Size(393, 873));
      final first = tester.getTopLeft(find.text('2026-08-15 (KST)'));
      final second = tester.getTopLeft(find.text('2026-09-15 (KST)'));
      expect(first.dy, lessThan(second.dy));
    });
  });

  testWidgets('T4 기본 상태에서는 스크롤이 없다 (393x873, ko, 소멸 예정 2건)', (
    tester,
  ) async {
    await _pumpPopup(tester, size: const Size(393, 873));
    expect(_position(tester).maxScrollExtent, 0.0);

    // 카드가 내용에 붙는다 — 예전처럼 0.82H 짜리 빈 상자가 되지 않는다.
    final shellRect = tester.getRect(_shellFinder);
    expect(shellRect.height, lessThan(873 * 0.82 - 28));
  });

  group('T5 예시 플레이스홀더 치환 (대소문자 무관)', () {
    // vi/fil 은 __Month__, th 는 전부 소문자, bn 은 올바른 __NEXT_MONTH__ 와
    // 깨진 __The_month_after_next__ 를 섞어 싣고 있다. 대소문자를 구분하던
    // 예전 replaceAll 에서는 이 로케일들이 24자 토큰을 그대로 노출했다.
    for (final locale in const [
      Locale('fil'),
      Locale('th'),
      Locale('vi'),
      Locale('bn'),
    ]) {
      testWidgets(locale.languageCode, (tester) async {
        await _pumpPopup(
          tester,
          size: const Size(393, 873),
          locale: locale,
          loggedIn: false,
        );
        await _openDisclosure(tester, _l10n(tester).bonus_candy_example_title);

        final leaked = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((s) => s.contains('__'))
            .toList();
        expect(leaked, isEmpty, reason: 'raw placeholder leaked to the user');
      });
    }
  });

  group('T6 상태 매트릭스', () {
    testWidgets('보너스 조회 실패가 다이얼로그를 대체하지 않는다', (tester) async {
      await _pumpPopup(
        tester,
        size: const Size(393, 873),
        bonusError: StateError('bonus unavailable'),
      );
      final l = _l10n(tester);

      // 실패는 보너스 카드 안에서만 말하고, 나머지는 전부 살아 있다.
      expect(
        find.text(l.bonus_candy_expiration_policy_load_fail),
        findsOneWidget,
      );
      expect(find.byKey(const Key('cotton-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('bonus-star-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('candy-policy-section')), findsOneWidget);
      expect(find.text(l.cotton_candy_daily_expiry_notice), findsOneWidget);
      // 개인 행이 없으니 소멸 시점 안내는 펼쳐져 있다.
      expect(
        find.text(l.bonus_candy_expiration_policy_earn_period),
        findsNWidgets(2),
      );
    });

    testWidgets('비로그인: 히어로가 없고 두 카드와 세 구분선은 남는다', (
      tester,
    ) async {
      await _pumpPopup(
        tester,
        size: const Size(393, 873),
        loggedIn: false,
      );
      expect(find.byKey(const Key('expiry-today-summary')), findsNothing);
      expect(find.byKey(const Key('cotton-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('bonus-star-candy-section')), findsOneWidget);
      // 표를 지운 뒤에도 구분선은 남아야 한다(기존 테스트 :281 이 이걸 본다).
      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('0 소멸 예정은 긴급 강조색을 쓰지 않는다', (tester) async {
      final zero = WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.zero,
        bonus: BigInt.zero,
        cotton: BigInt.zero,
        cottonExpiringAmount: BigInt.zero,
        cottonNextExpiresAt: null,
        snapshotAt: DateTime.utc(2026, 7, 23),
      );
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
      tester.view.physicalSize = const Size(393, 873) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: true,
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          extraOverrides: [
            expireBonusProvider.overrideWith((ref) async => const []),
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository.value(zero),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final hero = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('expiry-today-summary')),
          matching: find.byType(Text),
        ),
      );
      expect(hero.style?.fontSize, 14.0);
      expect(hero.style?.fontWeight, FontWeight.w500);
    });
  });
}
