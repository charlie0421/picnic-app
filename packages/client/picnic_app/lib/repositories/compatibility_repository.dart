import 'dart:convert';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompatibilityRepository {
  static const String _table = 'compatibility_results';
  static const String _userProfilesTable = 'user_profiles';

  /// 새로운 궁합 결과를 생성하고 Edge Function을 실행합니다.
  Future<CompatibilityModel> createCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      // 1. 사용자 프로필 업데이트
      await supabase.from(_userProfilesTable).upsert({
        'id': userId,
        'birth_date': birthDate.toIso8601String(),
        'gender': gender,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. 궁합 결과 레코드 생성
      final response = await supabase
          .from(_table)
          .insert({
            'user_id': userId,
            'artist_id': artist.id,
            'idol_birth_date': artist.birthDate?.toIso8601String(),
            'user_birth_date': birthDate.toIso8601String(),
            'gender': gender,
            'status': 'pending',
          })
          .select('*, artist(*)')
          .single();

      final compatibility = _mapToCompatibilityModel(response);

      // 3. Edge Function 호출을 통해 궁합 분석 시작
      _startCompatibilityAnalysis(compatibility.id);

      return compatibility;
    } catch (e, stackTrace) {
      logger.e('Failed to create compatibility',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to create compatibility: $e');
    }
  }

  /// Edge Function을 호출하여 궁합 분석을 시작합니다.
  Future<void> _startCompatibilityAnalysis(String compatibilityId) async {
    try {
      logger.d('Starting compatibility analysis for ID: $compatibilityId');

      final response = await supabase.functions.invoke(
        'compatibility',
        body: {
          'compatibility_id': compatibilityId,
        },
      );

      logger.i('Edge function response: ${jsonEncode(response.data)}');

      if (response.status != 200) {
        logger.e('Edge function error: ${response.data}');
        throw Exception('Failed to start compatibility analysis');
      }

      logger.d('Successfully started compatibility analysis');
    } catch (e, stackTrace) {
      logger.e('Error calling edge function', error: e, stackTrace: stackTrace);
      // Edge Function 호출 실패 시 상태 업데이트
      await supabase.from(_table).update({
        'status': 'error',
        'error_message': 'Failed to start analysis: $e',
      }).eq('id', compatibilityId);

      throw Exception('Failed to start compatibility analysis: $e');
    }
  }

  /// 특정 ID의 궁합 결과를 조회합니다.
  Future<CompatibilityModel?> getCompatibility(String id) async {
    try {
      final response = await supabase
          .from(_table)
          .select('*, artist(*)')
          .eq('id', id)
          .single();

      logger.i('Compatibility response: $response');

      return _mapToCompatibilityModel(response);
    } catch (e, s) {
      logger.e('Failed to get compatibility', error: e, stackTrace: s);
      throw Exception('Failed to get compatibility: $e');
    }
  }

  /// 유저의 궁합 히스토리를 페이지네이션으로 조회합니다.
  Future<List<CompatibilityModel>> getCompatibilityHistory(
    int offset,
    int limit,
  ) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await supabase
          .from(_table)
          .select('*, artist(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((data) => _mapToCompatibilityModel(data))
          .toList();
    } catch (e, stackTrace) {
      logger.e('Failed to get compatibility history',
          error: e, stackTrace: stackTrace);
      throw Exception('Failed to get compatibility history: $e');
    }
  }

  /// 진행 중인 궁합 분석의 수를 조회합니다.
  Future<int> getPendingAnalysisCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await supabase
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .count();

      return response.count;
    } catch (e) {
      logger.e('Failed to get pending analysis count', error: e);
      throw Exception('Failed to get pending analysis count: $e');
    }
  }

  /// 최근 완료된 궁합 결과를 조회합니다.
  Future<List<CompatibilityModel>> getRecentCompletedResults({
    required int limit,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await supabase
          .from(_table)
          .select('*, artist(*)')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => _mapToCompatibilityModel(data))
          .toList();
    } catch (e) {
      logger.e('Failed to get recent completed results', error: e);
      throw Exception('Failed to get recent completed results: $e');
    }
  }

  /// 데이터베이스 응답을 CompatibilityModel로 변환합니다.
  CompatibilityModel _mapToCompatibilityModel(Map<String, dynamic> data) {
    final artistData = data['artist'] as Map<String, dynamic>;

    return CompatibilityModel(
      id: data['id'],
      userId: data['user_id'],
      artist: ArtistModel.fromJson(artistData),
      birthDate: DateTime.parse(data['user_birth_date']),
      birthTime: data['birth_time'],
      gender: data['gender'],
      status: CompatibilityStatusX.fromJson(data['status']),
      compatibilityScore: data['compatibility_score'],
      compatibilitySummary: data['compatibility_summary'],
      style: data['details'] != null && data['details']['style'] != null
          ? StyleDetails.fromJson(data['details']['style'])
          : null,
      activities:
          data['details'] != null && data['details']['activities'] != null
              ? ActivitiesDetails.fromJson(data['details']['activities'])
              : null,
      tips: data['tips'] != null ? List<String>.from(data['tips']) : null,
      errorMessage: data['error_message'],
      createdAt: DateTime.parse(data['created_at']),
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'])
          : null,
    );
  }
}
