import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/fortune_divider.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('FortuneDivider', () {
    testWidgets('renders with given color', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const FortuneDivider(color: Colors.red),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with different colors', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const FortuneDivider(color: Colors.blue),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
    });
  });
}
