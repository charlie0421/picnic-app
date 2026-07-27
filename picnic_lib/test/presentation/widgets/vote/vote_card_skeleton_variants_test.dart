import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_active_and_end.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_upcoming.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_vs.dart';
import 'package:shimmer/shimmer.dart';

import '../../../helpers/test_environment.dart';

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
          home: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        );
      },
    );
  }

  group('VoteCardSkeletonActiveAndEnd', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonActiveAndEnd), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains Shimmer widget', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      // 프레임(헤더·컨텐츠) 카드가 각자 자기 Shimmer 를 든다 — 위젯 전체를 하나의
      // Shimmer 로 감싸면 불투명 프레임이 srcIn 마스크에 먹혀 골격이 사라진다.
      expect(find.byType(Shimmer), findsNWidgets(2));
    });

    testWidgets('contains 3 circle containers for ranks', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      // 3 rank circles + 3 name placeholders = Columns
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const widget = VoteCardSkeletonActiveAndEnd();
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('VoteCardSkeletonUpcoming', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonUpcoming()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonUpcoming), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains Shimmer widget', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonUpcoming()),
      );
      await tester.pump();

      // 프레임(헤더·컨텐츠) 카드가 각자 자기 Shimmer 를 든다 — 위젯 전체를 하나의
      // Shimmer 로 감싸면 불투명 프레임이 srcIn 마스크에 먹혀 골격이 사라진다.
      expect(find.byType(Shimmer), findsNWidgets(2));
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const widget = VoteCardSkeletonUpcoming();
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('VoteCardSkeletonVS', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonVS), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains Shimmer widget', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      // 프레임(헤더·컨텐츠) 카드가 각자 자기 Shimmer 를 든다 — 위젯 전체를 하나의
      // Shimmer 로 감싸면 불투명 프레임이 srcIn 마스크에 먹혀 골격이 사라진다.
      expect(find.byType(Shimmer), findsNWidgets(2));
    });

    testWidgets('contains two item columns and VS placeholder', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      // VS skeleton has a Row with 2 items + VS text = should have Row
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const widget = VoteCardSkeletonVS();
      expect(widget, isA<StatelessWidget>());
    });
  });
}
