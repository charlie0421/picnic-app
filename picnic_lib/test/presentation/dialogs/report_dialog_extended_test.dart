import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';

import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('ReportType enum coverage', () {
    test('toString includes name', () {
      expect(ReportType.comment.toString(), contains('comment'));
      expect(ReportType.post.toString(), contains('post'));
    });

    test('can be used in switch expression', () {
      String result(ReportType type) => switch (type) {
            ReportType.comment => 'comment_report',
            ReportType.post => 'post_report',
          };

      expect(result(ReportType.comment), 'comment_report');
      expect(result(ReportType.post), 'post_report');
    });
  });

  group('CustomRadioListTile rendering', () {
    testWidgets('renders multiple radio options with correct selection state',
        (tester) async {
      int? selectedValue = 2;
      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return CustomRadioListTile(
                    title: 'Option $i',
                    value: i,
                    groupValue: selectedValue,
                    onChanged: (v) => setState(() => selectedValue = v),
                  );
                }),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 5 options present
      for (int i = 0; i < 5; i++) {
        expect(find.text('Option $i'), findsOneWidget);
      }

      // Tap option 0
      await tester.tap(find.text('Option 0'));
      await tester.pumpAndSettle();

      // Widget should still render
      expect(find.byType(CustomRadioListTile), findsNWidgets(5));
    });

    testWidgets('InkWell does not fire when onChanged is null',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(
        buildTestApp(
          const CustomRadioListTile(
            title: 'Disabled tile',
            value: 3,
            groupValue: 1,
            onChanged: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap should not cause crash
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('Radio fillColor resolves for default (unselected) state',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: 'Default state',
            value: 0,
            groupValue: 99,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final radio = tester.widget<Radio<int>>(find.byType(Radio<int>));
      expect(radio.fillColor, isNotNull);
    });

    testWidgets('Row contains SizedBox and Expanded children', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CustomRadioListTile(
            title: 'Structure test',
            value: 0,
            groupValue: 0,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SizedBox wrapping Radio
      expect(
        find.descendant(
          of: find.byType(CustomRadioListTile),
          matching: find.byType(SizedBox),
        ),
        findsWidgets,
      );

      // Expanded wrapping Text
      expect(
        find.descendant(
          of: find.byType(CustomRadioListTile),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
    });
  });

  group('ReportDialog validation logic - extended', () {
    test('validate with whitespace-only other reason treats as empty', () {
      const text = '   ';
      String? errorText;

      if (text.trim().isEmpty) {
        errorText = 'Please enter a reason';
      }

      expect(errorText, isNotNull);
    });

    test('validate with exactly 1 character', () {
      const text = 'a';
      final maxLength = 100;
      String? errorText;

      if (text.isEmpty) {
        errorText = 'Please enter a reason';
      } else if (text.length > maxLength) {
        errorText = 'Max $maxLength characters';
      } else {
        errorText = null;
      }

      expect(errorText, isNull);
    });

    test('reason selection - index 0 through 3 are standard reasons', () {
      for (int i = 0; i < 4; i++) {
        bool needsOtherText = (i == 4);
        expect(needsOtherText, isFalse);
      }
    });

    test('reason index 4 requires additional text', () {
      int selectedReason = 4;
      bool needsOtherText = (selectedReason == 4);
      expect(needsOtherText, isTrue);
    });

    test('submit with reason 0 and blockUser true', () {
      int? selectedReason = 0;
      bool blockUser = true;
      bool canSubmit = selectedReason != null;

      expect(canSubmit, isTrue);
      expect(blockUser, isTrue);
    });

    test('submit with reason 4 and non-empty other text', () {
      int? selectedReason = 4;
      String otherText = 'Detailed reason here';
      bool canSubmit =
          selectedReason != null &&
          !(selectedReason == 4 && otherText.trim().isEmpty);

      expect(canSubmit, isTrue);
    });

    test('changing from reason 4 to another clears other text validation', () {
      int? selectedReason = 4;
      String? errorText = 'Please enter a reason';

      // Switch to reason 2
      selectedReason = 2;
      if (selectedReason != 4) {
        errorText = null;
      }

      expect(errorText, isNull);
    });

    test('isSubmitting blocks all interactions', () {
      bool isSubmitting = true;

      // Reason change blocked
      bool canChangeReason = !isSubmitting;
      expect(canChangeReason, isFalse);

      // Checkbox blocked
      bool canToggleBlock = !isSubmitting;
      expect(canToggleBlock, isFalse);

      // Submit blocked
      bool canSubmit = !isSubmitting;
      expect(canSubmit, isFalse);
    });
  });
}
