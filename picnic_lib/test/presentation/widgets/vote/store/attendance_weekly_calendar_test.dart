import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_weekly_calendar.dart';

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
          locale: const Locale('en'),
          home: Scaffold(body: child),
        );
      },
    );
  }

  List<AttendanceDayStatus> createWeekDays({
    int todayIndex = 2,
    List<int> checkedIndices = const [],
  }) {
    return List.generate(7, (i) {
      return AttendanceDayStatus(
        date: '2026-03-${9 + i}',
        dayOfWeek: i,
        checked: checkedIndices.contains(i),
        isToday: i == todayIndex,
        isFuture: i > todayIndex,
      );
    });
  }

  group('AttendanceWeeklyCalendar', () {
    testWidgets('renders 7 day cells', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AttendanceWeeklyCalendar(
            days: createWeekDays(),
            todayChecked: false,
            weeklyBonusEligible: false,
            checkedCount: 0,
            totalRequired: 7,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
      // English locale -> English day labels
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows +60 text for each day', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AttendanceWeeklyCalendar(
            days: createWeekDays(),
            todayChecked: false,
            weeklyBonusEligible: false,
            checkedCount: 0,
            totalRequired: 7,
          ),
        ),
      );
      await tester.pump();

      // Each day cell shows +60
      expect(find.text('+60'), findsNWidgets(7));
    });

    testWidgets('renders with no days checked', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AttendanceWeeklyCalendar(
            days: createWeekDays(todayIndex: 0, checkedIndices: []),
            todayChecked: false,
            weeklyBonusEligible: false,
            checkedCount: 0,
            totalRequired: 7,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });

    testWidgets('handles empty days list', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AttendanceWeeklyCalendar(
            days: [],
            todayChecked: false,
            weeklyBonusEligible: false,
            checkedCount: 0,
            totalRequired: 7,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const widget = AttendanceWeeklyCalendar(
        days: [],
        todayChecked: false,
        weeklyBonusEligible: false,
        checkedCount: 0,
        totalRequired: 7,
      );
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('Sunday shows x2 badge', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AttendanceWeeklyCalendar(
            days: createWeekDays(),
            todayChecked: false,
            weeklyBonusEligible: false,
            checkedCount: 0,
            totalRequired: 7,
          ),
        ),
      );
      await tester.pump();

      // Sunday (index 6, dayOfWeek 6) should show x2 badge
      expect(find.text('x2'), findsOneWidget);
    });
  });
}
