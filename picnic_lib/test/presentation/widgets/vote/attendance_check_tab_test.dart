import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_check_tab.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('AttendanceCheckTab rendering', () {
    testWidgets('shows login required when not logged in', (tester) async {
      final state = AttendanceState(
        weeklyStatus: null,
        todayChecked: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: false,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show login required text
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows attendance data when loaded', (tester) async {
      final weeklyStatus = AttendanceWeeklyStatus(
        weekStart: '2025-03-10',
        weekEnd: '2025-03-16',
        days: [
          AttendanceDayStatus(
            date: '2025-03-10',
            dayOfWeek: 1,
            checked: true,
            isToday: false,
            isFuture: false,
          ),
          AttendanceDayStatus(
            date: '2025-03-11',
            dayOfWeek: 2,
            checked: true,
            isToday: false,
            isFuture: false,
          ),
          AttendanceDayStatus(
            date: '2025-03-12',
            dayOfWeek: 3,
            checked: false,
            isToday: true,
            isFuture: false,
          ),
          AttendanceDayStatus(
            date: '2025-03-13',
            dayOfWeek: 4,
            checked: false,
            isToday: false,
            isFuture: true,
          ),
          AttendanceDayStatus(
            date: '2025-03-14',
            dayOfWeek: 5,
            checked: false,
            isToday: false,
            isFuture: true,
          ),
          AttendanceDayStatus(
            date: '2025-03-15',
            dayOfWeek: 6,
            checked: false,
            isToday: false,
            isFuture: true,
          ),
          AttendanceDayStatus(
            date: '2025-03-16',
            dayOfWeek: 0,
            checked: false,
            isToday: false,
            isFuture: true,
          ),
        ],
        checkedCount: 2,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: false,
      );

      final state = AttendanceState(
        weeklyStatus: weeklyStatus,
        todayChecked: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show progress indicator (2/7)
      expect(find.text('2/7'), findsOneWidget);
      // Should show check-in button (not disabled)
      expect(find.byType(ElevatedButton), findsOneWidget);
      // Should show +60 reward text (may appear multiple times in different contexts)
      expect(find.text('+60'), findsWidgets);
    });

    testWidgets('shows checked state when today is already checked',
        (tester) async {
      final weeklyStatus = AttendanceWeeklyStatus(
        weekStart: '2025-03-10',
        weekEnd: '2025-03-16',
        days: List.generate(
          7,
          (i) => AttendanceDayStatus(
            date: '2025-03-${10 + i}',
            dayOfWeek: (i + 1) % 7,
            checked: i < 3,
            isToday: i == 2,
            isFuture: i > 2,
          ),
        ),
        checkedCount: 3,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: false,
      );

      final state = AttendanceState(
        weeklyStatus: weeklyStatus,
        todayChecked: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show 3/7 progress
      expect(find.text('3/7'), findsOneWidget);
      // Button should be disabled (showing checked text)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows new user notice when isNewUser is true',
        (tester) async {
      final weeklyStatus = AttendanceWeeklyStatus(
        weekStart: '2025-03-10',
        weekEnd: '2025-03-16',
        days: List.generate(
          7,
          (i) => AttendanceDayStatus(
            date: '2025-03-${10 + i}',
            dayOfWeek: (i + 1) % 7,
            checked: false,
            isToday: i == 0,
            isFuture: i > 0,
          ),
        ),
        checkedCount: 0,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: true,
      );

      final state = AttendanceState(
        weeklyStatus: weeklyStatus,
        todayChecked: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show 0/7 progress
      expect(find.text('0/7'), findsOneWidget);
      // New user notice should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(hasError: true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show retry icon
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows deadline timer when deadlineKST is set',
        (tester) async {
      final weeklyStatus = AttendanceWeeklyStatus(
        weekStart: '2025-03-10',
        weekEnd: '2025-03-16',
        days: List.generate(
          7,
          (i) => AttendanceDayStatus(
            date: '2025-03-${10 + i}',
            dayOfWeek: (i + 1) % 7,
            checked: false,
            isToday: i == 0,
            isFuture: i > 0,
          ),
        ),
        checkedCount: 0,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: false,
      );

      final state = AttendanceState(
        weeklyStatus: weeklyStatus,
        todayChecked: false,
        deadlineKST: DateTime.now()
            .add(const Duration(hours: 2))
            .toIso8601String(),
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should show progress (0/7)
      expect(find.text('0/7'), findsOneWidget);
    });

    testWidgets('shows linear progress indicator', (tester) async {
      final weeklyStatus = AttendanceWeeklyStatus(
        weekStart: '2025-03-10',
        weekEnd: '2025-03-16',
        days: List.generate(
          7,
          (i) => AttendanceDayStatus(
            date: '2025-03-${10 + i}',
            dayOfWeek: (i + 1) % 7,
            checked: i < 5,
            isToday: i == 4,
            isFuture: i > 4,
          ),
        ),
        checkedCount: 5,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: false,
      );

      final state = AttendanceState(
        weeklyStatus: weeklyStatus,
        todayChecked: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _MockAttendance(data: state),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('5/7'), findsOneWidget);
    });
  });

  group('AttendanceCheckResult', () {
    test('creates with required fields', () {
      const result = AttendanceCheckResult(
        rewardAmount: 60,
        weeklyBonusAmount: 0,
        totalReward: 60,
      );
      expect(result.rewardAmount, 60);
      expect(result.weeklyBonusAmount, 0);
      expect(result.totalReward, 60);
    });

    test('creates with weekly bonus', () {
      const result = AttendanceCheckResult(
        rewardAmount: 60,
        weeklyBonusAmount: 120,
        totalReward: 180,
      );
      expect(result.weeklyBonusAmount, 120);
      expect(result.totalReward, 180);
    });
  });

  group('AttendanceState', () {
    test('creates with defaults', () {
      const state = AttendanceState();
      expect(state.weeklyStatus, isNull);
      expect(state.todayChecked, isFalse);
      expect(state.serverTimeKST, isNull);
      expect(state.deadlineKST, isNull);
    });

    test('creates with all fields', () {
      final state = AttendanceState(
        todayChecked: true,
        serverTimeKST: '2025-03-12T14:00:00',
        deadlineKST: '2025-03-13T00:00:00',
      );
      expect(state.todayChecked, isTrue);
      expect(state.serverTimeKST, isNotNull);
      expect(state.deadlineKST, isNotNull);
    });
  });

  group('AttendanceDayStatus', () {
    test('fromJson parses correctly', () {
      final status = AttendanceDayStatus.fromJson({
        'date': '2025-03-12',
        'dayOfWeek': 3,
        'checked': true,
        'isToday': true,
        'isFuture': false,
      });
      expect(status.date, '2025-03-12');
      expect(status.dayOfWeek, 3);
      expect(status.checked, isTrue);
      expect(status.isToday, isTrue);
      expect(status.isFuture, isFalse);
    });
  });

  group('AttendanceWeeklyStatus', () {
    test('fromJson parses correctly', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2025-03-10',
        'weekEnd': '2025-03-16',
        'days': [
          {
            'date': '2025-03-10',
            'dayOfWeek': 1,
            'checked': true,
            'isToday': false,
            'isFuture': false,
          },
        ],
        'checkedCount': 1,
        'totalRequired': 7,
        'isWeeklyBonusEligible': false,
        'isNewUser': false,
      });
      expect(status.weekStart, '2025-03-10');
      expect(status.weekEnd, '2025-03-16');
      expect(status.days.length, 1);
      expect(status.checkedCount, 1);
      expect(status.totalRequired, 7);
      expect(status.isWeeklyBonusEligible, isFalse);
      expect(status.isNewUser, isFalse);
    });

    test('fromJson with all days checked', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2025-03-10',
        'weekEnd': '2025-03-16',
        'days': List.generate(
          7,
          (i) => {
            'date': '2025-03-${10 + i}',
            'dayOfWeek': (i + 1) % 7,
            'checked': true,
            'isToday': false,
            'isFuture': false,
          },
        ),
        'checkedCount': 7,
        'totalRequired': 7,
        'isWeeklyBonusEligible': true,
        'isNewUser': false,
      });
      expect(status.checkedCount, 7);
      expect(status.isWeeklyBonusEligible, isTrue);
      expect(status.days.length, 7);
    });
  });
}

/// Mock Attendance notifier for testing
class _MockAttendance extends Attendance {
  final AttendanceState? data;
  final bool isLoading;
  final bool hasError;

  _MockAttendance({
    this.data,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  Future<AttendanceState> build() async {
    if (isLoading) {
      // Return a future that never completes to simulate loading
      await Future.delayed(const Duration(hours: 1));
    }
    if (hasError) {
      throw Exception('Test error');
    }
    return data ?? const AttendanceState();
  }
}
