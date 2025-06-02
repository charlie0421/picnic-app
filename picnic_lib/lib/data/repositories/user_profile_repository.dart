import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/repositories/base_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 사용자 프로필 데이터 접근을 위한 Repository
class UserProfileRepository extends BaseCrudRepository<UserProfilesModel, String> {
  @override
  String get tableName => 'user_profiles';

  @override
  UserProfilesModel fromJson(Map<String, dynamic> json) => UserProfilesModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(UserProfilesModel model) => model.toJson();

  @override
  String getId(UserProfilesModel model) => model.id;

  /// 현재 사용자의 프로필을 가져옵니다 (사용자 약관 정보 포함)
  Future<UserProfilesModel?> getCurrentUserProfile() async {
    try {
      requireAuth();
      
      final response = await supabase
          .from(tableName)
          .select('''
            id,
            avatar_url,
            star_candy,
            nickname,
            email,
            star_candy_bonus,
            is_admin,
            birth_date,
            gender,
            birth_time,
            deleted_at,
            user_agreement(id, terms, privacy)
          ''')
          .eq('id', currentUserId!)
          .maybeSingle();

      return handleResponse(response, fromJson);
    } catch (e) {
      return handleError('getCurrentUserProfile', Exception(e), null);
    }
  }

  /// 사용자 프로필 정보를 업데이트합니다
  Future<UserProfilesModel?> updateProfile({
    String? gender,
    DateTime? birthDate,
    String? birthTime,
    String? nickname,
    String? avatarUrl,
  }) async {
    try {
      requireAuth();

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (gender != null) updates['gender'] = gender;
      if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String();
      if (birthTime != null) updates['birth_time'] = birthTime;
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await supabase
          .from(tableName)
          .update(updates)
          .eq('id', currentUserId!)
          .select()
          .single();

      return handleResponse(response, fromJson);
    } catch (e) {
      throw handleError('updateProfile', Exception(e));
    }
  }

  /// 닉네임을 업데이트합니다 (Edge Function 사용)
  Future<UserProfilesModel?> updateNickname(String nickname) async {
    try {
      requireAuth();
      
      final response = await supabase.functions.invoke(
        'update-nickname',
        body: {'nickname': nickname},
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Unknown error';
        throw Exception('Failed to update nickname: $errorMessage');
      }

      final responseData = response.data;
      if (responseData is Map && responseData['data'] != null) {
        return fromJson(responseData['data'] as Map<String, dynamic>);
      }
      
      throw Exception('Invalid response format');
    } catch (e) {
      throw handleError('updateNickname', Exception(e));
    }
  }

  /// 아바타 URL을 업데이트합니다
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      requireAuth();
      
      await supabase
          .from(tableName)
          .update({'avatar_url': avatarUrl})
          .eq('id', currentUserId!);

      return true;
    } catch (e) {
      return handleError('updateAvatar', Exception(e), false);
    }
  }

  /// 스타 캔디를 업데이트합니다
  Future<bool> updateStarCandy(int amount) async {
    try {
      requireAuth();
      
      await supabase
          .from(tableName)
          .update({'star_candy': amount})
          .eq('id', currentUserId!);

      return true;
    } catch (e) {
      return handleError('updateStarCandy', Exception(e), false);
    }
  }

  /// 스타 캔디를 증가/감소시킵니다
  Future<int?> adjustStarCandy(int delta) async {
    try {
      requireAuth();
      
      final response = await supabase.rpc('adjust_star_candy', params: {
        'user_id': currentUserId!,
        'delta_amount': delta,
      });

      return response as int?;
    } catch (e) {
      return handleError('adjustStarCandy', Exception(e), null);
    }
  }

  /// 사용자 약관 동의를 설정합니다
  Future<bool> setUserAgreement() async {
    try {
      requireAuth();
      
      await supabase.from('user_agreement').upsert({
        'id': currentUserId!,
        'terms': 'now',
        'privacy': 'now',
      }).select();

      return true;
    } catch (e) {
      return handleError('setUserAgreement', Exception(e), false);
    }
  }

  /// 사용자 약관을 생성합니다
  Future<bool> createUserAgreement() async {
    try {
      requireAuth();
      
      await supabase.from('user_agreement').insert({
        'id': currentUserId!,
        'terms': DateTime.now().toUtc(),
        'privacy': DateTime.now().toUtc(),
      }).select();

      return true;
    } catch (e) {
      return handleError('createUserAgreement', Exception(e), false);
    }
  }

  /// 만료 예정 보너스를 계산합니다
  Future<List<Map<String, dynamic>>?> getExpireBonus() async {
    try {
      requireAuth();
      
      final response = await supabase.rpc('get_expiring_bonus_prediction');
      
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      
      return null;
    } catch (e) {
      return handleError('getExpireBonus', Exception(e), null);
    }
  }

  /// 특정 사용자의 프로필을 가져옵니다 (공개 정보만)
  Future<UserProfilesModel?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('id, nickname, avatar_url, is_admin')
          .eq('id', userId)
          .maybeSingle();

      return handleResponse(response, fromJson);
    } catch (e) {
      return handleError('getUserProfile', Exception(e), null);
    }
  }

  /// 여러 사용자의 프로필을 한번에 가져옵니다
  Future<Map<String, UserProfilesModel>> getUserProfiles(List<String> userIds) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('id, nickname, avatar_url, is_admin')
          .inFilter('id', userIds);

      final Map<String, UserProfilesModel> result = {};
      for (final item in response) {
        final profile = fromJson(item);
        result[profile.id] = profile;
      }
      
      return result;
    } catch (e) {
      return handleError('getUserProfiles', Exception(e), <String, UserProfilesModel>{});
    }
  }

  /// 사용자 프로필을 삭제합니다 (논리적 삭제)
  Future<bool> deleteUserProfile() async {
    try {
      requireAuth();
      
      await supabase
          .from(tableName)
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', currentUserId!);

      return true;
    } catch (e) {
      return handleError('deleteUserProfile', Exception(e), false);
    }
  }

  /// 사용자 프로필을 복구합니다
  Future<bool> restoreUserProfile() async {
    try {
      requireAuth();
      
      await supabase
          .from(tableName)
          .update({'deleted_at': null})
          .eq('id', currentUserId!);

      return true;
    } catch (e) {
      return handleError('restoreUserProfile', Exception(e), false);
    }
  }

  /// 닉네임 중복을 확인합니다
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return handleError('isNicknameAvailable', Exception(e), false);
    }
  }

  /// 관리자 사용자인지 확인합니다
  Future<bool> isAdmin() async {
    try {
      if (!isAuthenticated) return false;
      
      final response = await supabase
          .from(tableName)
          .select('is_admin')
          .eq('id', currentUserId!)
          .maybeSingle();

      return response?['is_admin'] == true;
    } catch (e) {
      return handleError('isAdmin', Exception(e), false);
    }
  }

  /// 사용자 통계를 가져옵니다
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      requireAuth();
      
      final response = await supabase.rpc('get_user_stats', params: {
        'user_id': currentUserId!,
      });

      return response as Map<String, dynamic>?;
    } catch (e) {
      return handleError('getUserStats', Exception(e), null);
    }
  }

  /// 사용자 활동 로그를 기록합니다
  Future<bool> logActivity(String activity, Map<String, dynamic>? metadata) async {
    try {
      requireAuth();
      
      await supabase.from('user_activity_log').insert({
        'user_id': currentUserId!,
        'activity': activity,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      return handleError('logActivity', Exception(e), false);
    }
  }
} 