import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';

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
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('contains ListView', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('contains TextFormField for nickname input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const Scaffold(body: MyProfilePage()),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders with custom user profile', (WidgetTester tester) async {
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
