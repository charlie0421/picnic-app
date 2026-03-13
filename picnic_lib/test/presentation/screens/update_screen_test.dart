import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/screens/update_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('UpdateScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UpdateScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(UpdateScreen), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });

    testWidgets('has two elevated buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UpdateScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('shows exit button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const UpdateScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('종료'), findsOneWidget);
    });
  });
}
