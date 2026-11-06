// Regression tests for showWithdrawalBlockedDialog (Sentry PICNIC-APP-5KE).
//
// The profile lookup is held on a Completer, so each test decides exactly what
// happens while it is pending: the caller leaves, the user logs out, or the
// account changes. Auth is the fake Supabase client of mock_supabase.dart, the
// same `supabase.auth` that UserInfo.getUserProfiles queries with.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../helpers/mock_data.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';

const _userA = 'user-a';
const _userB = 'user-b';

UserProfilesModel _profile(String id, {bool withdrawn = false}) =>
    MockData.userProfile(
      id: id,
    ).copyWith(deletedAt: withdrawn ? DateTime.utc(2026, 10, 1) : null);

/// UserInfo whose profile lookup waits for the test. Like the real notifier,
/// a late successful response overwrites the cached state.
class _PendingUserInfo extends UserInfo {
  _PendingUserInfo(this.cached);

  final UserProfilesModel? cached;
  final List<Completer<UserProfilesModel?>> lookups = [];
  int logouts = 0;

  @override
  Future<UserProfilesModel?> build() async => cached;

  @override
  Future<UserProfilesModel?> getUserProfiles() async {
    final lookup = Completer<UserProfilesModel?>();
    lookups.add(lookup);
    final profile = await lookup.future;
    if (profile != null) state = AsyncData(profile);
    return profile;
  }

  @override
  Future<void> logout() async => logouts++;
}

class _GuardHost extends ConsumerStatefulWidget {
  const _GuardHost({required this.record, this.logoutUser = true});

  final _Record record;
  final bool logoutUser;

  @override
  ConsumerState<_GuardHost> createState() => _GuardHostState();
}

class _Record {
  final List<bool> results = [];
  int continued = 0;
}

class _GuardHostState extends ConsumerState<_GuardHost> {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async {
      final blocked = await showWithdrawalBlockedDialog(
        context: context,
        ref: ref,
        logoutUser: widget.logoutUser,
      );
      widget.record.results.add(blocked);
      if (!blocked) widget.record.continued++;
    },
    child: const Text('guarded action'),
  );
}

/// Records which providers a container creates and disposes, by name.
final class _LifetimeObserver extends ProviderObserver {
  final List<String?> added = [];
  final List<String?> disposed = [];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      added.add(context.provider.name);

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      disposed.add(context.provider.name);
}

class _Harness {
  _Harness(this.userInfo);

  final _PendingUserInfo userInfo;
  final record = _Record();
  final showHost = ValueNotifier<bool>(true);
  final observer = _LifetimeObserver();

  Widget build({bool logoutUser = true}) => ProviderScope(
    observers: [observer],
    overrides: [userInfoProvider.overrideWith(() => userInfo)],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showHost,
            builder: (_, show, _) => show
                ? _GuardHost(record: record, logoutUser: logoutUser)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  UserProfilesModel? cached,
  bool logoutUser = true,
}) async {
  final harness = _Harness(_PendingUserInfo(cached));
  addTearDown(harness.showHost.dispose);
  await tester.pumpWidget(harness.build(logoutUser: logoutUser));
  await tester.pump();
  return harness;
}

/// Starts the guarded action; the profile lookup stays pending.
Future<Completer<UserProfilesModel?>> _startGuard(
  WidgetTester tester,
  _Harness harness,
) async {
  await tester.tap(find.text('guarded action'));
  await tester.pump();
  expect(harness.userInfo.lookups, hasLength(1));
  return harness.userInfo.lookups.single;
}

Future<void> _leave(WidgetTester tester, _Harness harness) async {
  harness.showHost.value = false;
  await tester.pump();
  expect(find.text('guarded action'), findsNothing);
}

/// A same-account token refresh on the SAME fake client: refreshSession goes
/// to the mock token endpoint, which answers for the signed-in user, and gotrue
/// installs a new Session instance and emits tokenRefreshed.
Future<void> _deliverTokenRefresh(WidgetTester tester) async {
  final client = testSupabaseClient!;
  final before = client.auth.currentSession;
  final seen = <AuthChangeEvent>[];
  final events = client.auth.onAuthStateChange.listen(
    (state) => seen.add(state.event),
  );
  await tester.pump();
  seen.clear(); // Drop the replay of the current session.

  await tester.runAsync(() => client.auth.refreshSession());
  await tester.pump();
  unawaited(events.cancel());

  expect(identical(testSupabaseClient, client), isTrue);
  expect(client.auth.currentUser!.id, _userA);
  expect(identical(client.auth.currentSession, before), isFalse);
  expect(seen, contains(AuthChangeEvent.tokenRefreshed));
}

/// Moves the SAME fake Supabase client to [owner] (recoverSession with a
/// synthetic session) and waits until onAuthStateChange delivered it.
Future<void> _deliverAuth(WidgetTester tester, String owner) async {
  final client = testSupabaseClient!;
  final seen = <String?>[];
  final events = client.auth.onAuthStateChange.listen(
    (state) => seen.add(state.session?.user.id),
  );
  await tester.pump();
  seen.clear(); // Drop the replay of the current session.

  final prior = client.auth.currentSession!.toJson();
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry = DateTime.now().add(const Duration(hours: 1));
  final token =
      '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'sub': owner, 'exp': expiry.millisecondsSinceEpoch ~/ 1000})}'
      '.qa-synthetic';
  await client.auth.recoverSession(
    jsonEncode({
      ...prior,
      'access_token': token,
      'user': {...prior['user'] as Map<String, dynamic>, 'id': owner},
    }),
  );
  await tester.pump();
  // Not awaited: the subject's cancel future is not flushed by fake async.
  unawaited(events.cancel());

  expect(identical(testSupabaseClient, client), isTrue);
  expect(client.auth.currentUser!.id, owner);
  expect(seen, contains(owner), reason: 'the transition was delivered');
}

/// Moves the SAME fake client to [owner] with the public recoverSession and
/// does NOT wait: currentSession changes now, the auth event is still queued.
void _queueRecovery(String owner) {
  final client = testSupabaseClient!;
  final prior = client.auth.currentSession!.toJson();
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry = DateTime.now().add(const Duration(hours: 1));
  final token =
      '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'sub': owner, 'exp': expiry.millisecondsSinceEpoch ~/ 1000})}'
      '.qa-synthetic-queued';
  unawaited(
    client.auth.recoverSession(
      jsonEncode({
        ...prior,
        'access_token': token,
        'user': {...prior['user'] as Map<String, dynamic>, 'id': owner},
      }),
    ),
  );
  expect(client.auth.currentUser!.id, owner);
}

/// Records auth events on the same client from now on (replay dropped).
Future<List<String?>> _observeAuth(WidgetTester tester) async {
  final seen = <String?>[];
  final events = testSupabaseClient!.auth.onAuthStateChange.listen(
    (state) => seen.add(state.session?.user.id),
  );
  addTearDown(() => unawaited(events.cancel()));
  await tester.pump();
  seen.clear();
  return seen;
}

/// Opens the withdrawn dialog for A and returns its actual OK callback.
Future<(_Harness, VoidCallback)> _openWithdrawnDialog(
  WidgetTester tester,
) async {
  final harness = await _pumpHarness(tester);
  final lookup = await _startGuard(tester, harness);
  await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));
  expect(find.text(_withdrawalMessage), findsOneWidget);
  final ok = tester.widget<TextButton>(find.byType(TextButton).last).onPressed!;
  return (harness, ok);
}

Future<void> _switchTo(WidgetTester tester, String? userId) async {
  if (userId == null) {
    setupMockSupabase({});
  } else {
    await tester.runAsync(() => setupMockSupabaseWithAuth({}, userId: userId));
  }
}

String get _withdrawalMessage =>
    lookupAppLocalizations(const Locale('en')).error_message_withdrawal;

Future<void> _finish(
  WidgetTester tester,
  Completer<UserProfilesModel?> lookup, {
  UserProfilesModel? profile,
  Object? error,
}) async {
  if (error != null) {
    lookup.completeError(error);
  } else {
    lookup.complete(profile);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectStopped(WidgetTester tester, _Harness harness) {
  expect(tester.takeException(), isNull);
  expect(harness.record.results, [true]);
  expect(harness.record.continued, 0);
  expect(harness.userInfo.logouts, 0);
  expect(find.text(_withdrawalMessage), findsNothing);
}

void main() {
  setUp(() async {
    initTestColors();
    await setupMockSupabaseWithAuth({}, userId: _userA);
  });

  tearDown(tearDownMockSupabase);

  group('the caller left while the profile lookup was pending', () {
    testWidgets('a later non-withdrawn profile still stops the caller', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _leave(tester, harness);
      await _finish(tester, lookup, profile: _profile(_userA));

      _expectStopped(tester, harness);
    });

    testWidgets('a null response does not read the unmounted ref', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _leave(tester, harness);
      await _finish(tester, lookup);

      _expectStopped(tester, harness);
    });

    testWidgets('a failed lookup does not read the unmounted ref', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _leave(tester, harness);
      await _finish(tester, lookup, error: StateError('lookup failed'));

      _expectStopped(tester, harness);
    });
  });

  group('the account changed while the profile lookup was pending', () {
    testWidgets('logout: a withdrawn result shows no dialog and no logout', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _switchTo(tester, null);
      await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));

      _expectStopped(tester, harness);
    });

    testWidgets('switch: the old account result does not let B continue', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _switchTo(tester, _userB);
      await _finish(tester, lookup, profile: _profile(_userA));

      _expectStopped(tester, harness);
    });

    testWidgets('switch: the old account cache is not applied to B', (
      tester,
    ) async {
      final harness = await _pumpHarness(
        tester,
        cached: _profile(_userA, withdrawn: true),
      );
      final lookup = await _startGuard(tester, harness);

      await _switchTo(tester, _userB);
      await _finish(tester, lookup);

      _expectStopped(tester, harness);
    });
  });

  group('the caller is still mounted and the account did not change', () {
    testWidgets('a withdrawn user is blocked and OK logs out', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));

      expect(harness.record.results, [true]);
      expect(harness.record.continued, 0);
      expect(find.text(_withdrawalMessage), findsOneWidget);

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      expect(harness.userInfo.logouts, 1);
      expect(find.text(_withdrawalMessage), findsNothing);
    });

    testWidgets('a withdrawn user with logoutUser false is not logged out', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester, logoutUser: false);
      final lookup = await _startGuard(tester, harness);

      await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));
      expect(harness.record.results, [true]);

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      expect(harness.userInfo.logouts, 0);
    });

    testWidgets(
      'a cached withdrawn profile of this user blocks after failure',
      (tester) async {
        final harness = await _pumpHarness(
          tester,
          cached: _profile(_userA, withdrawn: true),
        );
        final lookup = await _startGuard(tester, harness);

        await _finish(tester, lookup, error: StateError('lookup failed'));

        expect(harness.record.results, [true]);
        expect(find.text(_withdrawalMessage), findsOneWidget);
      },
    );

    testWidgets('a non-withdrawn user continues', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _finish(tester, lookup, profile: _profile(_userA));

      expect(tester.takeException(), isNull);
      expect(harness.record.results, [false]);
      expect(harness.record.continued, 1);
      expect(find.text(_withdrawalMessage), findsNothing);
    });

    testWidgets('a failed lookup with no cache keeps the documented false', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _finish(tester, lookup, error: StateError('lookup failed'));

      expect(tester.takeException(), isNull);
      expect(harness.record.results, [false]);
      expect(harness.record.continued, 1);
    });

    testWidgets('a cache that a late response filled for another account is '
        'not this user cache', (tester) async {
      final harness = await _pumpHarness(
        tester,
        cached: _profile(_userB, withdrawn: true),
      );
      final lookup = await _startGuard(tester, harness);

      await _finish(tester, lookup);

      expect(tester.takeException(), isNull);
      expect(harness.record.results, [false]);
      expect(find.text(_withdrawalMessage), findsNothing);
    });
  });

  testWidgets('an account change while the dialog is open: OK does not log '
      'out the new account', (tester) async {
    final harness = await _pumpHarness(tester);
    final lookup = await _startGuard(tester, harness);
    await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));
    expect(find.text(_withdrawalMessage), findsOneWidget);

    await _switchTo(tester, _userB);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    expect(harness.userInfo.logouts, 0);
    expect(find.text(_withdrawalMessage), findsNothing);
  });

  group('A to B to A on the same client, delivered', () {
    testWidgets('while the lookup is pending, the caller still stops', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _deliverAuth(tester, _userB);
      await _deliverAuth(tester, _userA);
      await _finish(tester, lookup, profile: _profile(_userA));

      _expectStopped(tester, harness);
    });

    testWidgets('while the dialog is open, OK does not log out the later A '
        'session', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);
      await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));
      expect(find.text(_withdrawalMessage), findsOneWidget);

      await _deliverAuth(tester, _userB);
      await _deliverAuth(tester, _userA);
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.userInfo.logouts, 0);
      expect(find.text(_withdrawalMessage), findsNothing);
    });
  });

  group('a same-account token refresh is not an account change', () {
    testWidgets('while the lookup is pending, the caller continues', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      await _deliverTokenRefresh(tester);
      await _finish(tester, lookup, profile: _profile(_userA));

      expect(tester.takeException(), isNull);
      expect(harness.record.results, [false]);
      expect(harness.record.continued, 1);
    });

    testWidgets('while the dialog is open, OK still logs out', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);
      await _finish(tester, lookup, profile: _profile(_userA, withdrawn: true));

      await _deliverTokenRefresh(tester);
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(harness.userInfo.logouts, 1);
    });
  });

  group('auth events still queued when the result is used', () {
    testWidgets('dialog OK after a queued A to B to A does not log out the '
        'later A session', (tester) async {
      final (harness, ok) = await _openWithdrawnDialog(tester);
      final seen = await _observeAuth(tester);
      final client = testSupabaseClient!;
      final session = client.auth.currentSession;

      _queueRecovery(_userB);
      _queueRecovery(_userA);
      expect(identical(client, testSupabaseClient), isTrue);
      expect(identical(session, client.auth.currentSession), isFalse);
      expect(seen, isEmpty, reason: 'no event delivered yet');
      ok();
      await tester.pumpAndSettle();

      expect(seen, containsAllInOrder([_userB, _userA]));
      expect(tester.takeException(), isNull);
      expect(harness.userInfo.logouts, 0);
      expect(find.text(_withdrawalMessage), findsNothing);
    });

    testWidgets('dialog OK after a queued same-account session recovery still '
        'logs out', (tester) async {
      final (harness, ok) = await _openWithdrawnDialog(tester);
      final seen = await _observeAuth(tester);
      final session = testSupabaseClient!.auth.currentSession;

      _queueRecovery(_userA);
      expect(
        identical(session, testSupabaseClient!.auth.currentSession),
        isFalse,
      );
      expect(seen, isEmpty);
      ok();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.userInfo.logouts, 1);
      expect(find.text(_withdrawalMessage), findsNothing);
    });

    testWidgets('the ProviderScope disposed while OK waits for queued events: '
        'no logout and no disposed container read', (tester) async {
      final (harness, ok) = await _openWithdrawnDialog(tester);
      final disposedBefore = harness.observer.disposed.length;

      _queueRecovery(_userA);
      ok();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(harness.observer.disposed.length, greaterThan(disposedBefore));
      expect(tester.takeException(), isNull);
      expect(harness.userInfo.logouts, 0);
    });

    testWidgets('a lookup result used with a queued A to B to A stops the '
        'caller', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      lookup.complete(_profile(_userA));
      _queueRecovery(_userB);
      _queueRecovery(_userA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      _expectStopped(tester, harness);
    });

    testWidgets('a lookup result used with a queued same-account recovery '
        'continues', (tester) async {
      final harness = await _pumpHarness(tester);
      final lookup = await _startGuard(tester, harness);

      lookup.complete(_profile(_userA));
      _queueRecovery(_userA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(harness.record.results, [false]);
      expect(harness.record.continued, 1);
    });
  });

  testWidgets('one transition tracker per ProviderScope: dialogs dismissed by '
      'the barrier add none, and scope disposal releases it', (tester) async {
    final harness = await _pumpHarness(tester);
    const trackerName = 'withdrawnUserGuardAuthTransitions';

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('guarded action'));
      await tester.pump();
      await _finish(
        tester,
        harness.userInfo.lookups.last,
        profile: _profile(_userA, withdrawn: true),
      );
      expect(find.text(_withdrawalMessage), findsOneWidget);
      // Barrier dismissal: OK is never called.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text(_withdrawalMessage), findsNothing);
    }
    expect(harness.record.results, [true, true, true]);
    expect(harness.userInfo.logouts, 0);
    expect(harness.observer.added.where((n) => n == trackerName), hasLength(1));
    expect(harness.observer.disposed.where((n) => n == trackerName), isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      harness.observer.disposed.where((n) => n == trackerName),
      hasLength(1),
    );
  });
}
