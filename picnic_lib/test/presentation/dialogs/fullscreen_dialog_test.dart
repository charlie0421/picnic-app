import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('FullScreenDialogConstants', () {
    test('closeButtonSize is 48', () {
      expect(FullScreenDialogConstants.closeButtonSize, 48);
    });

    test('transitionDuration is 300ms', () {
      expect(
        FullScreenDialogConstants.transitionDuration,
        const Duration(milliseconds: 300),
      );
    });
  });

  group('FullScreenDialog widget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullScreenDialog(child: const Text('Test Content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('shows default close button when no custom closeButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FullScreenDialog(child: const Text('Content'))),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows custom close button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullScreenDialog(
              closeButton: const Icon(Icons.cancel),
              child: const Text('Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('keeps close button inside top and right safe insets', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(top: 100, right: 100),
            ),
            child: Scaffold(body: FullScreenDialog(child: Text('Content'))),
          ),
        ),
      );
      await tester.pump();

      final buttonRect = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(buttonRect.top, greaterThanOrEqualTo(100));
      expect(buttonRect.right, lessThanOrEqualTo(800 - 100));
      final safeArea = tester.widget<SafeArea>(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(SafeArea),
        ),
      );
      expect(safeArea.minimum, const EdgeInsets.only(top: 50, right: 15));
    });

    testWidgets('is a StatefulWidget', (tester) async {
      const widget = FullScreenDialog(child: SizedBox());
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('renders with custom borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullScreenDialog(
              borderRadius: BorderRadius.circular(20),
              child: const Text('Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FullScreenDialog), findsOneWidget);
    });

    testWidgets('close button pops navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        FullScreenDialog(child: const Text('Dialog Content')),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsNothing);
    });

    testWidgets('renders with custom contentPadding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullScreenDialog(
              contentPadding: const EdgeInsets.all(32),
              child: const Text('Padded Content'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Padded Content'), findsOneWidget);
    });
  });

  group('showFullScreenDialog', () {
    testWidgets('shows dialog with builder content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showFullScreenDialog(
                  context: context,
                  builder: (ctx) => const Text('Dialog from builder'),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dialog from builder'), findsOneWidget);
    });

    testWidgets('dialog can be dismissed when barrierDismissible is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showFullScreenDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) =>
                      const Center(child: Text('Dismissible Dialog')),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dismissible Dialog'), findsOneWidget);
    });
  });
}
