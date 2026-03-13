import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/application_count_tag.dart';

import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(body: child),
        );
      },
    );
  }

  group('ApplicationCountTag', () {
    testWidgets('renders with count', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ApplicationCountTag(applicationCount: 42)),
      );
      await tester.pump();

      expect(find.byType(ApplicationCountTag), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('formats large numbers with comma', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ApplicationCountTag(applicationCount: 1234)),
      );
      await tester.pump();

      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('renders zero count', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ApplicationCountTag(applicationCount: 0)),
      );
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('contains vote icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ApplicationCountTag(applicationCount: 5)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const tag = ApplicationCountTag(applicationCount: 10);
      expect(tag, isA<StatelessWidget>());
    });
  });
}
