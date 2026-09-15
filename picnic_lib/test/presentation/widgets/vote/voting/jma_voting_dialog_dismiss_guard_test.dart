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
/// Harness note, measured rather than assumed. Under the widget-test clock a
/// `functions.invoke` that carries a **body** never reaches an injected
/// `MockClient` at all: the same call to the same endpoint reaches the handler
/// without `body:` and does not reach it with `body:`. REST is unaffected — the
/// withdrawal check's `user_profiles` GET does reach the mock, which is why the
/// gate group below can hold the submit path open and count its reads. The
/// shared `setupMockSupabase` client is constructed the same way and has the
/// same limit.
///
/// Two consequences, both deliberate:
///   * `jma-voting-v2` cannot be counted or completed from here, so the
///     JMA terminal success/failure pops are **not** covered in this file. The
///     equivalent contracts are covered on the general dialog, whose suites
///     inject a repository instead of HTTP.
///   * The spinner is not evidence that a request was entered — it turns on
///     with `_isVoting`, one line before the first await. Where this file needs
///     that evidence it counts profile reads instead.
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
