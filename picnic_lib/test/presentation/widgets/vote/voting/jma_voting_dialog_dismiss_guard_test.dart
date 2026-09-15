import 'dart:convert';

// A transitive package, imported only to subclass its isolate for this test.
// ignore: depend_on_referenced_packages
import 'package:yet_another_json_isolate/yet_another_json_isolate.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
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
/// Harness note, measured rather than assumed. A `functions.invoke` that
/// carries a non-String body used to never reach an injected `MockClient` at
/// all — the same call reached it without `body:` and not with it. The cause is
/// in `FunctionsClient.invoke`: a non-String body goes through
/// `await _isolate.encode(body)` *before* the http client is touched, and that
/// `Isolate.spawn` round trip does not advance under the widget-test clock, so
/// the submit parked there forever. `SupabaseClient` takes a `YAJsonIsolate`,
/// so [_SyncJsonIsolate] below encodes inline and the vote endpoint becomes
/// reachable, countable and completable from a widget test.
///
/// The spinner still is not evidence that a request was entered — it turns on
/// with `_isVoting`, one line before the first await. These tests assert on the
/// recorded endpoint calls instead.

/// A [YAJsonIsolate] that encodes on the calling isolate.
///
/// This is what unlocks the vote endpoint in a widget test. `FunctionsClient
/// .invoke` encodes a non-String body with `await _isolate.encode(body)` before
/// it ever touches the http client, and the real isolate's `Isolate.spawn`
/// round trip does not advance under the fake clock — so an invoke with a body
/// parked there forever and never reached the mock. Encoding inline removes
/// the round trip without changing what is sent.
class _SyncJsonIsolate extends YAJsonIsolate {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<String> encode(Object? json) async => jsonEncode(json);

  @override
  Future<dynamic> decode(String json) async => jsonDecode(json);
}

class _JmaBackend {
  /// How long the vote endpoint takes to answer.
  ///
  /// A `Future.delayed` rather than a `Completer` the test releases: a Completer
  /// completed from the test body does not resume its awaiting continuation
  /// inside `tester.pump`, so the response only landed after the test had
  /// finished pumping. A delay is driven by the fake clock, so the test decides
  /// exactly when the answer arrives by how far it pumps.
  Duration voteDelay = const Duration(seconds: 2);

  /// The scripted outcome the vote endpoint answers with.
  ///
  /// Defaults to a failure so that a test which only needs the *in-flight*
  /// window can drain its pending request at the end without also rendering the
  /// completion dialog.
  int voteStatus = 500;

  final List<Uri> functionCalls = <Uri>[];

  int callsTo(String function) => functionCalls
      .where((uri) => uri.path.endsWith('/functions/v1/$function'))
      .length;

  int get voteCalls => callsTo('jma-voting-v2');

  void install() {
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/functions/v1/')) {
        functionCalls.add(request.url);
      }

      if (path.endsWith('/functions/v1/jma-voting-usage')) {
        return _json(<String, dynamic>{'dailyVoteCount': 0});
      }
      if (path.endsWith('/functions/v1/jma-voting-v2')) {
        if (voteDelay > Duration.zero) await Future<void>.delayed(voteDelay);
        return _json(<String, dynamic>{
          'votePickId': 'pick-1',
          'updatedAt': '2026-09-15T00:00:00.000Z',
          'existingVoteTotal': 0,
          'addedVoteTotal': 5,
          'updatedVoteTotal': 5,
        }, status: voteStatus);
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
      isolate: _SyncJsonIsolate(),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  static http.Response _json(Map<String, dynamic> body, {int status = 200}) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: const {'content-type': 'application/json'},
      );
}

Future<void> _openJmaDialog(
  WidgetTester tester, {
  Size viewport = const Size(1125, 3600),
}) async {
  tester.view.physicalSize = viewport;
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

/// Runs the submit path until the vote request is actually out, without ever
/// settling — the loading overlay animates forever from here.
Future<void> _pumpUntilInFlight(
  WidgetTester tester,
  _JmaBackend backend,
) async {
  for (var i = 0; i < 8; i++) {
    await pumpAndIgnoreErrors(tester);
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(
    backend.voteCalls,
    1,
    reason: 'the request must actually be out for this test to mean anything',
  );
}

/// Pumps past the endpoint's delay so no request outlives the widget tree.
Future<void> _drainVoteRequest(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await pumpAndIgnoreErrors(tester);
    await tester.pump(const Duration(seconds: 1));
  }
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

    await _drainVoteRequest(tester);
  });

  testWidgets('system back cannot dismiss in the submit tap\'s own frame', (
    tester,
  ) async {
    // `PopScope` copies `canPop` into the route's notifier only from
    // `didUpdateWidget` (pop_scope.dart:205-208) and `ModalRoute
    // .popDisposition` reads that notifier (routes.dart:2037-2044), so a back
    // press that lands before the post-submit rebuild used to see the stale
    // `true` and pop the route while the request was already leaving. No pump
    // between the tap and the back press is what puts this inside that window.
    await _openJmaDialog(tester);
    await _startVote(tester, l10n.label_button_vote);
    await tester.binding.handlePopRoute();
    await pumpAndIgnoreErrors(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(JmaVotingDialog),
      findsOneWidget,
      reason: 'the route closed inside the guard\'s rebuild gap',
    );

    await _drainVoteRequest(tester);
  });

  testWidgets('a barrier tap cannot dismiss in the submit tap\'s own frame', (
    tester,
  ) async {
    await _openJmaDialog(tester);
    await _startVote(tester, l10n.label_button_vote);
    await tester.tapAt(const Offset(4, 4));
    await pumpAndIgnoreErrors(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(JmaVotingDialog), findsOneWidget);

    await _drainVoteRequest(tester);
  });

  testWidgets(
    'neither the close, a stale handler nor system back dismisses an in-flight vote',
    (tester) async {
      await _openJmaDialog(tester);
      final idleClose = _popup(tester).onClose!;

      await _startVote(tester, l10n.label_button_vote);
      await _pumpUntilInFlight(tester, backend);

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

      await _drainVoteRequest(tester);
    },
  );

  group('the withdrawal gate (the submit path\'s first await)', () {
    // The shared mock is the harness here, not the file's own client: the
    // withdrawal check reads `user_profiles` over REST, a GET with no body, so
    // unlike `functions.invoke` it does reach a mock — and `tableResponseDelays`
    // can hold it open. A profile read that has actually been entered is the
    // only proof this harness can offer that the submit path ran; the spinner
    // turns on one line earlier and so only proves the tap was accepted.
    Future<void> openWithProfile(
      WidgetTester tester, {
      required Map<String, dynamic> profileRow,
      required Duration readDelay,
    }) async {
      await setupMockSupabaseWithAuth(<String, dynamic>{
        'user_profiles': [profileRow],
      }, userId: 'test-user-id');
      tableResponseDelays['user_profiles'] = readDelay;
      await _openJmaDialog(tester);
    }

    Map<String, dynamic> profileRow({DateTime? deletedAt}) => <String, dynamic>{
      'id': 'test-user-id',
      'nickname': 'TestUser',
      'star_candy': 3000,
      'star_candy_bonus': 10,
      'deleted_at': deletedAt?.toIso8601String(),
    };

    int profileReads() => capturedMockRequests
        .where((uri) => uri.path.endsWith('/rest/v1/user_profiles'))
        .length;

    testWidgets('every close path is refused while the read is outstanding', (
      tester,
    ) async {
      await openWithProfile(
        tester,
        profileRow: profileRow(),
        readDelay: const Duration(seconds: 2),
      );
      final idleClose = _popup(tester).onClose!;
      final readsBefore = profileReads();

      await _startVote(tester, l10n.label_button_vote);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        profileReads(),
        readsBefore + 1,
        reason:
            'the submit path must actually be inside its first await for this '
            'test to mean anything',
      );
      expect(_popup(tester).closeButtonEnabled, isFalse);

      await tester.tap(_topClose(), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 16));
      idleClose();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(JmaVotingDialog), findsOneWidget);
      expect(
        profileReads(),
        readsBefore + 1,
        reason: 'no refused close may let a second submission start',
      );

      // Let the held read land, or its timer outlives the widget tree.
      tableResponseDelays.remove('user_profiles');
      for (var i = 0; i < 4; i++) {
        await pumpAndIgnoreErrors(tester);
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('a withdrawn user releases the lock and never votes', (
      tester,
    ) async {
      await openWithProfile(
        tester,
        profileRow: profileRow(deletedAt: DateTime.utc(2026, 9, 1)),
        readDelay: const Duration(milliseconds: 200),
      );

      await _startVote(tester, l10n.label_button_vote);
      for (var i = 0; i < 6; i++) {
        await pumpAndIgnoreErrors(tester);
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        _popup(tester).closeButtonEnabled,
        isTrue,
        reason: 'a blocked submission must hand the close back to the user',
      );
      expect(
        capturedMockRequests.where(
          (uri) => uri.path.endsWith('/functions/v1/jma-voting-v2'),
        ),
        isEmpty,
        reason: 'a withdrawn user must never reach the vote endpoint',
      );
    });
  });

  group('terminal outcomes (reachable now that the vote endpoint is)', () {
    /// Pumps past the endpoint's delay and on through the terminal path.
    Future<void> settleTerminal(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await pumpAndIgnoreErrors(tester);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    testWidgets('a settled success closes the dialog and reports once', (
      tester,
    ) async {
      backend.voteStatus = 200;
      // Wider than the default phone viewport on purpose: the completion
      // dialog overflows its own Row at 375 logical px (voting_complete.dart),
      // which is a pre-existing layout issue and not what this test is about.
      await _openJmaDialog(tester, viewport: const Size(1440, 3600));
      await _startVote(tester, l10n.label_button_vote);
      await _pumpUntilInFlight(tester, backend);

      await settleTerminal(tester);

      expect(
        find.byType(JmaVotingDialog),
        findsNothing,
        reason: 'the user-dismiss guard must not trap a settled vote',
      );
      expect(find.byType(VotingCompleteDialog), findsOneWidget);
      expect(
        backend.voteCalls,
        1,
        reason: 'one submission must produce exactly one request',
      );
    });

    testWidgets('a settled failure closes the dialog and reports once', (
      tester,
    ) async {
      backend.voteStatus = 500;
      await _openJmaDialog(tester);
      await _startVote(tester, l10n.label_button_vote);
      await _pumpUntilInFlight(tester, backend);

      await settleTerminal(tester);

      expect(find.byType(JmaVotingDialog), findsNothing);
      expect(find.byType(VotingCompleteDialog), findsNothing);
      expect(backend.voteCalls, 1);
    });

    testWidgets('a failure removes its own route, not the one covering it', (
      tester,
    ) async {
      // `Navigator.of(context).pop()` closes whatever is on top. Once something
      // else covers this dialog mid-request, that call takes the stranger's
      // route and leaves an unlocked voting dialog behind to submit from again.
      backend.voteStatus = 500;
      await _openJmaDialog(tester);
      await _startVote(tester, l10n.label_button_vote);
      await _pumpUntilInFlight(tester, backend);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covering-route')),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('covering-route'), findsOneWidget);

      await settleTerminal(tester);

      expect(
        find.byType(JmaVotingDialog),
        findsNothing,
        reason: 'the failing dialog must take its own route out of the stack',
      );
      expect(
        find.text('covering-route'),
        findsOneWidget,
        reason: 'the route that happened to be on top must survive',
      );
    });
  });

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
