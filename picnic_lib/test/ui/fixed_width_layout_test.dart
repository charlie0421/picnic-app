import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

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

    testWidgets(
      'content width is capped even with a different startup snapshot',
      (tester) async {
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
                  // The test window is wider than the content cap. The startup
                  // snapshot must not determine the current content width.
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
      },
    );
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

    testWidgets('content metrics follow fold and unfold without losing input', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController(text: 'keep my input');
      addTearDown(controller.dispose);
      MediaQueryData? seen;
      double? actualWidth;
      final app = buildTestApp(
        FixedWidthLayout(
          child: LayoutBuilder(
            builder: (context, constraints) {
              seen = MediaQuery.of(context);
              actualWidth = constraints.maxWidth;
              return TextField(controller: controller);
            },
          ),
        ),
        mediaQueryData: const MediaQueryData(size: Size(360, 800)),
      );

      for (final (size, expectedWidth) in [
        (const Size(360, 800), 360.0),
        (const Size(416, 657), 416.0),
        (const Size(466, 678), 466.0),
        (const Size(951, 669), 600.0),
        (const Size(600, 400), 600.0),
        (const Size(466, 678), 466.0),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app);
        await tester.pump();
        expect(actualWidth, expectedWidth, reason: '$size');
        expect(seen!.size.width, expectedWidth, reason: '$size');
        expect(seen!.size.height, size.height, reason: '$size');
        expect(find.text('keep my input'), findsOneWidget);
      }
    });

    testWidgets('keyboard changes reach the content Scaffold', (tester) async {
      final metrics = ValueNotifier(const MediaQueryData(size: Size(466, 678)));
      addTearDown(metrics.dispose);
      MediaQueryData? seen;
      double? bodyHeight;
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder(
            valueListenable: metrics,
            builder: (context, value, child) => MediaQuery(
              data: value,
              child: SizedBox(
                width: 466,
                height: 678,
                child: FixedWidthLayout(
                  child: Builder(
                    builder: (context) {
                      seen = MediaQuery.of(context);
                      return Scaffold(
                        body: LayoutBuilder(
                          builder: (context, c) {
                            bodyHeight = c.maxHeight;
                            return const SizedBox.expand();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          mediaQueryData: const MediaQueryData(size: Size(466, 678)),
        ),
      );
      await tester.pump();
      final initialHeight = bodyHeight!;
      for (final inset in [300.0, 0.0]) {
        metrics.value = metrics.value.copyWith(
          viewInsets: EdgeInsets.only(bottom: inset),
        );
        await tester.pump();
        expect(seen!.viewInsets.bottom, inset);
        expect(bodyHeight, initialHeight - inset);
      }
    });

    testWidgets('accessibility and display features use current metrics', (
      tester,
    ) async {
      final metrics = ValueNotifier(const MediaQueryData(size: Size(466, 678)));
      addTearDown(metrics.dispose);
      MediaQueryData? seen;
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder(
            valueListenable: metrics,
            builder: (context, value, child) => MediaQuery(
              data: value,
              child: FixedWidthLayout(
                child: Builder(
                  builder: (context) {
                    seen = MediaQuery.of(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      const fold = DisplayFeature(
        bounds: Rect.fromLTWH(233, 0, 0, 678),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      );
      metrics.value = metrics.value.copyWith(
        textScaler: const TextScaler.linear(2),
        accessibleNavigation: true,
        displayFeatures: [fold],
      );
      await tester.pump();
      expect(seen!.textScaler.scale(14), 28);
      expect(seen!.accessibleNavigation, isTrue);
      expect(seen!.displayFeatures, [fold]);
    });
  });
}
