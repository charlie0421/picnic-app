import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/ui/style.dart';

void main() {
  setUpAll(() {
    // AppColors의 Environment 의존 필드를 테스트용 기본값으로 초기화
    AppColors.primary500 = const Color(0xFF6200EE);
    AppColors.secondary500 = const Color(0xFF03DAC6);
    AppColors.sub500 = const Color(0xFF018786);
    AppColors.point500 = const Color(0xFFBB86FC);
    AppColors.point900 = const Color(0xFF3700B3);
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(
            body: child,
          ),
        );
      },
    );
  }

  group('CustomPagination 렌더링 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링되는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 5, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPagination), findsOneWidget);
    });

    testWidgets('Row 위젯이 포함되어 있는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 3, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('itemCount 수만큼 AnimatedContainer가 생성되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 5, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });

    testWidgets('itemCount가 1일 때 하나의 도트만 생성되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 1, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('itemCount가 0일 때 도트가 없는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 0, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });

  group('CustomPagination 활성 인덱스 테스트', () {
    testWidgets('activeIndex 변경 시 위젯이 리빌드되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 3, activeIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      // 첫 번째 인덱스가 활성 상태
      expect(find.byType(CustomPagination), findsOneWidget);

      // activeIndex를 변경
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 3, activeIndex: 2),
        ),
      );
      await tester.pumpAndSettle();

      // 위젯이 여전히 렌더링되는지 확인
      expect(find.byType(CustomPagination), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });
  });

  group('CustomPagination 속성 테스트', () {
    test('CustomPagination이 StatelessWidget인지 확인', () {
      const pagination = CustomPagination(itemCount: 3, activeIndex: 0);
      expect(pagination, isA<StatelessWidget>());
    });

    test('CustomPagination이 const 생성자를 지원하는지 확인', () {
      const pagination = CustomPagination(itemCount: 5, activeIndex: 2);
      expect(pagination, isNotNull);
      expect(pagination.itemCount, 5);
      expect(pagination.activeIndex, 2);
    });
  });

  group('CustomPaginationBuilder 구조 테스트', () {
    test('CustomPaginationBuilder가 인스턴스화 가능한지 확인', () {
      final builder = CustomPaginationBuilder();
      expect(builder, isNotNull);
    });

    test('CustomPaginationBuilder에 itemCount를 전달할 수 있는지 확인', () {
      final builder = CustomPaginationBuilder(itemCount: 10);
      expect(builder, isNotNull);
    });

    test('CustomPaginationBuilder가 null itemCount를 허용하는지 확인', () {
      final builder = CustomPaginationBuilder(itemCount: null);
      expect(builder, isNotNull);
    });
  });

  group('CustomPagination 다양한 itemCount 테스트', () {
    testWidgets('많은 수의 아이템이 있을 때 정상 렌더링되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 10, activeIndex: 5),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsNWidgets(10));
    });

    testWidgets('마지막 인덱스가 활성 상태일 때 정상 렌더링되는지 확인',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const CustomPagination(itemCount: 5, activeIndex: 4),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPagination), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });
  });
}
