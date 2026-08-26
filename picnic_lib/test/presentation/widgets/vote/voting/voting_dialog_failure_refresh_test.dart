import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_transaction_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Regression guard for `47a945db9` — "make post-failure wallet refresh
/// non-blocking".
///
/// The general-vote failure path used to `await walletSummaryProvider.refresh()`
/// *before* restoring the UI, so a hanging refresh delayed the error dialog and
/// a throwing refresh escaped the catch block entirely, masking the real vote
/// error. Every test here drives a real vote submission through
/// `_VotingDialogState._votingGeneral` and asserts that the failure handling —
/// loading overlay hidden, dialog dismissed, voting state restored, original
/// error surfaced — completes *without* waiting on the wallet refresh.
///
/// These tests go red if the refresh is ever awaited ahead of the failure
/// handling again.

/// Message the server sends back for the failed vote. Surfaced verbatim by
/// [VotingDialogHelper.resolveVoteFailureMessage].
const _voteFailureMessage = 'VOTE_REJECTED_BY_SERVER';

/// Message attached to a *wallet refresh* failure. Must never reach the user.
const _refreshFailureMessage = 'WALLET_REFRESH_EXPLODED';

/// Status 500 (not 401) so the auth-recovery path is not involved: the error
/// propagates straight into the catch block under test.
const _voteError = FunctionException(
  status: 500,
  details: {'message': _voteFailureMessage},
);

/// Wallet notifier whose [refresh] behaviour is fully controlled by the test.
class _ControllableWalletSummary extends WalletSummary {
  _ControllableWalletSummary({required this.summary, required this.onRefresh});

  final WalletSummaryModel summary;
  final Future<void> Function() onRefresh;
  int _calls = 0;

  @override
  Future<WalletSummaryModel> build() async => summary;

  /// The dialog also refreshes once when it opens, to keep "use all" off a
  /// stale snapshot. That call is not what these tests are about, so only the
  /// second refresh - the post-failure one - runs the scripted behaviour.
  @override
  Future<void> refresh() {
    _calls += 1;
    if (_calls == 1) return Future<void>.value();
    return onRefresh();
  }
}

/// Vote repository that fails, but only once the test opens [gate]. Holding the
/// RPC open lets the test observe the in-flight state (loading overlay up,
/// submit button disabled) before the failure path runs.
class _GatedFailingVoteRepository extends VoteTransactionRepository {
  _GatedFailingVoteRepository(super.client, {required this.gate});

  final Future<void> gate;

  @override
  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    await gate;
    throw _voteError;
  }
}

WalletSummaryModel _wallet(BigInt cotton) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: cotton,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026, 7, 21),
);

/// The loading overlay renders into the root [Overlay], so it is not a
/// descendant of [VotingDialog]. Match its semantics wrapper instead.
final Finder _visibleLoadingOverlay = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == '로딩 중입니다',
  description: 'visible LoadingOverlayWithIcon content',
);

final Finder _failDialog = find.byIcon(Icons.error_outline);

/// Pumps the dialog, submits a vote, and returns while the vote RPC is still
/// in flight (blocked on [voteGate]).
Future<void> _submitVoteAndHoldInFlight(
  WidgetTester tester, {
  required Completer<void> voteGate,
  required Future<void> Function() onWalletRefresh,
}) async {
  // Tall viewport so the whole dialog — including the submit button — is laid
  // out on screen and hit-testable.
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
      extraOverrides: [
        walletSummaryProvider.overrideWith(
          () => _ControllableWalletSummary(
            summary: _wallet(BigInt.from(1000)),
            onRefresh: onWalletRefresh,
          ),
        ),
        voteTransactionRepositoryProvider.overrideWithValue(
          _GatedFailingVoteRepository(supabase, gate: voteGate.future),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();

  // Open the vote dialog as a real route so the failure path's Navigator.pop
  // has something of its own to dismiss.
  await tester.tap(find.text('open-voting-dialog'));
  await tester.pumpAndSettle();
  expect(find.byType(VotingDialog), findsOneWidget);
  expect(_visibleLoadingOverlay, findsNothing);

  await tester.enterText(find.byType(TextFormField), '5');
  await tester.pumpAndSettle();

  await tester.tap(find.byType(VotingSubmitButton));
  // No pumpAndSettle from here on: the loading overlay runs repeating
  // animations, so the tree never settles while a vote is in flight.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));

  // Sanity check that we really are mid-vote: overlay up, button spinning.
  expect(
    _visibleLoadingOverlay,
    findsOneWidget,
    reason: 'loading overlay should be visible while the vote is in flight',
  );
  expect(
    find.descendant(
      of: find.byType(VotingSubmitButton),
      matching: find.byType(CircularProgressIndicator),
    ),
    findsOneWidget,
    reason: '_isVoting should be true while the vote is in flight',
  );
}

/// Asserts the complete post-failure UI contract.
void _expectFailureHandlingCompleted() {
  expect(
    find.byType(VotingDialog),
    findsNothing,
    reason: 'the voting dialog must be dismissed',
  );
  expect(
    find.byType(LoadingOverlayWithIcon),
    findsNothing,
    reason: 'the loading overlay host must be gone with the dialog',
  );
  expect(
    _visibleLoadingOverlay,
    findsNothing,
    reason: 'the loading overlay must be hidden',
  );
  expect(
    find.byType(VotingSubmitButton),
    findsNothing,
    reason: 'the voting state must be torn down, not left mid-vote',
  );
  expect(
    _failDialog,
    findsOneWidget,
    reason: 'the vote failure dialog must be shown',
  );
  expect(
    find.text(_voteFailureMessage),
    findsOneWidget,
    reason: 'the original vote error must be the message shown to the user',
  );
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

  group('VotingDialog general-vote failure vs. wallet refresh', () {
    testWidgets(
      'a wallet refresh that never completes does not block the failure UI',
      (tester) async {
        final voteGate = Completer<void>();
        final refreshStarted = Completer<void>();
        // Never completed while the assertions run — the failure handling must
        // not be waiting on it.
        final refreshGate = Completer<void>();

        await _submitVoteAndHoldInFlight(
          tester,
          voteGate: voteGate,
          onWalletRefresh: () {
            if (!refreshStarted.isCompleted) refreshStarted.complete();
            return refreshGate.future;
          },
        );

        // Fail the vote. Only the fail-dialog transition (300ms) and the route
        // pop are advanced here — nowhere near the refresh's 5s timeout.
        voteGate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          refreshStarted.isCompleted,
          isTrue,
          reason: 'the post-failure wallet refresh should have been kicked off',
        );
        expect(
          refreshGate.isCompleted,
          isFalse,
          reason:
              'the refresh must still be hanging while these assertions run, '
              'otherwise this test proves nothing',
        );
        _expectFailureHandlingCompleted();
        expect(tester.takeException(), isNull);

        // Release the hung refresh so its timeout timer does not outlive the
        // test. This is cleanup, not part of the assertion.
        refreshGate.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets(
      'a wallet refresh that throws does not replace the original vote error',
      (tester) async {
        final voteGate = Completer<void>();
        var refreshCalls = 0;

        await _submitVoteAndHoldInFlight(
          tester,
          voteGate: voteGate,
          onWalletRefresh: () async {
            refreshCalls++;
            throw StateError(_refreshFailureMessage);
          },
        );

        voteGate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(refreshCalls, 1);
        _expectFailureHandlingCompleted();
        expect(
          find.textContaining(_refreshFailureMessage),
          findsNothing,
          reason: 'the refresh failure must not be surfaced to the user',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'the refresh failure must be swallowed, not rethrown',
        );
      },
    );

    testWidgets(
      'control: a wallet refresh that completes normally behaves the same way',
      (tester) async {
        final voteGate = Completer<void>();
        var refreshCalls = 0;

        await _submitVoteAndHoldInFlight(
          tester,
          voteGate: voteGate,
          onWalletRefresh: () async {
            refreshCalls++;
            // A healthy refresh is still a round trip, so it resolves later
            // than the failure UI must. The assertions below run at +350ms.
            await Future<void>.delayed(const Duration(seconds: 2));
          },
        );

        voteGate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(refreshCalls, 1);
        _expectFailureHandlingCompleted();
        expect(tester.takeException(), isNull);

        // Let the healthy refresh land; nothing about the UI may change.
        await tester.pump(const Duration(seconds: 3));
        _expectFailureHandlingCompleted();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
