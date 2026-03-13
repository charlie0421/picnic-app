import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/overlay_notifier.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('OverlayNotification', () {
    // Helper to tear down widget and flush pending timers
    Future<void> tearDownWidget(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      // Flush any pending timers from Future.doWhile
      await tester.pump(const Duration(seconds: 10));
    }

    testWidgets('renders with childBuilder output', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('Remaining: $remaining'),
            duration: const Duration(seconds: 3),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(OverlayNotification), findsOneWidget);
      expect(find.text('Remaining: 3'), findsOneWidget);

      await tearDownWidget(tester);
    });

    testWidgets('uses SlideTransition for animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('$remaining'),
            duration: const Duration(seconds: 1),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(OverlayNotification),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );

      await tearDownWidget(tester);
    });

    testWidgets('wraps content in SafeArea and Material', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('$remaining'),
            duration: const Duration(seconds: 1),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Material), findsWidgets);

      await tearDownWidget(tester);
    });

    testWidgets('countdown decrements remaining seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('Remaining: $remaining'),
            duration: const Duration(seconds: 3),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Remaining: 3'), findsOneWidget);

      // Advance 1 second for countdown
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Remaining: 2'), findsOneWidget);

      // Advance another second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Remaining: 1'), findsOneWidget);

      await tearDownWidget(tester);
    });

    testWidgets('calls onDismiss after duration expires', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('$remaining'),
            duration: const Duration(seconds: 2),
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump();

      // Count down to zero: 2 -> 1 -> 0
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Wait for reverse animation (300ms) to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(dismissed, isTrue);
    });

    testWidgets('default duration is 5 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('Remaining: $remaining'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Remaining: 5'), findsOneWidget);

      await tearDownWidget(tester);
    });

    testWidgets('slide animation completes on forward', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('$remaining'),
            duration: const Duration(seconds: 1),
          ),
        ),
      );

      // Let the 300ms forward animation complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(OverlayNotification), findsOneWidget);

      await tearDownWidget(tester);
    });

    testWidgets('disposes without error when removed from tree', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          OverlayNotification(
            childBuilder: (remaining) => Text('$remaining'),
            duration: const Duration(seconds: 1),
          ),
        ),
      );
      await tester.pump();

      // Replace widget tree to trigger dispose
      await tester.pumpWidget(
        buildTestApp(const SizedBox()),
      );
      // Flush pending timers
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(OverlayNotification), findsNothing);
    });
  });
}
