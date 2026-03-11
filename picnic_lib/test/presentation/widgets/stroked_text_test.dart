import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/stroked_text.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('StrokedText', () {
    testWidgets('renders text content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StrokedText(
            text: 'Hello',
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stack renders two Text widgets (stroke + fill)
      expect(find.text('Hello'), findsNWidgets(2));
    });

    testWidgets('renders with custom stroke color', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StrokedText(
            text: 'Styled',
            textStyle: const TextStyle(fontSize: 20),
            strokeColor: Colors.red,
            strokeWidth: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Styled'), findsNWidgets(2));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders with default stroke width', (tester) async {
      final widget = StrokedText(
        text: 'Default',
        textStyle: const TextStyle(fontSize: 14),
      );

      expect(widget.strokeWidth, 1);
    });

    testWidgets('renders inside a Stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StrokedText(
            text: 'Stack Test',
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StrokedText), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });
  });
}
