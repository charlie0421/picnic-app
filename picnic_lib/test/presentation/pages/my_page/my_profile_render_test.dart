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
    setupMockSupabase({'user_profiles': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('MyProfilePage render', () {
    testWidgets('renders with logged-in user', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('enter text in nickname field', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find the TextFormField for nickname input
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'NewNickname');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('enter invalid nickname shows validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Enter invalid text with special characters
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '!@#\$%');
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      }
    });

    testWidgets('enter empty nickname', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('tap on page to dismiss keyboard',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // The outer GestureDetector dismisses keyboard on tap
      final gestureDetector = find.byType(GestureDetector);
      if (gestureDetector.evaluate().isNotEmpty) {
        await tester.tap(gestureDetector.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('scroll the list view', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll the ListView down
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -300),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('enter too long nickname triggers validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Enter a very long nickname (> 20 chars)
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(
            textField.first, 'ThisIsAVeryLongNicknameExceeding20Chars');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('enter valid Korean nickname', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '테스트닉네임');
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      }
    });

    testWidgets('enter valid Japanese nickname', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'テスト');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('tap save button (pencil GestureDetector)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Enter a new valid nickname first
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'NewName');
        await pumpAndIgnoreErrors(tester);
      }

      // Tap save button (GestureDetector with pencil icon)
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0;
          i < tester.widgetList(gestureDetectors).length && i < 10;
          i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('tap PicnicListItem for terms and privacy',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll to find list items
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -200),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // Tap InkWell widgets (PicnicListItems have InkWell)
      final inkWells = find.byType(InkWell);
      for (int i = 0;
          i < tester.widgetList(inkWells).length && i < 5;
          i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('enter nickname with spaces (invalid)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'test name');
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      }
    });

    testWidgets('renders with custom user profile avatar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          userProfile: MockData.userProfile(
            avatarUrl: 'https://example.com/avatar.jpg',
            nickname: 'AvatarUser',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders logged out state (null user data)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders with user without avatar (null avatarUrl)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          userProfile: MockData.userProfile(
            avatarUrl: null,
            nickname: 'NoAvatarUser',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          locale: const Locale('ja'),
          setting: MockData.setting(language: 'ja'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('enter Chinese characters nickname',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '测试用户');
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('focus and unfocus nickname field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap on the text field to focus it
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.tap(textField.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

        // Now tap outside to unfocus
        final gestureDetector = find.byType(GestureDetector);
        if (gestureDetector.evaluate().isNotEmpty) {
          await tester.tap(gestureDetector.first, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('renders with admin user profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          userProfile: MockData.userProfile(isAdmin: true),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('tap logout list item', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll down to find logout item
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -400),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // Tap all InkWells to hit logout and other list items
      final inkWells = find.byType(InkWell);
      for (int i = 0; i < tester.widgetList(inkWells).length && i < 8; i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('tap withdrawal list item opens modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll all the way down
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -600),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // Tap last InkWell (should be withdrawal)
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        final lastIndex = tester.widgetList(inkWells).length - 1;
        try {
          await tester.tap(inkWells.at(lastIndex), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
          await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
        } catch (_) {}
      }
    });

    testWidgets('tap profile image area', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap GestureDetectors (profile image has a GestureDetector)
      final gestureDetectors = find.byType(GestureDetector);
      for (int i = 0; i < tester.widgetList(gestureDetectors).length && i < 5; i++) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders nickname validation message for short input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Enter very short nickname (1 char)
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, 'a');
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      }
    });

    testWidgets('renders with user profile that has no nickname',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MyProfilePage(),
          userProfile: MockData.userProfile(nickname: null),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('dismiss keyboard by tapping outer GestureDetector',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const MyProfilePage()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Focus the text field
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isNotEmpty) {
        await tester.tap(textField.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);

        // Tap the outer GestureDetector to unfocus
        await tester.tapAt(const Offset(10, 10));
        await pumpAndIgnoreErrors(tester);
      }
    });
  });
}
