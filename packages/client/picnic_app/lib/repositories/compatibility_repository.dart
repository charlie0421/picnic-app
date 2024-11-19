import 'dart:convert';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompatibilityRepository {
  Future<CompatibilityModel> createCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final Map<String, dynamic> compatibilityData = {
        'user_id': userId,
        'artist_id': artist.id,
        'idol_birth_date': artist.birthDate?.toIso8601String(),
        'user_birth_date': birthDate.toIso8601String(),
        'user_birth_time': birthTime,
        'gender': gender,
        'status': 'pending',
      };

      logger.d('Inserting compatibility data: $compatibilityData');

      // DB에 데이터 삽입하고 즉시 결과 반환
      final response = await supabase
          .from('compatibility_results')
          .insert(compatibilityData)
          .select('*, artist:artist(*)')
          .single();

      // Edge Function 호출을 백그라운드로 이동
      final compatibilityId = response['id'] as String;
      _processInBackground(
        compatibilityId: compatibilityId,
      );

      // 즉시 모델 생성 및 반환
      final modelData = {
        ...response,
        'artist': artist.toJson(),
      };

      return CompatibilityModel.fromJson(modelData);
    } catch (e) {
      logger.e('Failed to create compatibility',
          error: e, stackTrace: StackTrace.current);

      if (e is PostgrestException) {
        logger.e('Postgrest Error Details:', error: {
          'message': e.message,
          'code': e.code,
          'details': e.details,
          'hint': e.hint
        });
      }

      rethrow;
    }
  }

  // 백그라운드 처리를 위한 메서드
  Future<void> _processInBackground({
    required String compatibilityId,
  }) async {
    try {
      await _startCompatibilityAnalysis(
        compatibilityId: compatibilityId,
      );
    } catch (e) {
      logger.e('Edge function error, will retry in background', error: e);
      _retryAnalysisInBackground(
        compatibilityId: compatibilityId,
      );
    }
  }

  Future<List<CompatibilityModel>> getCompatibilityHistory(
    int offset,
    int limit,
  ) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('compatibility_results')
          .select('*, artist:artist(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      logger.d('Got compatibility history response: $response');

      return (response as List).map((item) {
        return CompatibilityModel.fromJson(item);
      }).toList();
    } catch (e, s) {
      logger.e('Failed to get compatibility history', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<CompatibilityModel?> getCompatibility(String id) async {
    try {
      final response = await supabase
          .from('compatibility_results')
          .select('*, artist:artist(*)')
          .eq('id', id)
          .single();

      if (response == null) return null;

      logger.d('Got compatibility response: $response');

      return CompatibilityModel.fromJson(response);
    } catch (e) {
      logger.e('Failed to get compatibility', error: e);
      rethrow;
    }
  }

  Future<void> _startCompatibilityAnalysis({
    required String compatibilityId,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'compatibility',
        body: {
          'compatibility_id': compatibilityId,
        },
        headers: {
          'Content-Type': 'application/json',
        },
      );

      logger.d('Edge function complete. Status: ${response.status}');
      logger.d('Edge function response data: ${response.data}');

      if (response.status != 200) {
        throw Exception('Edge function error: ${response.data}');
      }
    } catch (e, s) {
      logger.e('Failed to start analysis', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _retryAnalysisInBackground({
    required String compatibilityId,
  }) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (var i = 0; i < maxRetries; i++) {
      try {
        await Future.delayed(retryDelay);
        await _startCompatibilityAnalysis(
          compatibilityId: compatibilityId,
        );
        return;
      } catch (e) {
        logger.e('Retry $i failed', error: e);
        if (i == maxRetries - 1) {
          await supabase.from('compatibility_results').update({
            'status': 'error',
            'error_message': 'Edge function failed after retries',
          }).eq('id', compatibilityId);
        }
      }
    }
  }
}
