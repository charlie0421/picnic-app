import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';

import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteGainIndicator', () {
    testWidgets('renders nothing when diff is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VoteGainIndicator(diff: 0),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('+0'), findsNothing);
    });

    testWidgets('shows +diff text when diff > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VoteGainIndicator(diff: 5),
          ),
        ),
      );

      // Text should be visible at the start of animation
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('animation completes and hides text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VoteGainIndicator(diff: 3),
          ),
        ),
      );

      expect(find.text('+3'), findsOneWidget);

      // Advance past animation duration (1200ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 1300));

      // After animation completes, text should be gone
      expect(find.text('+3'), findsNothing);
    });

    testWidgets('is a StatefulWidget', (tester) async {
      const widget = VoteGainIndicator(diff: 1);
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('handles negative diff', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VoteGainIndicator(diff: -1),
          ),
        ),
      );

      // Negative diff should not show animation
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('disposes without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VoteGainIndicator(diff: 10),
          ),
        ),
      );

      // Pump to start animation
      await tester.pump();

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: const SizedBox()),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
