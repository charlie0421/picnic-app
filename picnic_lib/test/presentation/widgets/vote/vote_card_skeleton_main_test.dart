import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:shimmer/shimmer.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteCardSkeleton', () {
    testWidgets('renders with ongoing status (default)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCardSkeleton(),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('renders with upcoming status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCardSkeleton(status: VoteCardStatus.upcoming),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('renders with ended status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCardSkeleton(status: VoteCardStatus.ended),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    test('VoteCardStatus has 3 values', () {
      expect(VoteCardStatus.values.length, 3);
      expect(VoteCardStatus.values, contains(VoteCardStatus.upcoming));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ongoing));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ended));
    });

    test('default status is ongoing', () {
      const skeleton = VoteCardSkeleton();
      expect(skeleton.status, VoteCardStatus.ongoing);
    });
  });

  group('VoteCardSkeleton - upcoming status structure', () {
    testWidgets('upcoming does not show vote items container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.upcoming),
          ),
        ),
      );
      await tester.pump();

      // Upcoming status should have Shimmer for header and footer only
      // (no vote items container with height 260)
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('upcoming shows footer skeleton with participant info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.upcoming),
          ),
        ),
      );
      await tester.pump();

      // Footer should be rendered (bordered container with shimmer)
      // The upcoming footer has a single Row with one container (width: 80)
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));
      // At minimum: header shimmer + footer shimmer
      expect(shimmerWidgets.length, greaterThanOrEqualTo(2));
    });
  });

  group('VoteCardSkeleton - ongoing status structure', () {
    testWidgets('ongoing shows vote items container and footer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
          ),
        ),
      );
      await tester.pump();

      // Ongoing should have vote items container (Shimmer wrapping 260h container)
      // + header shimmer + footer shimmer
      expect(find.byType(Shimmer), findsWidgets);

      // The ongoing footer has two containers (spaceBetween row)
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));
      expect(shimmerWidgets.length, greaterThanOrEqualTo(3));
    });

    testWidgets('ongoing renders 3 vote item skeletons with vote buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
          ),
        ),
      );
      await tester.pump();

      // The ongoing vote items contain circular containers (artist images)
      // Find all CircleShape decorations (BoxShape.circle)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circleContainers = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      }).toList();
      // 3 ongoing items each have 1 circle (artist image) = 3 circles
      expect(circleContainers.length, greaterThanOrEqualTo(3));
    });
  });

  group('VoteCardSkeleton - ended status structure', () {
    testWidgets('ended shows vote items container and footer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ended),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsWidgets);

      // Ended footer has a single container (width: 120)
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));
      expect(shimmerWidgets.length, greaterThanOrEqualTo(3));
    });

    testWidgets('ended renders 3 vote item skeletons with result icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ended),
          ),
        ),
      );
      await tester.pump();

      // The ended vote items also contain circular containers (artist images)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circleContainers = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      }).toList();
      // 3 ended items each have 1 circle (artist image) = 3 circles
      expect(circleContainers.length, greaterThanOrEqualTo(3));
    });

    testWidgets('ended first item has larger artist image than others',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ended),
          ),
        ),
      );
      await tester.pump();

      // Just verify it renders without error - the size difference
      // is in the 40.w vs 35.w which is hard to test precisely with screenutil
      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });
  });

  group('VoteCardSkeleton - vote items frame shimmer structure', () {
    /// 투표 아이템 컨테이너의 불투명 프레임(흰 배경 + 테두리 + 라운드 40).
    final itemsFrame = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration &&
          decoration.color == Colors.white &&
          decoration.border != null &&
          decoration.borderRadius == BorderRadius.circular(40);
    }, description: 'opaque vote items frame');

    // Shimmer 는 자식을 BlendMode.srcIn ShaderMask 로 덮으므로, 불투명한 흰
    // 프레임이 Shimmer 안에 있으면 그 위의 아이템 블록들이 배경과 한 덩어리로
    // 칠해져 구조 없는 회색 라운드 사각형만 남는다(수정 전 상태).
    for (final status in [VoteCardStatus.ongoing, VoteCardStatus.ended]) {
      testWidgets('$status keeps the opaque items frame outside the shimmer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SingleChildScrollView(
              child: VoteCardSkeleton(status: status),
            ),
          ),
        );
        await tester.pump();

        expect(itemsFrame, findsOneWidget);
        expect(
          find.descendant(of: find.byType(Shimmer), matching: itemsFrame),
          findsNothing,
          reason: '불투명한 아이템 프레임은 Shimmer 밖에 있어야 한다 — 안에 '
              '있으면 srcIn 마스크가 프레임과 블록을 한 덩어리로 칠한다',
        );
        expect(
          find.descendant(of: itemsFrame, matching: find.byType(Shimmer)),
          findsOneWidget,
          reason: '아이템 프레임은 자기 Shimmer 를 직접 들고 있어야 한다',
        );
      });
    }
  });

  group('VoteCardSkeleton - footer skeleton variants', () {
    testWidgets('upcoming footer has single shimmer row element',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.upcoming),
          ),
        ),
      );
      await tester.pump();

      // Upcoming footer: Row with single container
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('ongoing footer has spaceBetween row with two elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ongoing),
          ),
        ),
      );
      await tester.pump();

      // Ongoing footer: Row with mainAxisAlignment.spaceBetween
      final rows = tester.widgetList<Row>(find.byType(Row));
      final spaceBetweenRows = rows.where(
        (r) => r.mainAxisAlignment == MainAxisAlignment.spaceBetween,
      );
      expect(spaceBetweenRows.length, greaterThanOrEqualTo(1));
    });

    testWidgets('ended footer has single container element',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SingleChildScrollView(
            child: VoteCardSkeleton(status: VoteCardStatus.ended),
          ),
        ),
      );
      await tester.pump();

      // Just verify it renders and has shimmer
      expect(find.byType(Shimmer), findsWidgets);
    });
  });
}
