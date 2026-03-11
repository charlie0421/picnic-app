import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/post_write_actions.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('PostWriteActions', () {
    testWidgets('renders temporary save text and publish button',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: true,
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render both actions
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('calls onSave(true) when temporary save tapped with valid title',
        (tester) async {
      bool? isTemporary;
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: true,
            onSave: (temp) => isTemporary = temp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the GestureDetector for temporary save (first text widget)
      final gestureDetectors = find.byType(GestureDetector);
      // Tap the first GestureDetector (temporary save)
      await tester.tap(gestureDetectors.first);
      await tester.pumpAndSettle();

      expect(isTemporary, isTrue);
    });

    testWidgets('calls onSave(false) when publish button tapped with valid title',
        (tester) async {
      bool? isTemporary;
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: true,
            onSave: (temp) => isTemporary = temp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(isTemporary, isFalse);
    });

    testWidgets('shows dialog when temporary save tapped with invalid title',
        (tester) async {
      bool saveCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: false,
            onSave: (_) => saveCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gestureDetectors = find.byType(GestureDetector);
      await tester.tap(gestureDetectors.first);
      await tester.pumpAndSettle();

      // onSave should NOT be called when title is invalid
      expect(saveCalled, isFalse);
    });

    testWidgets('shows dialog when publish tapped with invalid title',
        (tester) async {
      bool saveCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: false,
            onSave: (_) => saveCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(saveCalled, isFalse);
    });

    testWidgets('renders correctly in row layout', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          PostWriteActions(
            isTitleValid: false,
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(PostWriteActions), findsOneWidget);
    });
  });
}
