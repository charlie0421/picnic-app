import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';

import '../helpers/test_app.dart';
import '../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('FixedWidthLayout', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FixedWidthLayout(child: Text('Hello'))),
      );
      await tester.pump();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('default maxWidth is 600', (tester) async {
      const widget = FixedWidthLayout(child: SizedBox());
      expect(widget.maxWidth, equals(600));
    });

    testWidgets('custom maxWidth is applied', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FixedWidthLayout(maxWidth: 400, child: Text('Custom'))),
      );
      await tester.pump();

      // Find the ConstrainedBox that has maxWidth 400
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final matching = constrainedBoxes.where(
        (cb) => cb.constraints.maxWidth == 400,
      );
      expect(matching, isNotEmpty);
    });

    testWidgets('contains Center and ConstrainedBox', (tester) async {
      await tester.pumpWidget(
        buildTestApp(FixedWidthLayout(child: Text('Test'))),
      );
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('MediaQuery is overridden with global provider data', (
      tester,
    ) async {
      const testMediaQuery = MediaQueryData(
        size: Size(500, 900),
        padding: EdgeInsets.only(top: 20, bottom: 10),
        devicePixelRatio: 2.0,
      );

      await tester.pumpWidget(
        buildTestApp(
          FixedWidthLayout(
            child: Builder(
              builder: (context) {
                final mq = MediaQuery.of(context);
                // The FixedWidthLayout overrides size width with maxWidth (600)
                // and height with constraints.maxHeight
                expect(mq.size.width, equals(600));
                return Text('MediaQuery Test');
              },
            ),
          ),
          mediaQueryData: testMediaQuery,
        ),
      );
      await tester.pump();

      expect(find.text('MediaQuery Test'), findsOneWidget);
    });
    // PICNIC-777: the root SystemNavigationBarInset zeroes the bottom insets
    // for its subtree. FixedWidthLayout must not resurrect them from the
    // startup snapshot, otherwise Portal pages double-pad and the floating
    // bottom nav floats 48dp too high on Android.
    testWidgets(
      'bottom padding/viewPadding follow the live MediaQuery, not the snapshot',
      (tester) async {
        MediaQueryData? seen;
        await tester.pumpWidget(
          buildTestApp(
            FixedWidthLayout(
              child: Builder(
                builder: (context) {
                  seen = MediaQuery.of(context);
                  return const Text('live');
                },
              ),
            ),
            // Snapshot captured with a 48dp system bar.
            mediaQueryData: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 48),
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
          ),
        );
        await tester.pump();

        // The harness installs no bottom inset above FixedWidthLayout.
        expect(seen!.padding.bottom, 0);
        expect(seen!.viewPadding.bottom, 0);
      },
    );

    testWidgets('live bottom insets above FixedWidthLayout reach the child', (
      tester,
    ) async {
      MediaQueryData? seen;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 34),
                viewPadding: const EdgeInsets.only(bottom: 34),
              ),
              child: FixedWidthLayout(
                child: Builder(
                  builder: (context) {
                    seen = MediaQuery.of(context);
                    return const Text('live');
                  },
                ),
              ),
            ),
          ),
          mediaQueryData: const MediaQueryData(size: Size(400, 800)),
        ),
      );
      await tester.pump();

      expect(seen!.padding.bottom, 34);
      expect(seen!.viewPadding.bottom, 34);
    });
  });
}
