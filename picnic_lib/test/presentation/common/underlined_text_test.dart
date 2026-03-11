import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('UnderlinedText', () {
    testWidgets('renders text content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(text: 'Hello World'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders with custom text style', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(
            text: 'Styled',
            textStyle: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Styled'));
      expect(textWidget.style?.fontSize, 20);
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('renders underline container', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(
            text: 'Underlined',
            underlineColor: Colors.blue,
            underlineHeight: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UnderlinedText), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with default properties', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(text: 'Default'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IntrinsicWidth), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders with maxLines', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(
            text: 'Long text that might overflow',
            maxLines: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(
        find.text('Long text that might overflow'),
      );
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders with custom overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UnderlinedText(
            text: 'Clip text',
            overflow: TextOverflow.clip,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Clip text'));
      expect(textWidget.overflow, TextOverflow.clip);
    });
  });
}
