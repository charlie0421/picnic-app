import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('LargePopupWidget', () {
    testWidgets('renders with content only', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: Text('Test Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LargePopupWidget), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders with title widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            titleWidget: Text('Title'),
            content: Text('Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders with close button hidden', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: Text('Content'),
            showCloseButton: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LargePopupWidget), findsOneWidget);
    });

    testWidgets('renders with custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: Text('Content'),
            backgroundColor: Colors.blue,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LargePopupWidget), findsOneWidget);
    });

    testWidgets('renders with custom width', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const LargePopupWidget(
            content: Text('Content'),
            width: 300,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LargePopupWidget), findsOneWidget);
    });
  });
}
