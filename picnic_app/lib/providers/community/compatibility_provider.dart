import 'dart:async';

import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/compatibility_provider.g.dart';

@Riverpod(keepAlive: true)
class Compatibility extends _$Compatibility {
  static const String _table = 'compatibility_results';
  static const _waitDuration = Duration(seconds: 30);
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  Timer? _displayTimer;
  Timer? _retryTimer;
  CompatibilityModel? _cachedResult;

  @override
  CompatibilityModel? build() {
    ref.onDispose(() {
      _displayTimer?.cancel();
      _retryTimer?.cancel();
      _cachedResult = null;
    });
    return null;
  }

  Future<CompatibilityModel> createCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. 먼저 레코드 생성
      final compatibilityData = {
        'user_id': userId,
        'artist_id': artist.id,
        'idol_birth_date': artist.birthDate?.toIso8601String(),
        'user_birth_date': birthDate.toIso8601String(),
        'user_birth_time': birthTime,
        'gender': gender,
        'status': 'pending',
      };

      final response = await supabase
          .from(_table)
          .insert(compatibilityData)
          .select('*, artist:artist(*)')
          .single();

      logger.i('Created compatibility record:$response');

      // 2. 레코드 생성 확인
      final compatibility =
          CompatibilityModel.fromJson({...response, 'artist': artist.toJson()});

      state = compatibility;

      // 3. 레코드가 실제로 생성되었는지 확인
      final verifyResponse = await supabase
          .from(_table)
          .select('id')
          .eq('id', compatibility.id)
          .single();

      logger.i('Verified compatibility record:$verifyResponse');

      // 4. Edge Function 호출 전 약간의 지연
      await Future.delayed(const Duration(milliseconds: 500));

      _processInBackground(compatibility);

      return compatibility;
    } catch (e) {
      logger.e('Failed to create compatibility', error: e);
      rethrow;
    }
  }

  void _processInBackground(CompatibilityModel initial) {
    _startCompatibilityAnalysis(initial.id);
    _startWaitTimer(initial);
  }

  Future<void> _startCompatibilityAnalysis(String compatibilityId) async {
    try {
      // 1. 레코드 존재 확인
      final checkResponse = await supabase
          .from(_table)
          .select('id, status')
          .eq('id', compatibilityId)
          .single();

      logger.i('Checking record before analysis:$checkResponse');

      // 2. Edge Function 호출
      final response = await supabase.functions.invoke(
        'compatibility',
        body: {'compatibility_id': compatibilityId},
        headers: {'Content-Type': 'application/json'},
      );

      logger.i('Edge function response:${response.data}');

      if (response.status != 200) {
        throw Exception('Edge function error: ${response.data}');
      }
    } catch (e) {
      logger.e('Edge function error, will retry', error: e);
      _retryAnalysis(compatibilityId);
    }
  }

  Future<void> _retryAnalysis(String compatibilityId) async {
    for (var i = 0; i < _maxRetries; i++) {
      try {
        await Future.delayed(_retryDelay);

        // 재시도 전 레코드 상태 확인
        final checkResponse = await supabase
            .from(_table)
            .select('id, status')
            .eq('id', compatibilityId)
            .single();

        logger.i('Retry $i - Current record status:$checkResponse');

        await _startCompatibilityAnalysis(compatibilityId);
        return;
      } catch (e) {
        logger.e('Retry $i failed', error: e);
        if (i == _maxRetries - 1) {
          await supabase.from(_table).update({
            'status': 'error',
            'error_message': 'Edge function failed after retries',
          }).eq('id', compatibilityId);
        }
      }
    }
  }

  void _startWaitTimer(CompatibilityModel initial) {
    _displayTimer?.cancel();
    _retryTimer?.cancel();
    _cachedResult = null;

    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final result = await getCompatibility(initial.id);
        if (result != null &&
            (result.isCompleted ||
                result.status == CompatibilityStatus.error)) {
          _cachedResult = result;
        }
      } catch (e) {
        logger.e('Failed to fetch early result', error: e);
      }
    });

    _displayTimer = Timer(_waitDuration, () async {
      try {
        if (_cachedResult != null) {
          state = _cachedResult;
        } else {
          final result = await getCompatibility(initial.id);
          if (result != null) {
            state = result;
          } else {
            _startErrorRetryTimer(initial);
          }
        }
      } catch (e) {
        logger.e('Failed to fetch final result', error: e);
        _startErrorRetryTimer(initial);
      }
    });
  }

  void _startErrorRetryTimer(CompatibilityModel initial) {
    _retryTimer?.cancel();

    state = initial.copyWith(
      status: CompatibilityStatus.error,
      errorMessage: '결과를 확인하는 중입니다. 잠시만 기다려주세요...',
    );

    _retryTimer = Timer(_retryDelay, refresh);
  }

  Future<CompatibilityModel?> getCompatibility(String id) async {
    try {
      final response = await supabase.from(_table).select('''
          *,
          artist:artist(*),
          i18n:compatibility_results_i18n(
            language,
            compatibility_score,
            compatibility_summary,
            details,
            tips
          )
        ''').eq('id', id).single();

      if (response['i18n'] == null || (response['i18n'] as List).isEmpty) {
        // i18n 데이터가 없으면 다시 시도
        await Future.delayed(const Duration(seconds: 1));
        return getCompatibility(id);
      }

      return CompatibilityModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Failed to get compatibility', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    if (state == null) return;

    try {
      final result = await getCompatibility(state!.id);
      if (result != null) {
        state = result;
      }
    } catch (e) {
      logger.e('Failed to refresh compatibility', error: e);
    }
  }
}
