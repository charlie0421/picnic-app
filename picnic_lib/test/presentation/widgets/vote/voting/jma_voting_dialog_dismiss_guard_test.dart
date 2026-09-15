import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// PICNIC-2695, JMA half.
///
/// The JMA dialog carries the same double-charge hazard as the general one:
/// `jma-voting-v2` keeps running after the route leaves, so a user who closes
/// the spinner and votes again is charged twice. Unlike the general dialog it
/// had no `PopScope` at all, and neither dialog had a way *out* before the
/// request started — this adds the top-right X to both, which is only safe
/// while it refuses mid-request.
///
/// Harness note: `functions.invoke` with a request body never reaches an
/// injected `MockClient` under the widget-test clock (the shared
/// `setupMockSupabase` mock has the same limit), so the submit parks inside the
/// HTTP call. That is exactly the in-flight state these tests need, but it also
/// means the request cannot be counted or completed from here — the assertions
/// below are about the dismissal contract, and the terminal success/failure
/// pops stay covered by the general dialog's suites, which inject a repository
/// instead of HTTP.
class _JmaBackend {
  final List<Uri> functionCalls = <Uri>[];

  void install() {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/functions/v1/')) {
        functionCalls.add(request.url);
      }

      if (path.endsWith('/functions/v1/jma-voting-usage')) {
        return _json(<String, dynamic>{'dailyVoteCount': 0});
      }
      if (path.contains('/rest/v1/')) {
        final accept =
            request.headers['Accept'] ?? request.headers['accept'] ?? '';
        return http.Response(
          accept.contains('vnd.pgrst.object') ? 'null' : '[]',
          200,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      }
      return _json(const <String, dynamic>{});
    });

    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  static http.Response _json(Map<String, dynamic> body) => http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json'},
  );
}

Future<void> _openJmaDialog(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1125, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(suppressImageErrors());

  await pumpWidgetAndIgnoreErrors(
    tester,
    buildTestApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (_) => JmaVotingDialog(
              voteModel: MockData.vote(),
              voteItemModel: MockData.voteItem(),
              portalType: VotePortal.vote,
            ),
          ),
          child: const Text('open-jma-dialog'),
        ),
      ),
      userProfile: MockData.userProfile(starCandy: 3000, starCandyBonus: 10),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('open-jma-dialog'));
  await tester.pump(const Duration(seconds: 1));
  drainExpectedImageErrors(tester);
  expect(find.byType(JmaVotingDialog), findsOneWidget);
}

/// Types an amount with the keyboard up and hands back the input's own node.
///
/// The node is the observable, not `FocusManager.primaryFocus`: a scope can own
/// the primary focus while no editable does.
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

/// Enters a valid amount and taps the JMA vote action, without pumping: the
/// caller decides how far the submit path is allowed to run.
Future<void> _startVote(WidgetTester tester, String voteLabel) async {
  await tester.enterText(find.byType(TextFormField), '5');
  await tester.pump();
  await tester.tap(
    find
        .ancestor(
          of: find.text(voteLabel),
          matching: find.byType(GestureDetector),
        )
        .first,
  );
}

/// Runs the submit path up to the point where it parks in the request, without
/// ever settling — the loading overlay animates forever from here.
Future<void> _pumpUntilInFlight(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await pumpAndIgnoreErrors(tester);
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(
    find.byType(SmallPulseLoadingIndicator),
    findsWidgets,
    reason: 'the request must be in flight for this test to mean anything',
  );
}

void main() {
  final l10n = AppLocalizationsKo();
  late _JmaBackend backend;

  setUpAll(initTestColors);

  setUp(() {
    backend = _JmaBackend();
    backend.install();
  });

  tearDown(tearDownMockSupabase);

  testWidgets('a barrier tap releases the amount field and the input client', (
    tester,
  ) async {
    await _openJmaDialog(tester);
    final node = await _focusAmountInput(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.pump();

    _expectEditingReleased(tester, node);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JmaVotingDialog), findsNothing);
    expect(find.text('open-jma-dialog'), findsOneWidget);
  });

  testWidgets('system back releases the amount field and the input client', (
    tester,
  ) async {
    await _openJmaDialog(tester);
    final node = await _focusAmountInput(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();

    _expectEditingReleased(tester, node);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JmaVotingDialog), findsNothing);
  });

  testWidgets('the top-right close leaves the dialog and the keyboard', (
    tester,
  ) async {
    await _openJmaDialog(tester);
    final node = await _focusAmountInput(tester);

    expect(_topClose(), findsOneWidget);
    final close = tester.getRect(_topClose());
    final popup = tester.getRect(find.byType(LargePopupWidget));
    expect(close.width, greaterThanOrEqualTo(47.99));
    expect(close.height, greaterThanOrEqualTo(47.99));
    expect(
      close.center.dx,
      greaterThan(popup.center.dx),
      reason: 'the X belongs on the trailing side',
    );
    expect(_topClose().hitTestable(), findsOneWidget);

    await tester.tap(_topClose());
    await tester.pump();
    await tester.pump();

    _expectEditingReleased(tester, node);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(JmaVotingDialog), findsNothing);
    expect(
      find.text('open-jma-dialog'),
      findsOneWidget,
      reason: 'exactly one route may leave',
    );
  });

  testWidgets('the close locks before the submit path takes its first await', (
    tester,
  ) async {
    // The withdrawal check is the first await and it is a network round trip.
    // The lock has to be up before it, or the X stays live across it and can
    // pop the route out from under the `setState` that follows. Calling the
    // captured handler with no pump in between is what makes this precise: it
    // runs in the same turn as the tap.
    await _openJmaDialog(tester);
    final idleClose = _popup(tester).onClose!;
    expect(_popup(tester).closeButtonEnabled, isTrue);

    await _startVote(tester, l10n.label_button_vote);
    idleClose();
    await tester.pump();

    expect(
      find.byType(JmaVotingDialog),
      findsOneWidget,
      reason: 'the guard must already be up in the tap\'s own turn',
    );
    expect(_popup(tester).closeButtonEnabled, isFalse);
  });

  testWidgets(
    'neither the close, a stale handler nor system back dismisses an in-flight vote',
    (tester) async {
      await _openJmaDialog(tester);
      final idleClose = _popup(tester).onClose!;

      await _startVote(tester, l10n.label_button_vote);
      await _pumpUntilInFlight(tester);

      expect(
        _popup(tester).closeButtonEnabled,
        isFalse,
        reason: 'the X must lock while the request is running',
      );

      await tester.tap(_topClose(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 16));
      idleClose();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byType(JmaVotingDialog),
        findsOneWidget,
        reason:
            'closing mid-vote leaves the request running and lets a second '
            'charge settle on reopen',
      );
    },
  );

  testWidgets('the daily usage read never reaches the vote endpoint', (
    tester,
  ) async {
    // Guards the fixture itself: if the dialog ever started voting on open,
    // every assertion above about the in-flight window would be meaningless.
    await _openJmaDialog(tester);
    expect(
      backend.functionCalls.where(
        (uri) => uri.path.endsWith('/functions/v1/jma-voting-v2'),
      ),
      isEmpty,
    );
  });
}
