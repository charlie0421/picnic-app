// The actual TopRightPost pencil callback awaits showWithdrawalBlockedDialog and
// then navigates without checking `mounted` again. These tests hold the profile
// lookup on a Completer, change the caller or the account while it is pending,
// and require that PostWritePage is not opened.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/top/top_right_post.dart';
import 'package:picnic_lib/presentation/pages/community/post_write_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_environment.dart';

const _userA = 'user-a';

class _PendingUserInfo extends UserInfo {
  final List<Completer<UserProfilesModel?>> lookups = [];

  @override
  Future<UserProfilesModel?> build() async => null;

  @override
  Future<UserProfilesModel?> getUserProfiles() async {
    final lookup = Completer<UserProfilesModel?>();
    lookups.add(lookup);
    final profile = await lookup.future;
    if (profile != null) state = AsyncData(profile);
    return profile;
  }
}

/// The real NavigationInfo, recording the community pages it is asked to open.
class _RecordingNavigation extends NavigationInfo {
  final List<Type> communityPages = [];

  @override
  Navigation build() => MockData.navigation();

  @override
  void setCommunityCurrentPage(
    Widget page, {
    bool showTopMenu = false,
    bool showBottomNavigation = true,
  }) {
    communityPages.add(page.runtimeType);
  }
}

class _Harness {
  final userInfo = _PendingUserInfo();
  final navigation = _RecordingNavigation();
  final showCaller = ValueNotifier<bool>(true);

  Widget build() => ProviderScope(
    overrides: [
      userInfoProvider.overrideWith(() => userInfo),
      navigationInfoProvider.overrideWith(() => navigation),
    ],
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
            valueListenable: showCaller,
            builder: (_, show, _) =>
                show ? const TopRightPost() : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

Future<(_Harness, Completer<UserProfilesModel?>)> _tapPencil(
  WidgetTester tester,
) async {
  final harness = _Harness();
  addTearDown(harness.showCaller.dispose);
  await tester.pumpWidget(harness.build());
  await tester.pump();

  // The first GestureDetector of TopRightPost is the pencil. Its transparent
  // tap area has no painted SVG in the test bundle, so the production onTap
  // closure itself is invoked instead of a positional tap.
  final pencil = tester.widget<GestureDetector>(
    find
        .descendant(
          of: find.byType(TopRightPost),
          matching: find.byType(GestureDetector),
        )
        .first,
  );
  pencil.onTap!();
  await tester.pump();
  expect(harness.userInfo.lookups, hasLength(1));
  return (harness, harness.userInfo.lookups.single);
}

Future<void> _finish(
  WidgetTester tester,
  Completer<UserProfilesModel?> lookup,
) async {
  lookup.complete(MockData.userProfile(id: _userA));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Moves the SAME fake Supabase client to [owner] (recoverSession with a
/// synthetic session) and requires onAuthStateChange to deliver it.
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

/// A same-account token refresh on the SAME fake client (mock token endpoint).
Future<void> _deliverTokenRefresh(WidgetTester tester) async {
  final client = testSupabaseClient!;
  final before = client.auth.currentSession;
  final seen = <AuthChangeEvent>[];
  final events = client.auth.onAuthStateChange.listen(
    (state) => seen.add(state.event),
  );
  await tester.pump();
  seen.clear();

  await tester.runAsync(() => client.auth.refreshSession());
  await tester.pump();
  unawaited(events.cancel());

  expect(client.auth.currentUser!.id, _userA);
  expect(identical(client.auth.currentSession, before), isFalse);
  expect(seen, contains(AuthChangeEvent.tokenRefreshed));
}

void main() {
  setUp(() async {
    initTestColors();
    await setupMockSupabaseWithAuth({}, userId: _userA);
  });

  tearDown(tearDownMockSupabase);

  testWidgets('opens PostWritePage when the caller stays and the account is '
      'the same', (tester) async {
    final (harness, lookup) = await _tapPencil(tester);

    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, [PostWritePage]);
  });

  testWidgets('does not open PostWritePage after the caller is unmounted', (
    tester,
  ) async {
    final (harness, lookup) = await _tapPencil(tester);

    harness.showCaller.value = false;
    await tester.pump();
    expect(find.byType(TopRightPost), findsNothing);
    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, isEmpty);
  });

  testWidgets('does not open PostWritePage after logout', (tester) async {
    final (harness, lookup) = await _tapPencil(tester);

    setupMockSupabase({});
    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, isEmpty);
  });

  testWidgets('does not open PostWritePage after an account change', (
    tester,
  ) async {
    final (harness, lookup) = await _tapPencil(tester);

    await tester.runAsync(
      () => setupMockSupabaseWithAuth({}, userId: 'user-b'),
    );
    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, isEmpty);
  });

  testWidgets('does not open PostWritePage after A to B to A on the same '
      'client', (tester) async {
    final (harness, lookup) = await _tapPencil(tester);

    await _deliverAuth(tester, 'user-b');
    await _deliverAuth(tester, _userA);
    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, isEmpty);
  });

  testWidgets('opens PostWritePage after a same-account token refresh', (
    tester,
  ) async {
    final (harness, lookup) = await _tapPencil(tester);

    await _deliverTokenRefresh(tester);
    await _finish(tester, lookup);

    expect(tester.takeException(), isNull);
    expect(harness.navigation.communityPages, [PostWritePage]);
  });
}
