import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_skeleton.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

class _PendingRepository extends WalletRepository {
  _PendingRepository(this.response) : super(_UnusedClient());

  final Future<WalletSummaryModel> response;

  @override
  Future<WalletSummaryModel> getSummary() => response;

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

/// A wallet with nothing expiring, so the panel renders the three segments and
/// no expiry banner - the layout the skeleton stands in for.
final _summary = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(3500),
  bonus: BigInt.from(301),
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 23),
);

void main() {
  setUp(initTestColors);

  testWidgets('the loading state pulses instead of spinning', (tester) async {
    final pending = Completer<WalletSummaryModel>();
    await tester.pumpWidget(
      buildTestApp(
        const WalletSummaryPanel(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(
            _PendingRepository(pending.future),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(WalletSummarySkeleton), findsOneWidget);
    expect(
      find.byType(Shimmer),
      findsNWidgets(3),
      reason:
          'the pouch must use the shimmer skeleton the rest of the app uses '
          '(vote cards, product lists), one per currency segment',
    );
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the pouch was the only card in the app loading with a spinner',
    );

    pending.complete(_summary);
    await tester.pump();
    await tester.pump();

    expect(find.byType(Shimmer), findsNothing);
    expect(find.text('3,500'), findsOneWidget);
  });

  // Guards the skeleton against structural drift from the card it stands in for
  // (a dropped row, a wrong icon size), which is what would make the pouch jump
  // the moment the balance lands. The placeholder bars are sized to the text
  // line boxes rather than derived from them, so a pixel or two of slack is
  // allowed - production renders Pretendard, this renders the test font.
  testWidgets('the skeleton stands in for the card at the same height', (
    tester,
  ) async {
    // Both in one tree: the shimmer never settles, so the loaded panel cannot
    // be measured in a second pumpWidget of its own.
    await tester.pumpWidget(
      buildTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 361, child: WalletSummaryPanel()),
            SizedBox(width: 361, child: WalletSummarySkeleton()),
          ],
        ),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(
            _PendingRepository(Future.value(_summary)),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('3,500'), findsOneWidget);

    final loaded = tester.getSize(find.byType(WalletSummaryPanel)).height;
    final skeleton = tester.getSize(find.byType(WalletSummarySkeleton)).height;

    expect(
      (skeleton - loaded).abs(),
      lessThan(2),
      reason:
          'the card must not jump when the balance arrives '
          '(skeleton $skeleton vs loaded $loaded)',
    );
  });
}
