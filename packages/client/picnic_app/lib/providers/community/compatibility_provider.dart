import 'dart:async';
import 'dart:convert';

import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/compatibility_provider.g.dart';

@Riverpod(keepAlive: true)
class Compatibility extends _$Compatibility {
  static const String _table = 'compatibility_results';
  static const _i18nTable = 'compatibility_results_i18n';
  static const _retryDelay = Duration(seconds: 2);
  static const _maxRetries = 3;

  Timer? _retryTimer;

  @override
  CompatibilityModel? build() {
    ref.onDispose(() {
      _retryTimer?.cancel();
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

// 기존 데이터 조회
      final existingResponse = await _findExistingCompatibility(
        userId: userId,
        artistId: artist.id,
        birthDate: birthDate,
        gender: gender,
        birthTime: birthTime,
      );

// 기존 데이터가 있는 경우 복사
      if (existingResponse != null) {
        final compatibility = await _copyExistingCompatibility(
          existingResponse: existingResponse,
          userId: userId,
          artist: artist,
          birthDate: birthDate,
          gender: gender,
          birthTime: birthTime,
        );
        return compatibility;
      }

// 새로운 데이터 생성
      final compatibility = await _createNewCompatibility(
        userId: userId,
        artist: artist,
        birthDate: birthDate,
        gender: gender,
        birthTime: birthTime,
      );

      return compatibility;
    } catch (e, s) {
      logger.e('Failed to create compatibility', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _findExistingCompatibility({
    required String userId,
    required int artistId,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    final query = supabase
        .from(_table)
        .select('''
          id,
          user_id,
          artist_id,
          user_birth_date,
          user_birth_time,
          gender,
          status,
          error_message,
          compatibility_score,
          compatibility_summary,
          completed_at,
          created_at,
          is_paid,
          artist:artist(*)
        ''')
        .eq('user_id', userId)
        .eq('artist_id', artistId)
        .eq('user_birth_date', birthDate.toIso8601String())
        .eq('gender', gender);

    final response = birthTime == null
        ? await query
            .isFilter('user_birth_time', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle()
        : await query
            .eq('user_birth_time', birthTime)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    return response;
  }

  Future<CompatibilityModel> _copyExistingCompatibility({
    required Map<String, dynamic> existingResponse,
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    final compatibilityData = {
      'user_id': userId,
      'artist_id': artist.id,
      'idol_birth_date': artist.birthDate?.toIso8601String(),
      'user_birth_date': birthDate.toIso8601String(),
      'user_birth_time': birthTime,
      'gender': gender,
      'status': 'completed',
      'compatibility_score': existingResponse['compatibility_score'],
      'compatibility_summary':
          utf8.decode(existingResponse['compatibility_summary']),
      'error_message': null,
      'completed_at': DateTime.now().toIso8601String(),
      'is_paid': existingResponse['is_paid'],
    };

    final response =
        await supabase.from(_table).insert(compatibilityData).select().single();

// i18n 데이터 조회 및 복사
    final i18nData = await _getI18nData(existingResponse['id']);
    if (i18nData.isNotEmpty) {
      await _copyI18nData(response['id'], i18nData);
    }

    final compatibility = CompatibilityModel.fromJson({
      ...response,
      'artist': artist.toJson(),
      'i18n': i18nData,
    });

    state = compatibility;
    return compatibility;
  }

  Future<CompatibilityModel> _createNewCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    final compatibilityData = {
      'user_id': userId,
      'artist_id': artist.id,
      'idol_birth_date': artist.birthDate?.toIso8601String(),
      'user_birth_date': birthDate.toIso8601String(),
      'user_birth_time': birthTime,
      'gender': gender,
      'status': 'pending',
      'is_paid': false,
    };

    final response =
        await supabase.from(_table).insert(compatibilityData).select().single();

    final compatibility = CompatibilityModel.fromJson({
      ...response,
      'artist': artist.toJson(),
    });

    state = compatibility;
    _processInBackground(compatibility);

    return compatibility;
  }

  Future<List<Map<String, dynamic>>> _getI18nData(
      String compatibilityId) async {
    final i18nData = [];

    for (final lang in ['en', 'ja', 'zh']) {
      try {
        final langData = await supabase
            .from(_i18nTable)
            .select()
            .eq('compatibility_id', compatibilityId)
            .eq('language', lang)
            .maybeSingle();

        if (langData != null) {
          i18nData.add(langData);
        }
      } catch (e) {
        logger.e('Error fetching $lang translation', error: e);
      }
    }

    return List<Map<String, dynamic>>.from(i18nData);
  }

  Future<void> _copyI18nData(
      String newCompatibilityId, List<Map<String, dynamic>> i18nData) async {
    for (final data in i18nData) {
      try {
        await _saveI18nData(newCompatibilityId, data);
      } catch (e) {
        logger.e('Error copying i18n data for ${data['language']}', error: e);
      }
    }
  }

  Future<CompatibilityModel?> getCompatibility(String id) async {
    try {
      // 1. 기본 데이터 조회
      final mainResponse = await supabase.from(_table).select('''
          id,
          user_id,
          artist_id,
          user_birth_date,
          user_birth_time,
          gender,
          status,
          error_message,
          compatibility_score,
          created_at,
          completed_at,
          is_paid,
          artist:artist(*)
        ''').eq('id', id).single();

      if (mainResponse == null) {
        throw Exception('Compatibility not found');
      }

      // 2. i18n 데이터를 언어/필드별로 개별 조회
      final i18nData = [];

      for (final lang in ['en', 'ja', 'zh']) {
        try {
          // 2-1. 기본 정보 조회 (score, summary)
          final basicResponse = await supabase
              .from(_i18nTable)
              .select('language, compatibility_score')
              .eq('compatibility_id', id)
              .eq('language', lang)
              .limit(1)
              .maybeSingle();

          if (basicResponse == null) continue;

          // 2-2. summary 별도 조회
          final summaryResponse = await supabase
              .from(_i18nTable)
              .select('compatibility_summary')
              .eq('compatibility_id', id)
              .eq('language', lang)
              .not('compatibility_summary', 'is', null)
              .limit(1)
              .maybeSingle();

          // 2-3. style 조회
          final styleResponse = await supabase
              .from(_i18nTable)
              .select('details->style')
              .eq('compatibility_id', id)
              .eq('language', lang)
              .not('details->style', 'is', null)
              .limit(1)
              .maybeSingle();

          // 2-4. activities 조회
          final activitiesResponse = await supabase
              .from(_i18nTable)
              .select('details->activities')
              .eq('compatibility_id', id)
              .eq('language', lang)
              .not('details->activities', 'is', null)
              .limit(1)
              .maybeSingle();

          // 2-5. tips 조회
          final tipsResponse = await supabase
              .from(_i18nTable)
              .select('tips')
              .eq('compatibility_id', id)
              .eq('language', lang)
              .not('tips', 'is', null)
              .maybeSingle();

          // 모든 데이터 병합
          final langData = {
            ...basicResponse,
            'compatibility_summary': summaryResponse?['compatibility_summary'],
            'details': {
              'style': styleResponse?['style'],
              'activities': activitiesResponse?['activities'],
            },
            'tips': tipsResponse?['tips'],
          };

          i18nData.add(langData);
        } catch (e) {
          logger.e('Error fetching $lang translation', error: e);
          continue;
        }
      }

      // completed 상태이고 i18n 데이터가 없는 경우 재시도
      if (i18nData.isEmpty && mainResponse['status'] == 'completed') {
        await Future.delayed(const Duration(milliseconds: 500));
        return getCompatibility(id);
      }

      return CompatibilityModel.fromJson({
        ...mainResponse,
        'i18n': i18nData,
      });
    } catch (e, stackTrace) {
      logger.e('Failed to get compatibility', error: e, stackTrace: stackTrace);

      if (_shouldRetry(e)) {
        await Future.delayed(_retryDelay);
        return getCompatibility(id);
      }

      rethrow;
    }
  }

  Future<void> _saveI18nData(
      String compatibilityId, Map<String, dynamic> i18nData) async {
    try {
      // 1. 기본 정보 저장
      await supabase.from(_i18nTable).upsert({
        'compatibility_id': compatibilityId,
        'language': i18nData['language'],
        'compatibility_score': i18nData['compatibility_score'],
      });

      // 2. summary 저장
      if (i18nData['compatibility_summary'] != null) {
        await supabase.from(_i18nTable).upsert({
          'compatibility_id': compatibilityId,
          'language': i18nData['language'],
          'compatibility_summary': i18nData['compatibility_summary'],
        });
      }

      // 3. details.style 저장
      if (i18nData['details']?['style'] != null) {
        await supabase.from(_i18nTable).upsert({
          'compatibility_id': compatibilityId,
          'language': i18nData['language'],
          'details': {'style': i18nData['details']['style']},
        });
      }

      // 4. details.activities 저장
      if (i18nData['details']?['activities'] != null) {
        await supabase.from(_i18nTable).upsert({
          'compatibility_id': compatibilityId,
          'language': i18nData['language'],
          'details': {'activities': i18nData['details']['activities']},
        });
      }

      // 5. tips 저장
      if (i18nData['tips'] != null) {
        await supabase.from(_i18nTable).upsert({
          'compatibility_id': compatibilityId,
          'language': i18nData['language'],
          'tips': i18nData['tips'],
        });
      }
    } catch (e, s) {
      logger.e('Error saving i18n data', error: e, stackTrace: s);
      throw e;
    }
  }

  bool _shouldRetry(dynamic error) {
    final errorMsg = error.toString().toLowerCase();
    return errorMsg.contains('connection closed') ||
        errorMsg.contains('network error') ||
        errorMsg.contains('content size exceeds') ||
        errorMsg.contains('encoding') ||
        errorMsg.contains('socket') ||
        errorMsg.contains('timeout');
  }

  Future<void> refresh() async {
    if (state == null) return;

    try {
      final currentState = state;
      final result = await getCompatibility(state!.id);
      if (currentState == state && result != null) {
        state = result;
      }
    } catch (e) {
      logger.e('Failed to refresh compatibility', error: e);
    }
  }

  Future<void> _processInBackground(CompatibilityModel initial) async {
    var retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        final response = await supabase.functions.invoke(
          'compatibility',
          body: {'compatibility_id': initial.id},
        );

        logger.i('Edge function response: ${response.data}');

        if (response.status == 200) {
          await Future.delayed(const Duration(seconds: 1));
          final updated = await getCompatibility(initial.id);
          if (updated != null) {
            state = updated;
          }
          return;
        }

        throw Exception('Edge function error: ${response.data}');
      } catch (e) {
        logger.e('Edge function error (attempt ${retryCount + 1}/$_maxRetries)',
            error: e);
        retryCount++;

        if (retryCount == _maxRetries) {
          await supabase.from(_table).update({
            'status': 'error',
            'error_message': 'Failed after $_maxRetries attempts',
          }).eq('id', initial.id);
          return;
        }

        await Future.delayed(_retryDelay * retryCount);
      }
    }
  }
}
