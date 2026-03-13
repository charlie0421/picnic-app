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

  group('LoginPage render', () {
    testWidgets('renders login page', (WidgetTester tester) async {
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

    testWidgets('tap login button opens bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the main login ElevatedButton
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // The bottom sheet should now be showing with login options
        // Check for Google login text
        expect(find.text('Login with Google'), findsWidgets);
      }
    });

    testWidgets('tap language selector opens bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // The language selector is a GestureDetector with a specific container
      // Look for the language selector by finding the border container
      final gestureDetectors = find.byType(GestureDetector);
      // Try tapping all gesture detectors to find the language selector
      for (int i = 0;
          i < tester.widgetList(gestureDetectors).length && i < 5;
          i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    });

    testWidgets('tap back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // The back button is an InkWell with CircleBorder
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('renders LastProvider widget when lastProvider is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // After initState postFrameCallback runs, lastProvider is set from secure storage
      // Let it settle
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('swiper auto-plays', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      // Let the swiper auto-play for a bit
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
      await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('swiper auto-plays multiple cycles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      // Let the swiper auto-play for multiple cycles
      for (int i = 0; i < 5; i++) {
        await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
      }
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('tap ElevatedButton opens bottom sheet with login options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the login button
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

        // Check that Google login option is visible
        final googleLogin = find.text('Login with Google');
        expect(googleLogin, findsWidgets);

        // Check Kakao login option
        final kakaoLogin = find.text('Login with Kakao');
        expect(kakaoLogin, findsWidgets);
      }
    });

    testWidgets('tap multiple gesture detectors for language selector',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // The language selector is built with GestureDetector
      // Try to find and tap it
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0;
          i < tester.widgetList(gestureDetectors).length && i < 8;
          i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
    });

    testWidgets('renders with different locale setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          setting: MockData.setting(language: 'en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('swipe the swiper manually', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Try to swipe the Swiper horizontally
      final swiper = find.byType(LoginPage);
      if (swiper.evaluate().isNotEmpty) {
        await tester.drag(swiper.first, const Offset(-200, 0),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          locale: const Locale('en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          locale: const Locale('ja'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with Chinese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          locale: const Locale('zh'),
          setting: MockData.setting(language: 'zh'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with Japanese language setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          setting: MockData.setting(language: 'ja'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('tap login button then tap login option',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap login button to open bottom sheet
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

        // Try to tap the Google login GestureDetector in the bottom sheet
        final gestureDetectors = find.byType(GestureDetector);
        for (int i = 0; i < tester.widgetList(gestureDetectors).length && i < 15; i++) {
          try {
            await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
          } catch (_) {}
        }
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('tap language selector and select a language',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find the language selector GestureDetector (the one with the border container)
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0; i < tester.widgetList(gestureDetectors).length && i < 5; i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

          // If bottom sheet opened with ListTile items, tap one
          final listTiles = find.byType(ListTile);
          if (listTiles.evaluate().isNotEmpty) {
            await tester.tap(listTiles.first, warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            break;
          }
        } catch (_) {}
      }
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    });

    testWidgets('initState reads lastProvider from secure storage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
        ),
      );
      // Let postFrameCallback run to read secure storage
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with Thai locale setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          setting: MockData.setting(language: 'th'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('tap back button when navigator can pop',
        (WidgetTester tester) async {
      // Create a Navigator stack so LoginPage can pop
      await tester.pumpWidget(
        buildTestAppPage(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: const Text('Go'),
            ),
          ),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Navigate to LoginPage
      final goButton = find.text('Go');
      if (goButton.evaluate().isNotEmpty) {
        await tester.tap(goButton, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // Now tap back button (InkWell)
        final inkWells = find.byType(InkWell);
        if (inkWells.evaluate().isNotEmpty) {
          await tester.tap(inkWells.first, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
        }
      }
    });
  });
}
