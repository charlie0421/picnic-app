import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_submit_button.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('QnaSubmitButton', () {
    testWidgets('fab renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: Builder(
              builder: (context) => Scaffold(
                floatingActionButton: QnaSubmitButton.fab(
                  context,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('primary renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => QnaSubmitButton.primary(
              context,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('primary shows loading state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => QnaSubmitButton.primary(
              context,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('primary with custom icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => QnaSubmitButton.primary(
              context,
              onPressed: () {},
              icon: Icons.send,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
