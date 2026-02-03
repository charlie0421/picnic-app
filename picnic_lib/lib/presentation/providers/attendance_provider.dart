import 'dart:convert';

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/attendance_provider.g.dart';

class AttendanceDayStatus {
  final String date;
  final int dayOfWeek;
  final bool checked;
  final bool isToday;
  final bool isFuture;

  const AttendanceDayStatus({
    required this.date,
    required this.dayOfWeek,
    required this.checked,
    required this.isToday,
    required this.isFuture,
  });

  factory AttendanceDayStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceDayStatus(
      date: json['date'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      checked: json['checked'] as bool,
      isToday: json['isToday'] as bool,
      isFuture: json['isFuture'] as bool,
    );
  }
}

class AttendanceWeeklyStatus {
  final String weekStart;
  final String weekEnd;
  final List<AttendanceDayStatus> days;
  final int checkedCount;
  final int totalRequired;
  final bool isWeeklyBonusEligible;
  final bool isNewUser;

  const AttendanceWeeklyStatus({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.checkedCount,
    required this.totalRequired,
    required this.isWeeklyBonusEligible,
    required this.isNewUser,
  });

  factory AttendanceWeeklyStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceWeeklyStatus(
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      days: (json['days'] as List)
          .map((e) => AttendanceDayStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkedCount: json['checkedCount'] as int,
      totalRequired: json['totalRequired'] as int,
      isWeeklyBonusEligible: json['isWeeklyBonusEligible'] as bool,
      isNewUser: json['isNewUser'] as bool,
    );
  }
}

class AttendanceState {
  final AttendanceWeeklyStatus? weeklyStatus;
  final bool todayChecked;
  final String? serverTimeKST;
  final String? deadlineKST;

  const AttendanceState({
    this.weeklyStatus,
    this.todayChecked = false,
    this.serverTimeKST,
    this.deadlineKST,
  });
}

class AttendanceCheckResult {
  final int rewardAmount;
  final int weeklyBonusAmount;
  final int totalReward;

  const AttendanceCheckResult({
    required this.rewardAmount,
    required this.weeklyBonusAmount,
    required this.totalReward,
  });
}

@riverpod
class Attendance extends _$Attendance {
  @override
  Future<AttendanceState> build() async {
    if (!isSupabaseLoggedSafely) {
      return const AttendanceState();
    }
    return await _fetchStatus();
  }

  Future<AttendanceState> _fetchStatus() async {
    try {
      final response = await supabase.functions.invoke(
        'attendance-check',
        method: HttpMethod.get,
      );

      final raw = response.data;
      final parsed = raw is String ? jsonDecode(raw) : raw;

      if (parsed['success'] != true) {
        throw Exception(parsed['error']?['message'] ?? 'Failed to fetch');
      }

      final data = parsed['data'] as Map<String, dynamic>;
      return AttendanceState(
        weeklyStatus: AttendanceWeeklyStatus.fromJson(
          data['weeklyStatus'] as Map<String, dynamic>,
        ),
        todayChecked: data['todayChecked'] as bool,
        serverTimeKST: data['serverTimeKST'] as String?,
        deadlineKST: data['deadlineKST'] as String?,
      );
    } catch (e, s) {
      logger.e('Error fetching attendance status', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<AttendanceCheckResult?> checkIn() async {
    try {
      final response = await supabase.functions.invoke(
        'attendance-check',
        body: {},
      );

      final raw = response.data;
      final parsed = raw is String ? jsonDecode(raw) : raw;

      if (parsed['success'] != true) {
        final code = parsed['error']?['code'];
        if (code == 'ALREADY_CHECKED') {
          // Update state to reflect checked status
          final current = state.value;
          if (current != null) {
            state = AsyncValue.data(
              AttendanceState(
                weeklyStatus: current.weeklyStatus,
                todayChecked: true,
                serverTimeKST: current.serverTimeKST,
                deadlineKST: current.deadlineKST,
              ),
            );
          }
          return null;
        }
        throw Exception(parsed['error']?['message'] ?? 'Check-in failed');
      }

      final data = parsed['data'] as Map<String, dynamic>;

      // Update state
      state = AsyncValue.data(
        AttendanceState(
          weeklyStatus: AttendanceWeeklyStatus.fromJson(
            data['weeklyStatus'] as Map<String, dynamic>,
          ),
          todayChecked: true,
          serverTimeKST: data['serverTimeKST'] as String?,
          deadlineKST: state.value?.deadlineKST,
        ),
      );

      return AttendanceCheckResult(
        rewardAmount: data['rewardAmount'] as int,
        weeklyBonusAmount: data['weeklyBonusAmount'] as int,
        totalReward: data['totalReward'] as int,
      );
    } catch (e, s) {
      logger.e('Error checking in', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _fetchStatus());
  }
}
