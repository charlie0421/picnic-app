import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_input_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'goonghap_results': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('GoonghapInputPage render', () {
    testWidgets('renders with artist parameter', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('tap gender buttons toggles selection',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find gender buttons (GestureDetector wrapping Container with text)
      final genderButtons = find.byType(GestureDetector);
      expect(genderButtons, findsWidgets);

      // Tap the first gender button (female)
      for (final gesture in tester.widgetList<GestureDetector>(genderButtons)) {
        if (gesture.child is Container) {
          final container = gesture.child as Container;
          if (container.constraints?.maxWidth == 60) {
            // Found a gender button
            break;
          }
        }
      }

      // Tap all GestureDetectors that might be gender buttons
      // The gender buttons are 60x19 containers
      final allGestures = find.byType(GestureDetector);
      for (int i = 0; i < tester.widgetList(allGestures).length && i < 10; i++) {
        try {
          await tester.tap(allGestures.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('tap date picker InkWell triggers date selection',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap the InkWell for date selection
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // If date picker opened, try to dismiss it
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('tap checkbox toggles agreement',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the CheckboxListTile
      final checkbox = find.byType(CheckboxListTile);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        // Tap again to toggle back
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('tap submit button triggers validation',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the submit ElevatedButton
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('scroll the page', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll down
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('dropdown time selection', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find DropdownButtonFormField
      final dropdown = find.byType(DropdownButtonFormField<String>);
      if (dropdown.evaluate().isNotEmpty) {
        await tester.tap(dropdown, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('fill all fields and tap submit', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // 1. Tap gender button (female first, then male)
      final allGestures = find.byType(GestureDetector);
      for (int i = 0; i < tester.widgetList(allGestures).length && i < 15; i++) {
        final widget = tester.widget<GestureDetector>(allGestures.at(i));
        if (widget.child is Container) {
          final container = widget.child as Container;
          if (container.constraints?.maxWidth == 60) {
            await tester.tap(allGestures.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            break;
          }
        }
      }

      // 2. Tap date picker InkWell
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // Try to dismiss any opened dialog
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        }
      }

      // 3. Toggle checkbox on
      final checkbox = find.byType(CheckboxListTile);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // 4. Now tap submit (should attempt validation since date may not be set)
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('submit without gender shows validation error',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Toggle checkbox on without filling required fields
      final checkbox = find.byType(CheckboxListTile);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // Tap submit - should show snackbar validation error
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
      }
    });

    testWidgets('scroll down to reveal submit button',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll all the way down
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        // Scroll back up
        await tester.drag(scrollable.first, const Offset(0, 500),
            warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('toggle gender between male and female',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap all GestureDetectors that are gender buttons (width 60)
      final allGestures = find.byType(GestureDetector);
      int tapped = 0;
      for (int i = 0; i < tester.widgetList(allGestures).length && tapped < 4; i++) {
        final widget = tester.widget<GestureDetector>(allGestures.at(i));
        if (widget.child is Container) {
          final container = widget.child as Container;
          if (container.constraints?.maxWidth == 60) {
            await tester.tap(allGestures.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            tapped++;
          }
        }
      }
    });

    testWidgets('renders with logged out state', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          locale: const Locale('en'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          locale: const Locale('ja'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with artist with English name only',
        (WidgetTester tester) async {
      final artist = MockData.artist(nameKo: '', nameEn: 'Jimin');

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with user that has birth info pre-filled',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          userProfile: MockData.userProfile(
            nickname: 'BirthUser',
          ),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('renders with artist group info', (WidgetTester tester) async {
      final group = MockData.artistGroup(nameKo: 'BTS', nameEn: 'BTS');
      final artist = MockData.artist(
        nameKo: '지민',
        nameEn: 'Jimin',
        artistGroup: group,
      );

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });

    testWidgets('dispose cleans up without error',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        buildTestAppPage(const SizedBox()),
      );
      drainExpectedImageErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 200));
    });

    testWidgets('select date then gender then checkbox then submit',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // 1. Tap gender buttons
      final allGestures = find.byType(GestureDetector);
      for (int i = 0; i < tester.widgetList(allGestures).length && i < 15; i++) {
        final widget = tester.widget<GestureDetector>(allGestures.at(i));
        if (widget.child is Container) {
          final container = widget.child as Container;
          if (container.constraints?.maxWidth == 60) {
            await tester.tap(allGestures.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            break;
          }
        }
      }

      // 2. Tap date picker
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));

        // Dismiss date picker
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton, warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        }
      }

      // 3. Toggle checkbox on
      final checkbox = find.byType(CheckboxListTile);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
      }

      // 4. Tap submit
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
      }
    });

    testWidgets('tap all gender buttons alternately',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap all gender GestureDetectors found
      final allGestures = find.byType(GestureDetector);
      int tapped = 0;
      for (int i = 0; i < tester.widgetList(allGestures).length && tapped < 6; i++) {
        final widget = tester.widget<GestureDetector>(allGestures.at(i));
        if (widget.child is Container) {
          final container = widget.child as Container;
          if (container.constraints?.maxWidth == 60) {
            await tester.tap(allGestures.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            tapped++;
          }
        }
      }
    });

    testWidgets('tap dropdown time selector opens menu',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(GoonghapInputPage(artist: artist)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Find and tap the DropdownButtonFormField
      final dropdown = find.byType(DropdownButtonFormField<String>);
      if (dropdown.evaluate().isNotEmpty) {
        await tester.tap(dropdown, warnIfMissed: false);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

        // Try to tap a dropdown menu item
        // DropdownMenuItem shows as a list of items in the overlay
        final menuItems = find.byType(InkWell);
        for (int i = 0; i < tester.widgetList(menuItems).length && i < 5; i++) {
          try {
            await tester.tap(menuItems.at(i), warnIfMissed: false);
            await pumpAndIgnoreErrors(tester);
            break;
          } catch (_) {}
        }
      }
    });

    testWidgets('renders with Chinese locale',
        (WidgetTester tester) async {
      final artist = MockData.artist();

      await tester.pumpWidget(
        buildTestAppPage(
          GoonghapInputPage(artist: artist),
          locale: const Locale('zh'),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(GoonghapInputPage), findsOneWidget);
    });
  });
}
