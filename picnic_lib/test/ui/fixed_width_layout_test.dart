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
        buildTestApp(
          FixedWidthLayout(
            child: Text('Hello'),
          ),
        ),
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
        buildTestApp(
          FixedWidthLayout(
            maxWidth: 400,
            child: Text('Custom'),
          ),
        ),
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
        buildTestApp(
          FixedWidthLayout(
            child: Text('Test'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('MediaQuery is overridden with global provider data',
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
  });
}
