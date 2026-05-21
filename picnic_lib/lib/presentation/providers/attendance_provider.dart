import 'dart:convert';

import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:picnic_lib/presentation/providers/attendance_models.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:picnic_lib/presentation/providers/attendance_models.dart';

part '../../generated/providers/attendance_provider.g.dart';

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
      final data = await _invokeAndParse(
        method: HttpMethod.get,
        action: 'fetchStatus',
        fallbackMessage: 'Failed to fetch',
        isRetry: isRetry,
      );

      return AttendanceState(
        weeklyStatus: AttendanceWeeklyStatus.fromJson(
          data['weeklyStatus'] as Map<String, dynamic>,
        ),
        todayChecked: data['todayChecked'] as bool,
        serverTimeKST: data['serverTimeKST'] as String?,
        deadlineKST: data['deadlineKST'] as String?,
      );
    } on FunctionException catch (e, s) {
      final aa = mapToAntiAbuseException(e);
      if (aa is AntiAbuseException) {
        logger.w('attendance-check rate-limited: channel=${aa.channel}');
        throw aa;
      }
      logger.e('FunctionException fetching attendance', error: e, stackTrace: s);
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
      if (!isRetry) return _retryWithSessionRefresh();
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
      if (!isRetry && _isAuthError(e)) return _retryWithSessionRefresh();
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

  Future<AttendanceCheckResult?> checkIn({bool isRetry = false}) async {
    try {
      final data = await _invokeAndParse(
        body: {},
        action: 'checkIn',
        fallbackMessage: 'Check-in failed',
        isRetry: isRetry,
        onAlreadyChecked: () {
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
        },
      );

      if (data.isEmpty) return null; // ALREADY_CHECKED case

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
      final aa = mapToAntiAbuseException(e);
      if (aa is AntiAbuseException) {
        logger.w('attendance check-in rate-limited: channel=${aa.channel}');
        throw aa;
      }
      logger.e('FunctionException during check-in', error: e, stackTrace: s);
      if (!isRetry && (e.status == 401 || e.status == 403)) {
        if (await _tryRefreshSession('checkIn')) {
          return checkIn(isRetry: true);
        }
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
        if (await _tryRefreshSession('checkIn')) {
          return checkIn(isRetry: true);
        }
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

  // ── Private helpers ──────────────────────────────────────

  /// Edge Function 호출 → 응답 파싱 → data 반환
  /// [onAlreadyChecked]가 있으면 ALREADY_CHECKED 시 호출 후 빈 맵 반환
  Future<Map<String, dynamic>> _invokeAndParse({
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? body,
    required String action,
    required String fallbackMessage,
    required bool isRetry,
    void Function()? onAlreadyChecked,
  }) async {
    // Attach X-Device-Id header for anti-abuse device-cohort signal.
    // Graceful: if retrieval fails the request proceeds without the header.
    Map<String, String>? extraHeaders;
    try {
      final deviceId = await DeviceManager.getDeviceId();
      extraHeaders = {'X-Device-Id': deviceId};
    } catch (e) {
      logger.w('Could not retrieve device ID for attendance-check header: $e');
    }

    final response = await supabase.functions.invoke(
      'attendance-check',
      method: method,
      body: body,
      headers: extraHeaders,
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
      if (code == 'ALREADY_CHECKED' && onAlreadyChecked != null) {
        onAlreadyChecked();
        return const {};
      }
      final message = errorMap is Map ? errorMap['message'] : fallbackMessage;
      throw AttendanceException(
        message?.toString() ?? fallbackMessage,
        AttendanceErrorType.server,
      );
    }

    return parsed['data'] as Map<String, dynamic>;
  }

  /// 세션을 갱신한 후 _fetchStatus를 1회 재시도
  Future<AttendanceState> _retryWithSessionRefresh() async {
    if (!await _tryRefreshSession('fetchStatus')) {
      throw const AttendanceException(
        'Session expired',
        AttendanceErrorType.auth,
      );
    }
    return _fetchStatus(isRetry: true);
  }

  /// 세션 갱신 시도. 성공 시 true, 실패 시 false.
  Future<bool> _tryRefreshSession(String action) async {
    try {
      logger.d('Attempting session refresh for attendance ($action)');
      await supabase.auth.refreshSession();
      return true;
    } catch (e) {
      logger.e('Session refresh failed', error: e);
      Sentry.captureException(e, stackTrace: StackTrace.current, withScope: (scope) {
        scope.setTag('feature', 'attendance');
        scope.setTag('action', 'sessionRefresh:$action');
      });
      return false;
    }
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
}
