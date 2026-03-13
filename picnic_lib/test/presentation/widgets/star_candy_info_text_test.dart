import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('StarCandyInfoText', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarCandyInfoText(),
        ),
      );
      await tester.pump();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });

    testWidgets('renders with center alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarCandyInfoText(alignment: MainAxisAlignment.center),
        ),
      );
      await tester.pump();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });

    testWidgets('renders with start alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarCandyInfoText(alignment: MainAxisAlignment.start),
        ),
      );
      await tester.pump();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });
  });
}
