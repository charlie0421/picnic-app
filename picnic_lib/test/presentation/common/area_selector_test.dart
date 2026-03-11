import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/area_selector.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('AreaSelector', () {
    testWidgets('renders dropdown with default area', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const AreaSelector()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AreaSelector), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('renders with kpop area setting', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AreaSelector(),
          setting: MockData.setting(area: 'kpop'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AreaSelector), findsOneWidget);
    });

    testWidgets('renders with musical area setting', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AreaSelector(),
          setting: MockData.setting(area: 'musical'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AreaSelector), findsOneWidget);
    });
  });
}
