import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository(this.summary) : super(_UnusedClient());
  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> getSummary() async => summary;

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// Answers each `getSummary()` from a script, so a failure can be followed by a
/// success (or the other way round).
class _ScriptedWalletRepository extends WalletRepository {
  _ScriptedWalletRepository(this.responses) : super(_UnusedClient());

  final List<Future<WalletSummaryModel> Function()> responses;
  int calls = 0;

  @override
  Future<WalletSummaryModel> getSummary() => responses[calls++]();

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

WalletSummaryModel _summary(int star) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(star),
  bonus: BigInt.from(301),
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 23),
);

void main() {
  setUp(initTestColors);

  testWidgets(
    'shows all localized currencies, precise amounts and server expiry',
    (tester) async {
      final summary = WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.parse('9007199254740993'),
        bonus: BigInt.from(20),
        cotton: BigInt.from(30),
        cottonExpiringAmount: BigInt.from(10),
        cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
        snapshotAt: DateTime.utc(2026, 7, 23),
      );
      await tester.pumpWidget(
        buildTestApp(
          const WalletSummaryPanel(),
          extraOverrides: [
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository(summary),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('스타캔디'), findsOneWidget);
      expect(find.text('보너스 스타캔디'), findsOneWidget);
      expect(find.text('코튼캔디'), findsOneWidget);
      expect(find.text('9,007,199,254,740,993'), findsOneWidget);
      expect(find.textContaining('오늘 만료 10'), findsOneWidget);
      expect(find.textContaining('다음 만료'), findsOneWidget);
      expect(find.byKey(const Key('wallet-star-card')), findsOneWidget);
      expect(find.byKey(const Key('wallet-bonus-card')), findsOneWidget);
      expect(find.byKey(const Key('wallet-cotton-card')), findsOneWidget);
      expect(find.byKey(const Key('wallet-cotton-expiry')), findsOneWidget);
      for (final label in ['스타캔디', '보너스 스타캔디', '코튼캔디']) {
        expect(tester.widget<Text>(find.text(label)).textAlign, TextAlign.left);
      }

      final cottonCard = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(const Key('wallet-cotton-card')),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = cottonCard.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFF7FB));
      expect(decoration.border, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  // A failed read used to end at a single line of text with nothing to press,
  // so the only way out was to kill the app.
  testWidgets('a failed read offers a retry that renders the balance', (
    tester,
  ) async {
    final repository = _ScriptedWalletRepository([
      () async => throw Exception('offline'),
      // riverpod retries the failed build once (walletSummaryRetry) before the
      // error becomes the settled state.
      () async => throw Exception('still offline'),
      () async => _summary(3500),
    ]);
    await tester.pumpWidget(
      buildTestApp(
        const WalletSummaryPanel(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    // Past the automatic retry's backoff, so the error has settled.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('wallet-summary-error')), findsOneWidget);
    expect(find.text('지갑 정보를 불러오지 못했습니다.'), findsOneWidget);

    final retry = find.byKey(const Key('wallet-summary-retry'));
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('wallet-summary-error')), findsNothing);
    expect(find.text('3,500'), findsOneWidget);
    expect(find.text('301'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // The background re-read after a purchase or a watched ad. Its failure must
  // not take the balance off screen - the candy was granted either way, and the
  // value shown was correct.
  testWidgets('a failed refresh leaves the displayed balance alone', (
    tester,
  ) async {
    final repository = _ScriptedWalletRepository([
      () async => _summary(3500),
      () async => throw Exception('network went away'),
    ]);
    await tester.pumpWidget(
      buildTestApp(
        const WalletSummaryPanel(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3,500'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WalletSummaryPanel)),
      listen: false,
    );
    await container.read(walletSummaryProvider.notifier).refresh();
    await tester.pump();

    expect(
      find.text('3,500'),
      findsOneWidget,
      reason: 'the last known balance stays on screen',
    );
    expect(find.byKey(const Key('wallet-summary-error')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.calls, 2);
  });
}
