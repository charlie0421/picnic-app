import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/fortune_divider.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_error.dart';
import 'package:picnic_lib/presentation/widgets/stroked_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_weekly_calendar.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  Widget wrapWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('FortuneDivider', () {
    testWidgets('renders with given color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const FortuneDivider(color: Colors.red),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with different color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const FortuneDivider(color: Colors.blue),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FortuneDivider), findsOneWidget);
    });
  });

  group('GoonghapErrorView', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const GoonghapErrorView(error: '테스트 에러 메시지'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('테스트 에러 메시지'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays long error message', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const GoonghapErrorView(error: '이것은 매우 긴 에러 메시지입니다. 여러 줄에 걸쳐 표시될 수 있습니다.'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GoonghapErrorView), findsOneWidget);
    });
  });

  group('StrokedText', () {
    testWidgets('renders text with stroke', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: '테스트',
          textStyle: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ));
      await tester.pumpAndSettle();

      // Stack contains two Text widgets (stroke + fill)
      expect(find.text('테스트'), findsNWidgets(2));
    });

    testWidgets('renders with custom stroke color and width', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: 'Hello',
          textStyle: const TextStyle(fontSize: 16, color: Colors.black),
          strokeColor: Colors.red,
          strokeWidth: 3,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNWidgets(2));
    });

    testWidgets('uses default stroke color', (tester) async {
      await tester.pumpWidget(wrapWidget(
        StrokedText(
          text: 'Default',
          textStyle: const TextStyle(fontSize: 14),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StrokedText), findsOneWidget);
    });
  });

  group('AttendanceWeeklyCalendar', () {
    List<AttendanceDayStatus> createDays({
      int todayIndex = 2,
      List<int> checkedIndices = const [0, 1],
    }) {
      return List.generate(7, (i) => AttendanceDayStatus(
        date: '2025-03-${10 + i}',
        dayOfWeek: i,
        checked: checkedIndices.contains(i),
        isToday: i == todayIndex,
        isFuture: i > todayIndex,
      ));
    }

    testWidgets('renders 7 day cells', (tester) async {
      final days = createDays();
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: false,
          weeklyBonusEligible: false,
          checkedCount: 2,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
      // Should show day labels
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows checked state for today', (tester) async {
      final days = createDays(todayIndex: 3);
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: true,
          weeklyBonusEligible: true,
          checkedCount: 3,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });

    testWidgets('all days checked', (tester) async {
      final days = List.generate(7, (i) => AttendanceDayStatus(
        date: '2025-03-${10 + i}',
        dayOfWeek: i,
        checked: true,
        isToday: i == 6,
        isFuture: false,
      ));
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: true,
          weeklyBonusEligible: true,
          checkedCount: 7,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });

    testWidgets('no days checked', (tester) async {
      final days = createDays(todayIndex: 0, checkedIndices: []);
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: false,
          weeklyBonusEligible: false,
          checkedCount: 0,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });

    testWidgets('handles fewer than 7 days', (tester) async {
      final days = List.generate(3, (i) => AttendanceDayStatus(
        date: '2025-03-${10 + i}',
        dayOfWeek: i,
        checked: false,
        isToday: i == 0,
        isFuture: i > 0,
      ));
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: false,
          weeklyBonusEligible: false,
          checkedCount: 0,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });

    testWidgets('renders all point labels', (tester) async {
      final days = createDays();
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: false,
          weeklyBonusEligible: true,
          checkedCount: 2,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      // Each day shows '+60' label
      expect(find.text('+60'), findsNWidgets(7));
    });

    testWidgets('Sunday has special styling (dayOfWeek == 6)', (tester) async {
      final days = List.generate(7, (i) => AttendanceDayStatus(
        date: '2025-03-${10 + i}',
        dayOfWeek: i,
        checked: false,
        isToday: false,
        isFuture: true,
      ));
      await tester.pumpWidget(wrapWidget(
        AttendanceWeeklyCalendar(
          days: days,
          todayChecked: false,
          weeklyBonusEligible: false,
          checkedCount: 0,
          totalRequired: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceWeeklyCalendar), findsOneWidget);
    });
  });

  group('AttendanceDayStatus', () {
    test('fromJson', () {
      final json = {
        'date': '2025-03-10',
        'dayOfWeek': 0,
        'checked': true,
        'isToday': false,
        'isFuture': false,
      };
      final status = AttendanceDayStatus.fromJson(json);
      expect(status.date, '2025-03-10');
      expect(status.dayOfWeek, 0);
      expect(status.checked, isTrue);
      expect(status.isToday, isFalse);
      expect(status.isFuture, isFalse);
    });

    test('constructor', () {
      const status = AttendanceDayStatus(
        date: '2025-03-15',
        dayOfWeek: 5,
        checked: false,
        isToday: true,
        isFuture: false,
      );
      expect(status.date, '2025-03-15');
      expect(status.dayOfWeek, 5);
      expect(status.isToday, isTrue);
    });
  });
}
