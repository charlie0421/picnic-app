import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_transaction_provider.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/ignore_image_errors.dart';
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

/// Types an amount with the keyboard up and hands back the input's own focus
/// node.
///
/// The node is the observable, not `FocusManager.primaryFocus`: a scope can own
/// the primary focus while no editable does, so only "this field still holds
/// focus" distinguishes a leaked keyboard from a clean handover.
Future<FocusNode> _focusAmountInput(WidgetTester tester) async {
  final field = find.byType(TextFormField);
  await tester.showKeyboard(field);
  await tester.enterText(field, '5');
  await tester.pump();

  final node = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
  expect(node.hasPrimaryFocus, isTrue);
  expect(tester.testTextInput.hasAnyClients, isTrue);
  return node;
}

/// Asserts the editing session is over *while the route is still leaving*.
///
/// Waiting for the dialog to finish unmounting proves nothing: `dispose` tears
/// the connection down on its own, so the assertion has to land in the window
/// where the popup is still on screen.
void _expectEditingReleased(WidgetTester tester, FocusNode node) {
  expect(
    node.hasFocus,
    isFalse,
    reason: 'the amount field still held focus while the dialog was leaving',
  );
  expect(FocusManager.instance.primaryFocus, isNot(same(node)));
  expect(
    tester.testTextInput.hasAnyClients,
    isFalse,
    reason: 'the text input connection outlived the dismissal',
  );
}

Finder _topClose() => find.byKey(kLargePopupTopCloseKey);

LargePopupWidget _popup(WidgetTester tester) =>
    tester.widget<LargePopupWidget>(find.byType(LargePopupWidget));

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

  testWidgets(
    'system back cannot dismiss the dialog while a vote is in flight',
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
      await pumpAndIgnoreErrors(tester);
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.descendant(
          of: find.byType(VotingSubmitButton),
          matching: find.byType(SmallPulseLoadingIndicator),
        ),
        findsOneWidget,
        reason:
            'the vote must still be in flight for this test to mean anything',
      );

      await _pressSystemBack(tester);

      expect(
        find.byType(VotingDialog),
        findsOneWidget,
        reason:
            'dismissing mid-vote leaves the request running and lets the user '
            'submit a second request_id, which is charged separately',
      );
    },
  );

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

  group('dismissing with the keyboard up (PICNIC-2695)', () {
    final l10n = AppLocalizationsKo();

    testWidgets('a barrier tap releases the amount field as the route leaves', (
      tester,
    ) async {
      final voteGate = Completer<void>();
      addTearDown(() {
        if (!voteGate.isCompleted) voteGate.complete();
      });

      await _openDialog(tester, voteGate: voteGate);
      final node = await _focusAmountInput(tester);

      // Outside the popup: the harness centres a 345 wide capsule in a 375
      // viewport, so the top-left corner is barrier.
      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(VotingDialog),
        findsOneWidget,
        reason: 'the reverse transition must still be running here',
      );
      _expectEditingReleased(tester, node);

      await tester.pumpAndSettle();
      expect(find.byType(VotingDialog), findsNothing);
      expect(find.text('open-voting-dialog'), findsOneWidget);
    });

    testWidgets('system back releases the amount field as the route leaves', (
      tester,
    ) async {
      final voteGate = Completer<void>();
      addTearDown(() {
        if (!voteGate.isCompleted) voteGate.complete();
      });

      await _openDialog(tester, voteGate: voteGate);
      final node = await _focusAmountInput(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump();

      expect(find.byType(VotingDialog), findsOneWidget);
      _expectEditingReleased(tester, node);

      await tester.pumpAndSettle();
      expect(find.byType(VotingDialog), findsNothing);
    });

    testWidgets('the top-right close leaves the dialog and the keyboard', (
      tester,
    ) async {
      final voteGate = Completer<void>();
      addTearDown(() {
        if (!voteGate.isCompleted) voteGate.complete();
      });

      await _openDialog(tester, voteGate: voteGate);
      final node = await _focusAmountInput(tester);

      expect(_topClose(), findsOneWidget);
      final close = tester.getRect(_topClose());
      final popup = tester.getRect(find.byType(LargePopupWidget));
      expect(close.width, greaterThanOrEqualTo(48));
      expect(close.height, greaterThanOrEqualTo(48));
      expect(close.center.dx, greaterThan(popup.center.dx));
      expect(_topClose().hitTestable(), findsOneWidget);

      await tester.tap(_topClose());
      await tester.pump();
      await tester.pump();

      _expectEditingReleased(tester, node);

      await tester.pumpAndSettle();
      expect(find.byType(VotingDialog), findsNothing);
      expect(
        find.text('open-voting-dialog'),
        findsOneWidget,
        reason: 'exactly one route may leave',
      );
    });

    testWidgets(
      'the close cannot dismiss an in-flight vote, even through a stale callback',
      (tester) async {
        final voteGate = Completer<void>();
        addTearDown(() {
          if (!voteGate.isCompleted) voteGate.complete();
        });

        await _openDialog(tester, voteGate: voteGate);
        // Captured while idle, the way a rebuild-stale handler would be.
        final idleClose = _popup(tester).onClose!;
        expect(_popup(tester).closeButtonEnabled, isTrue);

        await tester.enterText(find.byType(TextFormField), '5');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(VotingSubmitButton));
        await pumpAndIgnoreErrors(tester);
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          find.descendant(
            of: find.byType(VotingSubmitButton),
            matching: find.byType(SmallPulseLoadingIndicator),
          ),
          findsOneWidget,
          reason: 'the vote must be in flight for this test to mean anything',
        );

        expect(
          _popup(tester).closeButtonEnabled,
          isFalse,
          reason: 'the X must lock while the request is running',
        );

        await tester.tap(_topClose(), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 16));
        idleClose();
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          find.byType(VotingDialog),
          findsOneWidget,
          reason:
              'closing mid-vote leaves the request running and lets a second '
              'request_id be charged separately',
        );
      },
    );

    testWidgets('leaving for the store releases the amount field first', (
      tester,
    ) async {
      final voteGate = Completer<void>();
      addTearDown(() {
        if (!voteGate.isCompleted) voteGate.complete();
      });

      await _openDialog(tester, voteGate: voteGate);
      final node = await _focusAmountInput(tester);

      await tester.tap(find.text(l10n.label_button_recharge));
      await tester.pump();
      await tester.pump();

      _expectEditingReleased(tester, node);

      await tester.pumpAndSettle();
      expect(find.byType(VotingDialog), findsNothing);
    });

    testWidgets('a mid-vote store navigation is refused', (tester) async {
      final voteGate = Completer<void>();
      addTearDown(() {
        if (!voteGate.isCompleted) voteGate.complete();
      });

      await _openDialog(tester, voteGate: voteGate);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(VotingDialog)),
      );
      final screenBefore = container.read(navigationInfoProvider).currentScreen;

      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(VotingSubmitButton));
      await pumpAndIgnoreErrors(tester);
      await tester.pump(const Duration(milliseconds: 16));

      // The recharge control is behind the loading overlay, so drive the
      // handler the way a stale captured callback would.
      final recharge = tester
          .widget<VotingStarCandyInfo>(find.byType(VotingStarCandyInfo))
          .onRecharge;
      recharge();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(VotingDialog), findsOneWidget);
      expect(
        container.read(navigationInfoProvider).currentScreen,
        same(screenBefore),
        reason: 'a refused close must not change the page underneath either',
      );
    });
  });
}
