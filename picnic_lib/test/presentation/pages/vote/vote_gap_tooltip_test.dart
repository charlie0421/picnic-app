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

      // t=300: past the 260ms fade-in, which is when the 1000ms hold
      // actually starts counting.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('gap'), findsOneWidget);

      // t=1300: past the hold's end (260 + 1000 = 1260ms), so fade-out
      // has started but not yet finished.
      await tester.pump(const Duration(milliseconds: 1000));

      // t=1600: past fade-out's end (1260 + 260 = 1520ms).
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(); // rebuild as SizedBox.shrink

      expect(find.text('gap'), findsNothing);
      expect(dismissed, 1);
    });

    testWidgets(
        'holds for 1000ms measured from the end of the fade-in, not from mount',
        (tester) async {
      // Pins the timing contract with fine-grained (~frame-sized) pumps so
      // each checkpoint lands close to its real target instead of being
      // swallowed by one large pump:
      //   t=260   fade-in done; the 1000ms hold starts counting HERE
      //   t=1260  hold ends, fade-out starts
      //   t=1520  fade-out done, onDismissed fires
      //
      // If the hold were (incorrectly) measured from mount instead of from
      // the end of the fade-in, the tooltip would already be dismissed by
      // roughly t=1260ms (mount + 1000ms hold + 260ms fade-out) rather than
      // t=1520ms -- the middle checkpoint below lands squarely in the gap
      // between those two totals and catches exactly that regression.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: 'gap')),
        ),
      );

      const step = Duration(milliseconds: 20);
      var elapsed = Duration.zero;
      Future<void> pumpTo(Duration target) async {
        while (elapsed < target) {
          await tester.pump(step);
          elapsed += step;
        }
      }

      // Shortly before the hold ends (260 + 1000 = 1260ms) -- still well
      // inside the hold under the fix, and (not yet a useful signal on its
      // own) not yet dismissed under the old mount-anchored bug either.
      await pumpTo(const Duration(milliseconds: 1240));
      expect(find.text('gap'), findsOneWidget);

      // t=1400: past where the old mount-anchored bug would already have
      // fired onDismissed (~1260ms), but still well before the fix's real
      // fade-out completion (1520ms). This is the assertion that actually
      // fails if the hold-timer regresses to counting from mount again.
      await pumpTo(const Duration(milliseconds: 1400));
      expect(find.text('gap'), findsOneWidget);

      // Shortly after fade-out completes (1260 + 260 = 1520ms).
      await pumpTo(const Duration(milliseconds: 1580));
      expect(find.text('gap'), findsNothing);
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
