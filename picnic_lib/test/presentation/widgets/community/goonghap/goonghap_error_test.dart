import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_error.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('GoonghapErrorView', () {
    testWidgets('renders with error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapErrorView(error: 'Something went wrong'),
        ),
      );
      await tester.pump();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders with different error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapErrorView(error: 'Network error'),
        ),
      );
      await tester.pump();

      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('renders with empty error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GoonghapErrorView(error: ''),
        ),
      );
      await tester.pump();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
    });
  });
}
