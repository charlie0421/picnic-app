import 'dart:convert';

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/attendance_provider.g.dart';

/// 출석체크 에러 유형
enum AttendanceErrorType {
  auth,
  network,
  server,
  unknown,
}

class AttendanceException implements Exception {
  final String message;
  final AttendanceErrorType type;

  const AttendanceException(this.message, this.type);

  @override
  String toString() => 'AttendanceException($type): $message';
}

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

  Future<AttendanceState> _fetchStatus({bool isRetry = false}) async {
    try {
      final response = await supabase.functions.invoke(
        'attendance-check',
        method: HttpMethod.get,
      );

      final raw = response.data;
      if (raw == null) {
        throw const AttendanceException(
          'Empty response from server',
          AttendanceErrorType.server,
        );
      }

      final parsed = raw is String ? jsonDecode(raw) : raw;
      if (parsed is! Map<String, dynamic>) {
        throw const AttendanceException(
          'Invalid response format',
          AttendanceErrorType.server,
        );
      }

      if (parsed['success'] != true) {
        final errorMap = parsed['error'];
        final message = errorMap is Map ? errorMap['message'] : 'Failed to fetch';
        throw AttendanceException(
          message?.toString() ?? 'Failed to fetch',
          AttendanceErrorType.server,
        );
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
    } on FunctionException catch (e, s) {
      logger.e('FunctionException fetching attendance', error: e, stackTrace: s);
      // 401/403 → 세션 만료 가능성 → 세션 갱신 후 1회 재시도
      if (!isRetry && (e.status == 401 || e.status == 403)) {
        return _retryWithSessionRefresh();
      }
      _reportToSentry('fetchStatus:FunctionException', e, s, {
        'status': e.status,
        'reasonPhrase': e.reasonPhrase,
        'isRetry': isRetry,
      });
      throw AttendanceException(
        e.reasonPhrase ?? 'Server error',
        e.status == 401 || e.status == 403
            ? AttendanceErrorType.auth
            : AttendanceErrorType.server,
      );
    } on AuthException catch (e, s) {
      logger.e('AuthException fetching attendance', error: e, stackTrace: s);
      if (!isRetry) {
        return _retryWithSessionRefresh();
      }
      _reportToSentry('fetchStatus:AuthException', e, s, {
        'message': e.message,
        'isRetry': isRetry,
      });
      throw AttendanceException(e.message, AttendanceErrorType.auth);
    } on AttendanceException catch (e, s) {
      _reportToSentry('fetchStatus:AttendanceException', e, s, {
        'type': e.type.name,
        'isRetry': isRetry,
      });
      rethrow;
    } catch (e, s) {
      logger.e('Error fetching attendance status', error: e, stackTrace: s);
      if (!isRetry && _isAuthError(e)) {
        return _retryWithSessionRefresh();
      }
      _reportToSentry('fetchStatus:Unknown', e, s, {
        'errorType': e.runtimeType.toString(),
        'isRetry': isRetry,
      });
      throw AttendanceException(
        e.toString(),
        _isNetworkError(e) ? AttendanceErrorType.network : AttendanceErrorType.unknown,
      );
    }
  }

  /// 세션을 갱신한 후 _fetchStatus를 1회 재시도
  Future<AttendanceState> _retryWithSessionRefresh() async {
    try {
      logger.d('Attempting session refresh for attendance');
      await supabase.auth.refreshSession();
    } catch (e) {
      logger.e('Session refresh failed', error: e);
      Sentry.captureException(e, stackTrace: StackTrace.current, withScope: (scope) {
        scope.setTag('feature', 'attendance');
        scope.setTag('action', 'sessionRefresh');
      });
      throw const AttendanceException(
        'Session expired',
        AttendanceErrorType.auth,
      );
    }
    return _fetchStatus(isRetry: true);
  }

  void _reportToSentry(
    String action,
    Object error,
    StackTrace stackTrace,
    Map<String, dynamic> extra,
  ) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('feature', 'attendance');
        scope.setTag('action', action);
        for (final entry in extra.entries) {
          scope.setTag('attendance.${entry.key}', entry.value.toString());
        }
      },
    );
  }

  bool _isAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('auth') ||
        msg.contains('token') ||
        msg.contains('unauthorized') ||
        msg.contains('jwt') ||
        msg.contains('session');
  }

  bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('network') ||
        msg.contains('connection');
  }

  Future<AttendanceCheckResult?> checkIn({bool isRetry = false}) async {
    try {
      final response = await supabase.functions.invoke(
        'attendance-check',
        body: {},
      );

      final raw = response.data;
      if (raw == null) {
        throw const AttendanceException(
          'Empty response from server',
          AttendanceErrorType.server,
        );
      }

      final parsed = raw is String ? jsonDecode(raw) : raw;
      if (parsed is! Map<String, dynamic>) {
        throw const AttendanceException(
          'Invalid response format',
          AttendanceErrorType.server,
        );
      }

      if (parsed['success'] != true) {
        final errorMap = parsed['error'];
        final code = errorMap is Map ? errorMap['code'] : null;
        if (code == 'ALREADY_CHECKED') {
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
        final message = errorMap is Map ? errorMap['message'] : 'Check-in failed';
        throw AttendanceException(
          message?.toString() ?? 'Check-in failed',
          AttendanceErrorType.server,
        );
      }

      final data = parsed['data'] as Map<String, dynamic>;

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
    } on FunctionException catch (e, s) {
      logger.e('FunctionException during check-in', error: e, stackTrace: s);
      if (!isRetry && (e.status == 401 || e.status == 403)) {
        try {
          await supabase.auth.refreshSession();
          return checkIn(isRetry: true);
        } catch (_) {}
      }
      _reportToSentry('checkIn:FunctionException', e, s, {
        'status': e.status,
        'reasonPhrase': e.reasonPhrase,
        'isRetry': isRetry,
      });
      throw AttendanceException(
        e.reasonPhrase ?? 'Check-in failed',
        e.status == 401 || e.status == 403
            ? AttendanceErrorType.auth
            : AttendanceErrorType.server,
      );
    } on AuthException catch (e, s) {
      logger.e('AuthException during check-in', error: e, stackTrace: s);
      if (!isRetry) {
        try {
          await supabase.auth.refreshSession();
          return checkIn(isRetry: true);
        } catch (_) {}
      }
      _reportToSentry('checkIn:AuthException', e, s, {
        'message': e.message,
        'isRetry': isRetry,
      });
      throw AttendanceException(e.message, AttendanceErrorType.auth);
    } on AttendanceException catch (e, s) {
      _reportToSentry('checkIn:AttendanceException', e, s, {
        'type': e.type.name,
        'isRetry': isRetry,
      });
      rethrow;
    } catch (e, s) {
      logger.e('Error checking in', error: e, stackTrace: s);
      _reportToSentry('checkIn:Unknown', e, s, {
        'errorType': e.runtimeType.toString(),
        'isRetry': isRetry,
      });
      throw AttendanceException(
        e.toString(),
        _isNetworkError(e) ? AttendanceErrorType.network : AttendanceErrorType.unknown,
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _fetchStatus());
  }
}
