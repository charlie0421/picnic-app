import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('NetworkErrorScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          NetworkErrorScreen(onRetry: () {}),
        ),
      );
      await tester.pump();

      expect(find.byType(NetworkErrorScreen), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('calls onRetry when button pressed', (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildTestApp(
          NetworkErrorScreen(onRetry: () => retried = true),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      expect(retried, true);
    });

    testWidgets('contains retry icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          NetworkErrorScreen(onRetry: () {}),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
