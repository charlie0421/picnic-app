import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_gap_tooltip.dart';

import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteGapTooltip', () {
    testWidgets('shows the text after fading in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: '1위와 16,800표 차이!')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1위와 16,800표 차이!'), findsOneWidget);
    });

    testWidgets('plays once, then removes itself from the tree', (tester) async {
      var dismissed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteGapTooltip(text: 'gap', onDismissed: () => dismissed++),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300)); // fade in done
      expect(find.text('gap'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100)); // hold elapsed
      await tester.pump(const Duration(milliseconds: 300)); // fade out done
      await tester.pump(); // rebuild as SizedBox.shrink

      expect(find.text('gap'), findsNothing);
      expect(dismissed, 1);
    });

    testWidgets('does not intercept taps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: 'gap')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // MaterialApp/Scaffold mount their own IgnorePointer widgets elsewhere
      // in the tree, so scope the finder to VoteGapTooltip's own subtree.
      expect(
        find.descendant(
          of: find.byType(VoteGapTooltip),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancels its timer when disposed early', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: 'gap')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount before the hold timer fires. If the timer were left pending,
      // flutter_test fails the test with "A Timer is still pending".
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
