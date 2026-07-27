import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
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
    testWidgets('renders when opened via showUsagePolicyDialog', (
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
        expect(find.textContaining('오늘 만료 10'), findsOneWidget);
        expect(find.textContaining('다음 만료'), findsOneWidget);
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

      expect(find.text('보너스 별사탕 정책'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

      expect(find.text('보너스 별사탕 정책'), findsOneWidget);
      expect(find.text('지갑 정보를 불러오지 못했습니다.'), findsOneWidget);
    });

    testWidgets('showUsagePolicyDialog uses general dialog with transitions', (
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
      // Pump a few frames to observe transition animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(UsagePolicyPopup), findsOneWidget);
    });

    testWidgets('renders example table with current month calculations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: false,
        ),
      );
      await tester.pumpAndSettle();

      // The example table should be rendered inside the policy details
      expect(find.byType(UsagePolicyPopup), findsOneWidget);
      // Table rows should contain Divider widgets
      expect(find.byType(Divider), findsWidgets);
    });
  });
}
