import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository.value(WalletSummaryModel summary)
    : loadSummary = (() async => summary),
      super(_UnusedClient());

  _WalletRepository.error(Object error)
    : loadSummary = (() async => throw error),
      super(_UnusedClient());

  _WalletRepository.loading()
    : loadSummary = (() => Completer<WalletSummaryModel>().future),
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

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('UsagePolicyPopup', () {
    testWidgets('renders fullscreen dialog and closes from its close button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUsagePolicyDialog(context),
              child: const Text('Open'),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
      expect(find.byType(FullScreenDialog), findsOneWidget);
      expect(find.byType(LargePopupWidget), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsNothing);
      expect(find.byType(FullScreenDialog), findsNothing);
    });

    testWidgets('renders UsagePolicyPopup directly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('centers the policy title within UsagePolicyPopup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      final popup = tester.getRect(find.byType(UsagePolicyPopup));
      final title = tester.getRect(find.byType(VoteCommonTitle));

      expect(title.center.dx, closeTo(popup.center.dx, 0.01));
    });

    testWidgets('renders policy content with scrollable area', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets(
      'renders non-logged-in policy content (no expiring data section)',
      (WidgetTester tester) async {
        // isSupabaseLoggedSafely = false since no auth session
        await tester.pumpWidget(
          buildTestAppPage(
            const Material(
              color: Colors.transparent,
              child: UsagePolicyPopup(),
            ),
            loggedIn: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(UsagePolicyPopup), findsOneWidget);
        // Should have policy content but not the expiring bonus section header
      },
    );

    testWidgets('renders with logged-in state using auth mock', (
      WidgetTester tester,
    ) async {
      // Set up Supabase with auth to make isSupabaseLoggedSafely true
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');

      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('shows the Bonus Star Candy expiration guide header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      final header = find.ancestor(
        of: find.text('보너스 스타캔디 소멸 시점 안내'),
        matching: find.byType(Row),
      );
      expect(header, findsOneWidget);
      expect(
        find.descendant(
          of: header,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/icons/store/currency_bonus_star_candy.png',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows Cotton Candy expiry only from the server wallet snapshot',
      (WidgetTester tester) async {
        await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
        final summary = WalletSummaryModel(
          contractVersion: 'wallet.v1',
          star: BigInt.zero,
          bonus: BigInt.zero,
          cotton: BigInt.from(50),
          cottonExpiringAmount: BigInt.from(10),
          cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
          snapshotAt: DateTime.utc(2026, 7, 23),
        );

        await tester.pumpWidget(
          buildTestAppPage(
            const Material(
              color: Colors.transparent,
              child: UsagePolicyPopup(),
            ),
            loggedIn: true,
            extraOverrides: [
              expireBonusProvider.overrideWith((ref) async => const []),
              walletRepositoryProvider.overrideWithValue(
                _WalletRepository.value(summary),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('코튼캔디'), findsOneWidget);
        // 오늘 만료 요약은 두 재화를 한 줄로 합친다. 보너스는 소멸일에만 붙는다.
        expect(find.textContaining('오늘 만료 : 코튼캔디 10'), findsOneWidget);
        // "다음 만료" 줄은 제거됨 — 코튼캔디는 소멸 규칙 한 줄로 안내한다.
        expect(find.textContaining('다음 만료'), findsNothing);
        expect(find.text('매일 자정 00:00:00 (KST) 에 소멸됩니다.'), findsOneWidget);
        expect(
          find.byKey(const Key('bonus-star-candy-section')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('candy-policy-section')), findsOneWidget);
      },
    );

    testWidgets('keeps Bonus policy visible while wallet is loading', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: true,
          extraOverrides: [
            expireBonusProvider.overrideWith((ref) async => const []),
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository.loading(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Picnic! 캔디 정책'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 파우치 읽기에는 상한(kWalletSummaryReadTimeout)이 걸려 있다. 그 타이머를
      // 흘려보내지 않으면 테스트 종료 시 'Timer is still pending' 으로 깨진다
      // (origin/main 에서도 깨져 있던 사전 실패).
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
    });

    testWidgets('keeps Bonus policy visible when wallet loading fails', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: true,
          extraOverrides: [
            expireBonusProvider.overrideWith((ref) async => const []),
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository.error(StateError('wallet unavailable')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Picnic! 캔디 정책'), findsOneWidget);
      expect(find.text('지갑 정보를 불러오지 못했습니다.'), findsOneWidget);
    });

    testWidgets('showUsagePolicyDialog settles without a scale transition', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showUsagePolicyDialog(context),
              child: const Text('Open'),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      // 공통 전체 화면 라우트의 전환 시간이 끝날 때까지 진행한다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('renders example months from an injected reference date', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(
              exampleReferenceDate: DateTime.utc(2032, 3, 1),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3월 10일 14:00(KST)'), findsOneWidget);
      expect(find.text('4월 15일 00:00(KST)'), findsOneWidget);
      expect(find.text('3월 20일 14:00(KST)'), findsOneWidget);
      expect(find.text('5월 15일 00:00(KST)'), findsOneWidget);
    });

    testWidgets('rolls the month after next from November into January', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(
              exampleReferenceDate: DateTime.utc(2032, 11, 1),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('11월 10일 14:00(KST)'), findsOneWidget);
      expect(find.text('12월 15일 00:00(KST)'), findsOneWidget);
      expect(find.text('11월 20일 14:00(KST)'), findsOneWidget);
      expect(find.text('1월 15일 00:00(KST)'), findsOneWidget);
      expect(find.textContaining('13월'), findsNothing);
    });

    testWidgets('uses the KST month at a UTC month boundary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          Material(
            color: Colors.transparent,
            child: UsagePolicyPopup(
              // 2032-12-01 00:30 KST.
              exampleReferenceDate: DateTime.utc(2032, 11, 30, 15, 30),
            ),
          ),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12월 10일 14:00(KST)'), findsOneWidget);
      expect(find.text('1월 15일 00:00(KST)'), findsOneWidget);
      expect(find.text('12월 20일 14:00(KST)'), findsOneWidget);
      expect(find.text('2월 15일 00:00(KST)'), findsOneWidget);
    });
  });

  group('bonusExpiringToday', () {
    const data = [
      {'prediction_month': '2026-08', 'expiring_amount': 120},
      {'prediction_month': '2026-09', 'expiring_amount': 30},
    ];

    test('소멸일(15일 KST)에는 그 달 몫을 돌려준다', () {
      // 2026-08-15 00:30 KST == 2026-08-14 15:30 UTC
      expect(
        bonusExpiringToday(data, nowUtc: DateTime.utc(2026, 8, 14, 15, 30)),
        120,
      );
    });

    test('소멸일이 아니면 0 (줄에 보너스가 붙지 않는다)', () {
      expect(bonusExpiringToday(data, nowUtc: DateTime.utc(2026, 8, 20, 3)), 0);
    });

    test('그 달 예정분이 없으면 0', () {
      expect(
        bonusExpiringToday(const [
          {'prediction_month': '2026-09', 'expiring_amount': 30},
        ], nowUtc: DateTime.utc(2026, 8, 14, 15, 30)),
        0,
      );
    });

    test('데이터가 없으면 0', () {
      expect(bonusExpiringToday(null), 0);
    });
  });
}
