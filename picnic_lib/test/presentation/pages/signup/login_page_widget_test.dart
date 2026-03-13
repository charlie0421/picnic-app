import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';

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

  group('LoginPage widget test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('contains ElevatedButton for login', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('contains back button InkWell', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('login button opens bottom sheet with login options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

        expect(find.text('Login with Google'), findsWidgets);
        expect(find.text('Login with Kakao'), findsWidgets);
      }
    });

    testWidgets('language selector GestureDetector exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
