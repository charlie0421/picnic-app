import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// `walletSummaryProvider` is `keepAlive: true` with no TTL and no refresh on
/// app resume, and "use all" writes that cached total into the amount field
/// verbatim. The server expires Cotton grants and Bonus buckets at vote time
/// before computing the balance, so a snapshot taken hours earlier can exceed
/// what is actually spendable — the vote comes back 409
/// WALLET_INSUFFICIENT_BALANCE even though the client pre-check passed. That is
/// the single most common vote failure in production (13 of 32 events over 14
/// days, 15 distinct users).
///
/// Two things have to hold: the dialog must not open on a stale snapshot, and
/// when the server does reject for balance the user must be told why instead of
/// a bare "vote failed".
class _RefreshCountingWalletSummary extends WalletSummary {
  int refreshCount = 0;

  @override
  Future<WalletSummaryModel> build() async => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.from(1000),
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 8, 16),
  );

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }
}

void main() {
  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    setupMockSupabase(const {});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('insufficient balance is named, not swallowed', () {
    const rechargeMessage = '충전이 필요합니다.';

    // The Edge Function answers `{"error": "WALLET_INSUFFICIENT_BALANCE"}`, so
    // the details map has no `message` key and the old code fell through to the
    // generic failure title.
    test('409 WALLET_INSUFFICIENT_BALANCE resolves to the recharge message', () {
      final message = VotingDialogHelper.resolveVoteFailureMessage(
        error: const FunctionException(
          status: 409,
          details: {'error': 'WALLET_INSUFFICIENT_BALANCE'},
        ),
        reLoginMessage: 'Re-login',
        genericMessage: 'Vote failed',
        endedMessage: 'Voting ended',
        upcomingMessage: 'Voting not started',
        insufficientBalanceMessage: rechargeMessage,
      );

      expect(message, rechargeMessage);
    });

    test('a different 409 keeps the generic message', () {
      final message = VotingDialogHelper.resolveVoteFailureMessage(
        error: const FunctionException(
          status: 409,
          details: {'error': 'OP_IDEMPOTENCY_CONFLICT'},
        ),
        reLoginMessage: 'Re-login',
        genericMessage: 'Vote failed',
        endedMessage: 'Voting ended',
        upcomingMessage: 'Voting not started',
        insufficientBalanceMessage: rechargeMessage,
      );

      expect(message, 'Vote failed');
    });
  });

  testWidgets('opening the dialog refreshes the wallet snapshot', (
    tester,
  ) async {
    final wallet = _RefreshCountingWalletSummary();
    tester.view.physicalSize = const Size(1125, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => VotingDialog(
                voteModel: MockData.vote(),
                voteItemModel: MockData.voteItem(),
                portalType: VotePortal.vote,
              ),
            ),
            child: const Text('open-voting-dialog'),
          ),
        ),
        userProfile: MockData.userProfile(starCandy: 1000, starCandyBonus: 0),
        extraOverrides: [walletSummaryProvider.overrideWith(() => wallet)],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      wallet.refreshCount,
      0,
      reason: 'nothing should refresh before the dialog opens',
    );

    await tester.tap(find.text('open-voting-dialog'));
    await tester.pumpAndSettle();

    expect(
      wallet.refreshCount,
      1,
      reason:
          'the amount field is filled from this snapshot, so it must be read '
          'fresh when the dialog opens',
    );
  });
}
