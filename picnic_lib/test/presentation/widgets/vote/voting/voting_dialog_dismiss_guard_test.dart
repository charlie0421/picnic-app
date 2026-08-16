import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_transaction_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Nothing stopped the voting dialog from being popped *while a vote was in
/// flight*. The HTTP chain keeps running against a captured ProviderContainer,
/// so a user who closes the spinner, reopens the dialog and votes again submits
/// a **second** `request_id` — server-side idempotency keys off `request_id`,
/// so both votes settle and both are charged.
///
/// The modal barrier is not the reachable path: the loading overlay is a
/// full-screen opaque `Positioned.fill` inserted above the dialog route, so it
/// swallows barrier taps on its own. System back is, and it pops the route
/// straight through the overlay.
///
/// That window used to be one 30s HTTP budget. Reconciling a lost response
/// (`VoteTransactionRepository.performGeneralVote`) stretches it to ~94s, so the
/// hazard is materially wider and the dialog must refuse to close mid-vote.
///
/// Dismissal before the vote must keep working — this guards the in-flight
/// window only.
class _HangingVoteRepository extends VoteTransactionRepository {
  _HangingVoteRepository(super.client, {required this.gate});

  final Future<void> gate;

  @override
  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    await gate;
    throw StateError('gate released without a scripted outcome');
  }
}

class _StaticWalletSummary extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() async => _wallet();

  @override
  Future<void> refresh() async {}
}

WalletSummaryModel _wallet() => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.from(1000),
  bonus: BigInt.zero,
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 8, 16),
);

Future<void> _openDialog(
  WidgetTester tester, {
  required Completer<void> voteGate,
}) async {
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
            barrierDismissible: true,
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
      extraOverrides: [
        walletSummaryProvider.overrideWith(_StaticWalletSummary.new),
        voteTransactionRepositoryProvider.overrideWithValue(
          _HangingVoteRepository(supabase, gate: voteGate.future),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open-voting-dialog'));
  await tester.pumpAndSettle();
  expect(find.byType(VotingDialog), findsOneWidget);
}

/// Presses the Android system back button.
Future<void> _pressSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
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

  testWidgets('system back cannot dismiss the dialog while a vote is in flight',
      (tester) async {
    final voteGate = Completer<void>();
    addTearDown(() {
      if (!voteGate.isCompleted) voteGate.complete();
    });

    await _openDialog(tester, voteGate: voteGate);

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(VotingSubmitButton));
    // The loading overlay animates forever, so never settle mid-vote.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.descendant(
        of: find.byType(VotingSubmitButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
      reason: 'the vote must still be in flight for this test to mean anything',
    );

    await _pressSystemBack(tester);

    expect(
      find.byType(VotingDialog),
      findsOneWidget,
      reason:
          'dismissing mid-vote leaves the request running and lets the user '
          'submit a second request_id, which is charged separately',
    );
  });

  testWidgets('system back still dismisses the dialog before a vote starts', (
    tester,
  ) async {
    final voteGate = Completer<void>();
    addTearDown(() {
      if (!voteGate.isCompleted) voteGate.complete();
    });

    await _openDialog(tester, voteGate: voteGate);

    await _pressSystemBack(tester);
    await tester.pumpAndSettle();

    expect(
      find.byType(VotingDialog),
      findsNothing,
      reason: 'the guard must only cover the in-flight window',
    );
  });
}
