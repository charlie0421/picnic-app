import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/widgets/shortform_playback_consent_tile.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('MyProfilePage widget test', () {
    testWidgets('optional measurement control uses the authenticated owner', (
      tester,
    ) async {
      await setupMockSupabaseWithAuth({}, userId: 'profile-owner');
      await tester.pumpWidget(buildTestAppPage(const MyProfilePage()));
      await pumpAndIgnoreErrors(tester);
      await tester.scrollUntilVisible(
        find.byType(ShortformPlaybackConsentTile),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final tile = tester.widget<ShortformPlaybackConsentTile>(
        find.byType(ShortformPlaybackConsentTile),
      );
      expect(tile.ownerUserId, 'profile-owner');
      expect(tile.key, const ValueKey('shortform-consent:profile-owner'));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('signed-out profile has no optional measurement control', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestAppPage(const MyProfilePage()));
      await pumpAndIgnoreErrors(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      expect(find.byType(ShortformPlaybackConsentTile), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const Scaffold(body: MyProfilePage())),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('contains ListView', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const Scaffold(body: MyProfilePage())),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('contains TextFormField for nickname input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(const Scaffold(body: MyProfilePage())),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders with custom user profile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
          userProfile: MockData.userProfile(
            nickname: 'CustomNick',
            avatarUrl: 'https://example.com/avatar.png',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders with logged out state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyProfilePage), findsOneWidget);
    });
  });
}
