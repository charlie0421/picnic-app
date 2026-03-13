import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';

void main() {
  group('AttendanceDayStatus', () {
    test('constructor sets all fields', () {
      const day = AttendanceDayStatus(
        date: '2026-03-11',
        dayOfWeek: 1,
        checked: true,
        isToday: false,
        isFuture: false,
      );
      expect(day.date, '2026-03-11');
      expect(day.dayOfWeek, 1);
      expect(day.checked, isTrue);
      expect(day.isToday, isFalse);
      expect(day.isFuture, isFalse);
    });

    test('fromJson parses correctly', () {
      final json = {
        'date': '2026-03-10',
        'dayOfWeek': 0,
        'checked': false,
        'isToday': true,
        'isFuture': false,
      };
      final day = AttendanceDayStatus.fromJson(json);
      expect(day.date, '2026-03-10');
      expect(day.dayOfWeek, 0);
      expect(day.checked, isFalse);
      expect(day.isToday, isTrue);
      expect(day.isFuture, isFalse);
    });
  });

  group('AttendanceWeeklyStatus', () {
    test('constructor sets all fields', () {
      const status = AttendanceWeeklyStatus(
        weekStart: '2026-03-09',
        weekEnd: '2026-03-15',
        days: [],
        checkedCount: 3,
        totalRequired: 7,
        isWeeklyBonusEligible: false,
        isNewUser: false,
      );
      expect(status.weekStart, '2026-03-09');
      expect(status.weekEnd, '2026-03-15');
      expect(status.days, isEmpty);
      expect(status.checkedCount, 3);
      expect(status.totalRequired, 7);
      expect(status.isWeeklyBonusEligible, isFalse);
      expect(status.isNewUser, isFalse);
    });

    test('fromJson parses with days', () {
      final json = {
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [
          {
            'date': '2026-03-09',
            'dayOfWeek': 0,
            'checked': true,
            'isToday': false,
            'isFuture': false,
          },
          {
            'date': '2026-03-10',
            'dayOfWeek': 1,
            'checked': false,
            'isToday': true,
            'isFuture': false,
          },
        ],
        'checkedCount': 1,
        'totalRequired': 7,
        'isWeeklyBonusEligible': false,
        'isNewUser': true,
      };
      final status = AttendanceWeeklyStatus.fromJson(json);
      expect(status.days.length, 2);
      expect(status.days[0].checked, isTrue);
      expect(status.days[1].isToday, isTrue);
      expect(status.isNewUser, isTrue);
    });
  });

  group('AttendanceState', () {
    test('default values', () {
      const state = AttendanceState();
      expect(state.weeklyStatus, isNull);
      expect(state.todayChecked, isFalse);
      expect(state.serverTimeKST, isNull);
      expect(state.deadlineKST, isNull);
    });

    test('constructor with all values', () {
      const state = AttendanceState(
        weeklyStatus: AttendanceWeeklyStatus(
          weekStart: '2026-03-09',
          weekEnd: '2026-03-15',
          days: [],
          checkedCount: 5,
          totalRequired: 7,
          isWeeklyBonusEligible: true,
          isNewUser: false,
        ),
        todayChecked: true,
        serverTimeKST: '2026-03-11 14:30:00',
        deadlineKST: '2026-03-12 00:00:00',
      );
      expect(state.weeklyStatus, isNotNull);
      expect(state.todayChecked, isTrue);
      expect(state.serverTimeKST, '2026-03-11 14:30:00');
      expect(state.deadlineKST, '2026-03-12 00:00:00');
    });
  });

  group('AttendanceCheckResult', () {
    test('constructor sets all fields', () {
      const result = AttendanceCheckResult(
        rewardAmount: 60,
        weeklyBonusAmount: 120,
        totalReward: 180,
      );
      expect(result.rewardAmount, 60);
      expect(result.weeklyBonusAmount, 120);
      expect(result.totalReward, 180);
    });

    test('zero values', () {
      const result = AttendanceCheckResult(
        rewardAmount: 0,
        weeklyBonusAmount: 0,
        totalReward: 0,
      );
      expect(result.rewardAmount, 0);
      expect(result.weeklyBonusAmount, 0);
      expect(result.totalReward, 0);
    });
  });
}
