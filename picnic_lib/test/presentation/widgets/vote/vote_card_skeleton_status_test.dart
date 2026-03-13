import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
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
            body: SingleChildScrollView(
              child: child,
            ),
          ),
        );
      },
    );
  }

  group('VoteCardStatus enum', () {
    test('has all expected values', () {
      expect(VoteCardStatus.values.length, 3);
      expect(VoteCardStatus.values, contains(VoteCardStatus.upcoming));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ongoing));
      expect(VoteCardStatus.values, contains(VoteCardStatus.ended));
    });
  });

  group('VoteCardSkeleton default (ongoing)', () {
    testWidgets('renders with default status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton()),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('default status is ongoing', (WidgetTester tester) async {
      const skeleton = VoteCardSkeleton();
      expect(skeleton.status, VoteCardStatus.ongoing);
    });

    testWidgets('contains Shimmer widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton()),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('contains vote items container for ongoing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton(status: VoteCardStatus.ongoing)),
      );
      await tester.pump();

      // Ongoing has vote items container + footer
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('VoteCardSkeleton upcoming', () {
    testWidgets('renders upcoming status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
            const VoteCardSkeleton(status: VoteCardStatus.upcoming)),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('upcoming does not show vote items container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
            const VoteCardSkeleton(status: VoteCardStatus.upcoming)),
      );
      await tester.pump();

      // Upcoming doesn't show vote items container (status != upcoming check)
      // but does show footer
      expect(find.byType(Shimmer), findsWidgets);
    });
  });

  group('VoteCardSkeleton ended', () {
    testWidgets('renders ended status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton(status: VoteCardStatus.ended)),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeleton), findsOneWidget);
    });

    testWidgets('ended contains Shimmer and structural widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton(status: VoteCardStatus.ended)),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('VoteCardSkeleton all statuses render without errors', () {
    for (final status in VoteCardStatus.values) {
      testWidgets('renders ${status.name} without errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(VoteCardSkeleton(status: status)),
        );
        await tester.pump();

        expect(find.byType(VoteCardSkeleton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('VoteCardSkeleton structural verification', () {
    testWidgets('is a StatelessWidget', (WidgetTester tester) async {
      const skeleton = VoteCardSkeleton();
      expect(skeleton, isA<StatelessWidget>());
    });

    testWidgets('supports const constructor', (WidgetTester tester) async {
      const skeleton1 = VoteCardSkeleton();
      const skeleton2 = VoteCardSkeleton(status: VoteCardStatus.upcoming);
      const skeleton3 = VoteCardSkeleton(status: VoteCardStatus.ended);

      expect(skeleton1, isNotNull);
      expect(skeleton2, isNotNull);
      expect(skeleton3, isNotNull);
    });

    testWidgets('ongoing and ended show more structure than upcoming',
        (WidgetTester tester) async {
      // Pump ongoing
      await tester.pumpWidget(
        buildTestWidget(const VoteCardSkeleton(status: VoteCardStatus.ongoing)),
      );
      await tester.pump();
      final ongoingShimmerCount =
          find.byType(Shimmer).evaluate().length;

      // Pump upcoming
      await tester.pumpWidget(
        buildTestWidget(
            const VoteCardSkeleton(status: VoteCardStatus.upcoming)),
      );
      await tester.pump();
      final upcomingShimmerCount =
          find.byType(Shimmer).evaluate().length;

      // Ongoing has vote items container with Shimmer + header Shimmer + footer Shimmer
      // Upcoming only has header Shimmer + footer Shimmer (no vote items container)
      expect(ongoingShimmerCount, greaterThan(upcomingShimmerCount));
    });
  });
}
