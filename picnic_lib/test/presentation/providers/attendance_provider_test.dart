import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('Attendance provider', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'functions:attendance-check': {
          'success': true,
          'data': {
            'weeklyStatus': {
              'weekStart': '2026-03-09',
              'weekEnd': '2026-03-15',
              'days': [],
              'checkedCount': 2,
              'totalRequired': 7,
              'isWeeklyBonusEligible': false,
              'isNewUser': false,
            },
            'todayChecked': false,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'deadlineKST': '2026-03-12T00:00:00+09:00',
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns default state when not authenticated (currentUser is null)', () async {
      // isSupabaseLoggedSafely returns false in test since
      // mock HTTP doesn't set auth.currentUser local state
      final result = await container.read(attendanceProvider.future);
      expect(result, isA<AttendanceState>());
      expect(result.weeklyStatus, isNull);
      expect(result.todayChecked, false);
    });
  });

  group('Attendance provider without auth', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns empty state when not logged in', () async {
      final result = await container.read(attendanceProvider.future);
      expect(result.weeklyStatus, isNull);
      expect(result.todayChecked, false);
      expect(result.serverTimeKST, isNull);
      expect(result.deadlineKST, isNull);
    });
  });

  group('AttendanceCheckResult', () {
    test('stores reward amounts', () {
      const result = AttendanceCheckResult(
        rewardAmount: 10,
        weeklyBonusAmount: 50,
        totalReward: 60,
      );
      expect(result.rewardAmount, 10);
      expect(result.weeklyBonusAmount, 50);
      expect(result.totalReward, 60);
    });

    test('zero rewards', () {
      const result = AttendanceCheckResult(
        rewardAmount: 0,
        weeklyBonusAmount: 0,
        totalReward: 0,
      );
      expect(result.rewardAmount, 0);
      expect(result.totalReward, 0);
    });

    test('large rewards', () {
      const result = AttendanceCheckResult(
        rewardAmount: 100,
        weeklyBonusAmount: 500,
        totalReward: 600,
      );
      expect(result.totalReward, 600);
    });
  });

  group('AttendanceState', () {
    test('default values', () {
      const state = AttendanceState();
      expect(state.weeklyStatus, isNull);
      expect(state.todayChecked, false);
      expect(state.serverTimeKST, isNull);
      expect(state.deadlineKST, isNull);
    });

    test('with all parameters', () {
      final state = AttendanceState(
        weeklyStatus: AttendanceWeeklyStatus(
          weekStart: '2026-03-09',
          weekEnd: '2026-03-15',
          days: [],
          checkedCount: 3,
          totalRequired: 7,
          isWeeklyBonusEligible: false,
          isNewUser: true,
        ),
        todayChecked: true,
        serverTimeKST: '2026-03-11T15:00:00+09:00',
        deadlineKST: '2026-03-12T00:00:00+09:00',
      );
      expect(state.todayChecked, true);
      expect(state.weeklyStatus!.isNewUser, true);
      expect(state.weeklyStatus!.checkedCount, 3);
    });

    test('todayChecked true', () {
      const state = AttendanceState(todayChecked: true);
      expect(state.todayChecked, true);
    });
  });

  group('AttendanceWeeklyStatus', () {
    test('fromJson with all fields', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [
          {
            'date': '2026-03-09',
            'dayOfWeek': 1,
            'checked': true,
            'isToday': false,
            'isFuture': false,
          },
          {
            'date': '2026-03-10',
            'dayOfWeek': 2,
            'checked': false,
            'isToday': true,
            'isFuture': false,
          },
        ],
        'checkedCount': 1,
        'totalRequired': 7,
        'isWeeklyBonusEligible': false,
        'isNewUser': false,
      });

      expect(status.weekStart, '2026-03-09');
      expect(status.weekEnd, '2026-03-15');
      expect(status.days.length, 2);
      expect(status.checkedCount, 1);
      expect(status.totalRequired, 7);
      expect(status.isWeeklyBonusEligible, false);
      expect(status.isNewUser, false);
    });

    test('fromJson with weekly bonus eligible', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [],
        'checkedCount': 7,
        'totalRequired': 7,
        'isWeeklyBonusEligible': true,
        'isNewUser': false,
      });

      expect(status.isWeeklyBonusEligible, true);
      expect(status.checkedCount, 7);
    });

    test('fromJson with new user', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [],
        'checkedCount': 0,
        'totalRequired': 7,
        'isWeeklyBonusEligible': false,
        'isNewUser': true,
      });

      expect(status.isNewUser, true);
      expect(status.checkedCount, 0);
    });

    test('fromJson with empty days', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [],
        'checkedCount': 0,
        'totalRequired': 7,
        'isWeeklyBonusEligible': false,
        'isNewUser': false,
      });

      expect(status.days, isEmpty);
    });
  });

  group('AttendanceDayStatus', () {
    test('fromJson creates correct object', () {
      final day = AttendanceDayStatus.fromJson({
        'date': '2026-03-11',
        'dayOfWeek': 3,
        'checked': true,
        'isToday': true,
        'isFuture': false,
      });

      expect(day.date, '2026-03-11');
      expect(day.dayOfWeek, 3);
      expect(day.checked, true);
      expect(day.isToday, true);
      expect(day.isFuture, false);
    });

    test('fromJson for future day', () {
      final day = AttendanceDayStatus.fromJson({
        'date': '2026-03-14',
        'dayOfWeek': 6,
        'checked': false,
        'isToday': false,
        'isFuture': true,
      });

      expect(day.isFuture, true);
      expect(day.checked, false);
    });

    test('fromJson for past unchecked day', () {
      final day = AttendanceDayStatus.fromJson({
        'date': '2026-03-09',
        'dayOfWeek': 1,
        'checked': false,
        'isToday': false,
        'isFuture': false,
      });

      expect(day.checked, false);
      expect(day.isFuture, false);
      expect(day.isToday, false);
    });

    test('all day of week values', () {
      for (var i = 1; i <= 7; i++) {
        final day = AttendanceDayStatus.fromJson({
          'date': '2026-03-0$i',
          'dayOfWeek': i,
          'checked': false,
          'isToday': false,
          'isFuture': false,
        });
        expect(day.dayOfWeek, i);
      }
    });
  });
}
