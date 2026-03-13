import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  final weeklyStatusJson = {
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
        'checked': true,
        'isToday': false,
        'isFuture': false,
      },
      {
        'date': '2026-03-11',
        'dayOfWeek': 3,
        'checked': false,
        'isToday': true,
        'isFuture': false,
      },
      {
        'date': '2026-03-12',
        'dayOfWeek': 4,
        'checked': false,
        'isToday': false,
        'isFuture': true,
      },
      {
        'date': '2026-03-13',
        'dayOfWeek': 5,
        'checked': false,
        'isToday': false,
        'isFuture': true,
      },
      {
        'date': '2026-03-14',
        'dayOfWeek': 6,
        'checked': false,
        'isToday': false,
        'isFuture': true,
      },
      {
        'date': '2026-03-15',
        'dayOfWeek': 7,
        'checked': false,
        'isToday': false,
        'isFuture': true,
      },
    ],
    'checkedCount': 2,
    'totalRequired': 7,
    'isWeeklyBonusEligible': false,
    'isNewUser': false,
  };

  final updatedWeeklyStatusJson = {
    ...weeklyStatusJson,
    'checkedCount': 3,
    'days': [
      ...((weeklyStatusJson['days'] as List).sublist(0, 2)),
      {
        'date': '2026-03-11',
        'dayOfWeek': 3,
        'checked': true,
        'isToday': true,
        'isFuture': false,
      },
      ...((weeklyStatusJson['days'] as List).sublist(3)),
    ],
  };

  group('Attendance provider - authenticated - build (fetchStatus)', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
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

    test('fetches attendance status when authenticated', () async {
      // Keep provider alive with listen
      container.listen(attendanceProvider, (_, __) {});
      final result = await container.read(attendanceProvider.future);

      expect(result, isA<AttendanceState>());
      expect(result.weeklyStatus, isNotNull);
      expect(result.weeklyStatus!.weekStart, '2026-03-09');
      expect(result.weeklyStatus!.weekEnd, '2026-03-15');
      expect(result.weeklyStatus!.checkedCount, 2);
      expect(result.weeklyStatus!.totalRequired, 7);
      expect(result.weeklyStatus!.isWeeklyBonusEligible, false);
      expect(result.weeklyStatus!.isNewUser, false);
      expect(result.todayChecked, false);
      expect(result.serverTimeKST, '2026-03-11T15:00:00+09:00');
      expect(result.deadlineKST, '2026-03-12T00:00:00+09:00');
    });

    test('fetches weekly status with 7 days', () async {
      container.listen(attendanceProvider, (_, __) {});
      final result = await container.read(attendanceProvider.future);
      expect(result.weeklyStatus!.days.length, 7);
    });

    test('days include past checked, today unchecked, and future days', () async {
      container.listen(attendanceProvider, (_, __) {});
      final result = await container.read(attendanceProvider.future);
      final days = result.weeklyStatus!.days;

      expect(days[0].checked, true);
      expect(days[0].isFuture, false);
      expect(days[0].isToday, false);
      expect(days[1].checked, true);
      expect(days[2].isToday, true);
      expect(days[2].checked, false);
      expect(days[3].isFuture, true);
      expect(days[3].checked, false);
    });

    test('provider is in AsyncData state after fetch', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);
      final state = container.read(attendanceProvider);
      expect(state, isA<AsyncData<AttendanceState>>());
      expect(state.hasValue, true);
      expect(state.hasError, false);
    });
  });

  group('Attendance provider - authenticated - fetchStatus todayChecked true', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': true,
            'serverTimeKST': '2026-03-11T18:00:00+09:00',
            'deadlineKST': null,
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('handles todayChecked true from server', () async {
      container.listen(attendanceProvider, (_, __) {});
      final result = await container.read(attendanceProvider.future);
      expect(result.todayChecked, true);
    });

    test('handles null deadlineKST', () async {
      container.listen(attendanceProvider, (_, __) {});
      final result = await container.read(attendanceProvider.future);
      expect(result.deadlineKST, isNull);
    });
  });

  group('Attendance provider - authenticated - fetchStatus error', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': false,
          'error': {
            'message': 'Server error',
            'code': 'INTERNAL_ERROR',
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('results in AsyncError state when server returns success: false', () async {
      container.listen(attendanceProvider, (_, __) {});
      // Trigger the provider
      container.read(attendanceProvider);
      // Wait for the async operation to complete
      await Future.delayed(const Duration(seconds: 2));
      final state = container.read(attendanceProvider);
      expect(state.hasError, true);
    });
  });

  group('Attendance provider - authenticated - fetchStatus error without message', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': false,
          'error': {},
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('results in error state when error has no message', () async {
      container.listen(attendanceProvider, (_, __) {});
      container.read(attendanceProvider);
      await Future.delayed(const Duration(seconds: 2));
      final state = container.read(attendanceProvider);
      expect(state.hasError, true);
      expect(state.error.toString(), contains('Failed to fetch'));
    });
  });

  group('Attendance provider - authenticated - checkIn success', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': false,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'deadlineKST': '2026-03-12T00:00:00+09:00',
          },
        },
        'functions:attendance-check:POST': {
          'success': true,
          'data': {
            'weeklyStatus': updatedWeeklyStatusJson,
            'todayChecked': true,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'rewardAmount': 60,
            'weeklyBonusAmount': 0,
            'totalReward': 60,
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkIn returns AttendanceCheckResult on success', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      final result = await notifier.checkIn();

      expect(result, isNotNull);
      expect(result, isA<AttendanceCheckResult>());
      expect(result!.rewardAmount, 60);
      expect(result.weeklyBonusAmount, 0);
      expect(result.totalReward, 60);
    });

    test('checkIn updates state to todayChecked true', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.checkIn();

      final state = container.read(attendanceProvider);
      expect(state.value!.todayChecked, true);
    });

    test('checkIn updates weeklyStatus checkedCount', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.checkIn();

      final state = container.read(attendanceProvider);
      expect(state.value!.weeklyStatus!.checkedCount, 3);
    });

    test('checkIn preserves deadlineKST from previous state', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.checkIn();

      final state = container.read(attendanceProvider);
      expect(state.value!.deadlineKST, '2026-03-12T00:00:00+09:00');
    });
  });

  group('Attendance provider - authenticated - checkIn with weekly bonus', () {
    late ProviderContainer container;

    setUp(() async {
      final bonusWeeklyStatus = {
        ...weeklyStatusJson,
        'checkedCount': 7,
        'isWeeklyBonusEligible': true,
      };
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': false,
            'serverTimeKST': '2026-03-15T15:00:00+09:00',
            'deadlineKST': '2026-03-16T00:00:00+09:00',
          },
        },
        'functions:attendance-check:POST': {
          'success': true,
          'data': {
            'weeklyStatus': bonusWeeklyStatus,
            'todayChecked': true,
            'serverTimeKST': '2026-03-15T15:00:00+09:00',
            'rewardAmount': 60,
            'weeklyBonusAmount': 120,
            'totalReward': 180,
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkIn returns weekly bonus when eligible', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      final result = await notifier.checkIn();

      expect(result, isNotNull);
      expect(result!.rewardAmount, 60);
      expect(result.weeklyBonusAmount, 120);
      expect(result.totalReward, 180);
    });
  });

  group('Attendance provider - authenticated - checkIn ALREADY_CHECKED', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': false,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'deadlineKST': '2026-03-12T00:00:00+09:00',
          },
        },
        'functions:attendance-check:POST': {
          'success': false,
          'error': {
            'code': 'ALREADY_CHECKED',
            'message': 'Already checked in today',
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkIn returns null for ALREADY_CHECKED', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      final result = await notifier.checkIn();
      expect(result, isNull);
    });

    test('checkIn updates state to todayChecked true for ALREADY_CHECKED', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.checkIn();

      final state = container.read(attendanceProvider);
      expect(state.value!.todayChecked, true);
    });

    test('checkIn preserves weeklyStatus for ALREADY_CHECKED', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.checkIn();

      final state = container.read(attendanceProvider);
      expect(state.value!.weeklyStatus, isNotNull);
      expect(state.value!.weeklyStatus!.checkedCount, 2);
    });
  });

  group('Attendance provider - authenticated - checkIn error', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': false,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'deadlineKST': '2026-03-12T00:00:00+09:00',
          },
        },
        'functions:attendance-check:POST': {
          'success': false,
          'error': {
            'code': 'RATE_LIMITED',
            'message': 'Too many requests',
          },
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkIn throws for non-ALREADY_CHECKED errors', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      expect(
        () => notifier.checkIn(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Too many requests'),
        )),
      );
    });
  });

  group('Attendance provider - authenticated - checkIn error without message', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
            'todayChecked': false,
            'serverTimeKST': '2026-03-11T15:00:00+09:00',
            'deadlineKST': '2026-03-12T00:00:00+09:00',
          },
        },
        'functions:attendance-check:POST': {
          'success': false,
          'error': {'code': 'UNKNOWN'},
        },
      }, userId: 'test-user-id');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('checkIn throws with fallback message when no error message', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      expect(
        () => notifier.checkIn(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Check-in failed'),
        )),
      );
    });
  });

  group('Attendance provider - authenticated - refresh', () {
    late ProviderContainer container;

    setUp(() async {
      await setupMockSupabaseWithAuth({
        'functions:attendance-check:GET': {
          'success': true,
          'data': {
            'weeklyStatus': weeklyStatusJson,
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

    test('refresh reloads status successfully', () async {
      container.listen(attendanceProvider, (_, __) {});
      await container.read(attendanceProvider.future);

      final notifier = container.read(attendanceProvider.notifier);
      await notifier.refresh();

      final state = container.read(attendanceProvider);
      expect(state, isA<AsyncData<AttendanceState>>());
      expect(state.value!.weeklyStatus, isNotNull);
      expect(state.value!.weeklyStatus!.checkedCount, 2);
    });
  });

  group('Attendance provider - not authenticated', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('returns default state when not authenticated', () async {
      final result = await container.read(attendanceProvider.future);
      expect(result.weeklyStatus, isNull);
      expect(result.todayChecked, false);
      expect(result.serverTimeKST, isNull);
      expect(result.deadlineKST, isNull);
    });
  });

  group('AttendanceDayStatus - additional coverage', () {
    test('fromJson with all boolean combinations', () {
      final checkedToday = AttendanceDayStatus.fromJson({
        'date': '2026-03-11',
        'dayOfWeek': 3,
        'checked': true,
        'isToday': true,
        'isFuture': false,
      });
      expect(checkedToday.checked, true);
      expect(checkedToday.isToday, true);
      expect(checkedToday.isFuture, false);
    });
  });

  group('AttendanceWeeklyStatus - additional coverage', () {
    test('fromJson with weekly bonus eligible and new user', () {
      final status = AttendanceWeeklyStatus.fromJson({
        'weekStart': '2026-03-09',
        'weekEnd': '2026-03-15',
        'days': [],
        'checkedCount': 7,
        'totalRequired': 7,
        'isWeeklyBonusEligible': true,
        'isNewUser': true,
      });
      expect(status.isWeeklyBonusEligible, true);
      expect(status.isNewUser, true);
    });
  });

  group('AttendanceCheckResult - additional coverage', () {
    test('large reward values', () {
      const result = AttendanceCheckResult(
        rewardAmount: 1000,
        weeklyBonusAmount: 5000,
        totalReward: 6000,
      );
      expect(result.rewardAmount, 1000);
      expect(result.weeklyBonusAmount, 5000);
      expect(result.totalReward, 6000);
    });
  });
}
