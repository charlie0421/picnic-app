import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_transaction_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// A vote settles against the account that cast it, and the wallet it comes
/// back with is that account's balance. The RPC takes as long as the network
/// takes - and `invokeVotingWithAuthRecovery` will even refresh the session and
/// retry inside that window - so the user has room to sign out or switch
/// accounts before the result lands.
///
/// The dialog captures the app-level container up front (PICNIC-APP-530) so the
/// settlement still applies after the route is gone. That capture is what makes
/// the write survive; without the account captured alongside it, it is also
/// what carries one account's balance onto another's screen (PICNIC-2664).

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);

  @override
  final String id;
}

class _FakeSession extends Fake implements Session {
  _FakeSession(String userId) : user = _FakeUser(userId);

  @override
  final User user;
}

class _SwitchableAuthGateway implements WalletAuthGateway {
  _SwitchableAuthGateway(String userId) : _session = _FakeSession(userId);

  final _changes = StreamController<AuthState>.broadcast(sync: true);
  Session? _session;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges => _changes.stream;

  void signIn(String userId) {
    final session = _FakeSession(userId);
    _session = session;
    _changes.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  Future<void> close() => _changes.close();
}

/// Holds the vote open so the test can switch accounts mid-flight, then answers
/// with the balance the *first* account's vote settled at.
class _GatedVoteRepository extends VoteTransactionRepository {
  _GatedVoteRepository(
    super.client, {
    required this.gate,
    required this.result,
  });

  final Future<void> gate;
  final VoteTransactionResultModel result;

  @override
  Future<VoteTransactionResultModel> performGeneralVote(
    VoteTransactionRequest request,
  ) async {
    await gate;
    return result;
  }
}

class _FixedWalletSummary extends WalletSummary {
  _FixedWalletSummary(this.summary);

  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> build() async => summary;

  @override
  Future<void> refresh() async {}
}

WalletSummaryModel _wallet(int star, {DateTime? snapshotAt}) =>
    WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.from(star),
      bonus: BigInt.zero,
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: snapshotAt ?? DateTime.utc(2026, 7, 21),
    );

void main() {
  setUpAll(initTestColors);
  setUp(() => setupMockSupabase(const {}));
  tearDown(tearDownMockSupabase);

  testWidgets('a vote cast by owner A never lands on owner B', (tester) async {
    final voteGate = Completer<void>();
    final gateway = _SwitchableAuthGateway('owner-a');
    addTearDown(gateway.close);

    // Owner A's vote settles at 500 - stamped late so the snapshotAt ordering
    // rule cannot be what rejects it. Only ownership can.
    final settledForA = _wallet(500, snapshotAt: DateTime.utc(2099));

    tester.view.physicalSize = const Size(1800, 3600);
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
          walletAuthGatewayProvider.overrideWithValue(gateway),
          walletSummaryProvider.overrideWith(
            () => _FixedWalletSummary(_wallet(1000)),
          ),
          voteTransactionRepositoryProvider.overrideWithValue(
            _GatedVoteRepository(
              supabase,
              gate: voteGate.future,
              result: VoteTransactionResultModel(
                operationId: 'op-1',
                replayed: false,
                votePickId: 1,
                updatedVoteTotal: 5,
                addedVoteTotal: 5,
                updatedAt: DateTime.utc(2026, 7, 21),
                usage: VoteUsageModel(
                  cottonCandy: BigInt.zero,
                  bonusStarCandy: BigInt.zero,
                  starCandy: BigInt.from(5),
                ),
                wallet: settledForA,
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-voting-dialog'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VotingDialog)),
      listen: false,
    );
    await container.read(walletSummaryProvider.future);

    await tester.tap(find.byType(VotingSubmitButton));
    await tester.pump();

    // The user walks out of the vote while the RPC is in flight. This is the
    // case the captured container exists for (PICNIC-APP-530) - the settlement
    // still has to apply - and it is also how the write outlives any check the
    // widget could have made for itself.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    await tester.pump();

    // ... and signs in as somebody else.
    gateway.signIn('owner-b');
    await tester.pump();

    voteGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      container.read(walletSummaryProvider).value!.star,
      BigInt.from(1000),
      reason:
          'owner A cast this vote and the 500 is what A has left; owner B is '
          'the one looking at the pouch now',
    );

    // Let the in-flight overlay/safety timers fire so the binding does not
    // report them as leaked, and drain the asset failures the teardown frames
    // raise (the test bundle has no images).
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    while (tester.takeException() != null) {}
  });
}
