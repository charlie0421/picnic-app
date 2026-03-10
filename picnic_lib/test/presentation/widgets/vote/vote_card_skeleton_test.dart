import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_active_and_end.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_upcoming.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_vs.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: child,
            ),
          ),
        );
      },
    );
  }

  group('VoteCardSkeletonActiveAndEnd 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonActiveAndEnd), findsOneWidget);
    });

    testWidgets('Shimmer 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Column 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('Row 위젯이 투표 결과 영역에 포함되어 있는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonActiveAndEnd()),
      );
      await tester.pump();

      // 투표 결과 영역에 Row가 있는지 확인 (순위 스켈레톤들)
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('VoteCardSkeletonUpcoming 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonUpcoming()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonUpcoming), findsOneWidget);
    });

    testWidgets('Shimmer 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonUpcoming()),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Column 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonUpcoming()),
      );
      await tester.pump();

      expect(find.byType(Column), findsWidgets);
    });
  });

  group('VoteCardSkeletonVS 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonVS), findsOneWidget);
    });

    testWidgets('Shimmer 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('VS 영역에 Row 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      // VS 투표 아이템 영역에 Row가 있는지 확인
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Column 위젯이 여러 개 포함되어 있는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeletonVS()),
      );
      await tester.pump();

      // 헤더 Column + 아이템 Column들
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('스켈레톤 위젯 공통 테스트', () {
    testWidgets('세 가지 스켈레톤 위젯이 모두 const 생성자를 지원하는지 확인',
        (WidgetTester tester) async {
      // const 생성자가 가능한지 컴파일 시점에서 확인
      const activeAndEnd = VoteCardSkeletonActiveAndEnd();
      const upcoming = VoteCardSkeletonUpcoming();
      const vs = VoteCardSkeletonVS();

      expect(activeAndEnd, isNotNull);
      expect(upcoming, isNotNull);
      expect(vs, isNotNull);
    });

    testWidgets('모든 스켈레톤 위젯이 StatelessWidget인지 확인',
        (WidgetTester tester) async {
      const activeAndEnd = VoteCardSkeletonActiveAndEnd();
      const upcoming = VoteCardSkeletonUpcoming();
      const vs = VoteCardSkeletonVS();

      expect(activeAndEnd, isA<StatelessWidget>());
      expect(upcoming, isA<StatelessWidget>());
      expect(vs, isA<StatelessWidget>());
    });
  });
}
