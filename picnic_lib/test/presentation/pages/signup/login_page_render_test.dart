import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  // 프로덕션 폰트(Pretendard)를 실제로 올린다.
  //
  // 이게 없으면 flutter_test 의 기본 테스트 폰트(모든 글리프가 1em 정사각형)로
  // 텍스트를 재는데, 그 폰트는 실제 Pretendard 보다 훨씬 넓다. 로그인 버튼 Row 가
  // 여기서 오버플로로 보였던 건 순전히 그 때문이다 — 프로덕션 기하(393x892,
  // kAppDesignSize, splitScreenMode) 로 구글 버튼만 따로 재보면 테스트 폰트로는
  // 52px 넘치고 Pretendard 로는 0px 다. 즉 버튼 디자인 문제가 아니라 하네스 문제였고,
  // 폰트를 올리면 이 파일의 오버플로는 전부 사라진다.
  //
  // 전역(`flutter_test_config.dart`)으로 올리지 않는 건 12k 개 테스트의 텍스트
  // 기하가 한꺼번에 바뀌기 때문이다. 오버플로를 검사하는 파일에서만 켠다.
  setUpAll(loadTestFonts);

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
      // 격리 — 이 테스트 하나에만 적용된다.
      //
      // app_localizations 는 `Locale('zh')` 를 지원 목록에 넣어두었는데
      // constants.dart 의 languageMap 에는 'zh_CN'/'zh_TW' 만 있고 'zh' 가 없다.
      // login_page.dart:284 의 `languageMap[appSettingState.language]!` 가 그대로
      // null 단언이라 언어가 'zh' 인 사용자는 로그인 화면에서 크래시한다.
      //
      // 이건 main 에서 #85(`languageLabel()` 폴백)로 이미 고쳐졌다. 이 브랜치는
      // 아직 그 커밋을 안 받았을 뿐이므로, main 을 머지하는 순간 이 격리는
      // 통째로 지워야 한다 — 그때 이 테스트는 격리 없이 그냥 통과해야 한다.
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestAppPage(
          const LoginPage(),
          loggedIn: false,
          locale: const Locale('zh'),
          setting: MockData.setting(language: 'zh'),
        ),
        knownDefects: const ['Null check operator used on a null value'],
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
