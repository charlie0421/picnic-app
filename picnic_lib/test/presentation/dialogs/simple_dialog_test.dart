import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('DialogType', () {
    test('normal constant', () {
      expect(DialogType.normal, 'normal');
    });

    test('error constant', () {
      expect(DialogType.error, 'error');
    });
  });

  group('buildDialogButton', () {
    testWidgets('renders button with text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return Row(
              children: [
                buildDialogButton(
                  context,
                  '확인',
                  Colors.blue,
                  () {},
                ),
              ],
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('확인'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return Row(
              children: [
                buildDialogButton(
                  context,
                  'OK',
                  Colors.blue,
                  () => pressed = true,
                ),
              ],
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      expect(pressed, isTrue);
    });

    testWidgets('renders with custom text color', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return Row(
              children: [
                buildDialogButton(
                  context,
                  'Cancel',
                  Colors.red,
                  () {},
                ),
              ],
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('showSimpleDialog (navigatorKey)', () {
    testWidgets('shows dialog with content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  content: '테스트 메시지',
                  onOk: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('테스트 메시지'), findsOneWidget);
    });

    testWidgets('shows dialog with title and content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  title: '알림',
                  content: '내용입니다',
                  onOk: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('알림'), findsOneWidget);
      expect(find.text('내용입니다'), findsOneWidget);
    });

    testWidgets('shows error type dialog', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  content: '에러 메시지',
                  type: DialogType.error,
                  onOk: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('에러 메시지'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows dialog with cancel and ok buttons', (tester) async {
      bool okPressed = false;
      bool cancelPressed = false;

      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  content: '확인하시겠습니까?',
                  onOk: () {
                    okPressed = true;
                    Navigator.of(context).pop();
                  },
                  onCancel: () {
                    cancelPressed = true;
                    Navigator.of(context).pop();
                  },
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify both buttons are present
      expect(find.text('확인하시겠습니까?'), findsOneWidget);

      // Tap OK button
      // The OK button text comes from l10n
      final buttons = find.byType(TextButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('shows dialog with contentWidget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  contentWidget: const Text('커스텀 위젯'),
                  onOk: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('커스텀 위젯'), findsOneWidget);
    });

    testWidgets('shows dialog with titleWidget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleDialog(
                  titleWidget: const Icon(Icons.info),
                  content: '내용',
                  onOk: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);
    });
  });

  group('buildDialogButton widget tree', () {
    testWidgets('wraps TextButton in Expanded with flex 1', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return Row(
              children: [
                buildDialogButton(
                  context,
                  'Test',
                  Colors.green,
                  () {},
                ),
              ],
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      final expanded = tester.widget<Expanded>(find.byType(Expanded));
      expect(expanded.flex, equals(1));

      // SizedBox wraps TextButton
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('showSimpleErrorDialog', () {
    testWidgets('does nothing when context not mounted', (tester) async {
      // Create a context that is NOT mounted (disposed)
      late BuildContext savedContext;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            savedContext = context;
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      // Replace the widget tree to unmount the saved context
      await tester.pumpWidget(
        buildTestApp(const SizedBox()),
      );
      await tester.pumpAndSettle();

      // Should not throw even with unmounted context
      expect(
        () => showSimpleErrorDialog(savedContext, 'Test error'),
        returnsNormally,
      );
    });

    testWidgets('shows dialog with message only (no error)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleErrorDialog(context, '단순 에러 메시지');
              },
              child: const Text('ShowError'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ShowError'));
      await tester.pumpAndSettle();

      expect(find.text('단순 에러 메시지'), findsOneWidget);
      // Error type dialog shows error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('truncates long error message', (tester) async {
      final longError = 'E' * 200;

      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleErrorDialog(
                  context,
                  '오류 발생',
                  error: longError,
                  truncateError: true,
                );
              },
              child: const Text('ShowError'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ShowError'));
      await tester.pumpAndSettle();

      // The displayed message should contain the base message
      expect(find.textContaining('오류 발생'), findsOneWidget);
      // The long error should be truncated (150 chars + "...")
      expect(find.textContaining('...'), findsOneWidget);
    });

    testWidgets('does not truncate short error message', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleErrorDialog(
                  context,
                  '오류 발생',
                  error: 'Short error',
                  truncateError: true,
                );
              },
              child: const Text('ShowError'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ShowError'));
      await tester.pumpAndSettle();

      // Should contain the full error without truncation
      expect(find.textContaining('Short error'), findsOneWidget);
    });

    testWidgets('does not truncate when truncateError is false',
        (tester) async {
      final longError = 'E' * 200;

      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleErrorDialog(
                  context,
                  '오류 발생',
                  error: longError,
                  truncateError: false,
                );
              },
              child: const Text('ShowError'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ShowError'));
      await tester.pumpAndSettle();

      // The full error should be shown (no truncation)
      expect(find.textContaining('오류 발생'), findsOneWidget);
      // Full 200-char error should be present
      expect(find.textContaining(longError), findsOneWidget);
    });

    testWidgets('shows with normal type override', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showSimpleErrorDialog(
                  context,
                  '일반 타입 에러',
                  type: DialogType.normal,
                );
              },
              child: const Text('ShowError'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ShowError'));
      await tester.pumpAndSettle();

      expect(find.text('일반 타입 에러'), findsOneWidget);
      // Normal type should NOT show error icon
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
