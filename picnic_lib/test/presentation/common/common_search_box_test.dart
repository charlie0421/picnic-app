import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/common_search_box.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommonSearchBox', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          CommonSearchBox(
            focusNode: focusNode,
            textEditingController: controller,
            hintText: 'Search...',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommonSearchBox), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays hint text', (WidgetTester tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          CommonSearchBox(
            focusNode: focusNode,
            textEditingController: controller,
            hintText: 'Search artists',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Search artists'), findsOneWidget);
    });

    testWidgets('renders with pre-filled text', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'BTS');
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        buildTestApp(
          CommonSearchBox(
            focusNode: focusNode,
            textEditingController: controller,
            hintText: 'Search',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BTS'), findsOneWidget);
    });
  });
}
