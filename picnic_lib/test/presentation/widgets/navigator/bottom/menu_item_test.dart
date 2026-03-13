import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('MenuItem', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MenuItem(
            title: 'Vote',
            assetPath: 'assets/icons/navigation/vote.svg',
            index: 0,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MenuItem), findsOneWidget);
    });

    testWidgets('renders with needLogin flag', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const MenuItem(
            title: 'MyPage',
            assetPath: 'assets/icons/navigation/vote.svg',
            index: 2,
            needLogin: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MenuItem), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
