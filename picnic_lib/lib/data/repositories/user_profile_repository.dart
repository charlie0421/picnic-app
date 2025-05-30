import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/repositories/offline_first_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class UserProfileRepository extends OfflineFirstRepository<UserProfilesModel> {
  @override
  String get tableName => 'user_profiles';

  @override
  UserProfilesModel fromJson(Map<String, dynamic> json) => UserProfilesModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(UserProfilesModel model) => model.toJson();

  @override
  String getId(UserProfilesModel model) => model.id ?? '';

  /// 현재 사용자 프로필을 가져옵니다
  Future<UserProfilesModel?> getCurrentUserProfile(String userId) async {
    try {
      return await getById(userId);
    } catch (e, s) {
      logger.e('Error fetching current user profile', error: e, stackTrace: s);
      return null;
    }
  }

  /// 사용자 프로필을 업데이트합니다
  Future<UserProfilesModel?> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    String? countryCode,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) async {
    try {
      final existingProfile = await getById(userId);
      if (existingProfile == null) {
        logger.w('User profile not found: $userId');
        return null;
      }

      final updatedProfile = existingProfile.copyWith(
        nickname: nickname ?? existingProfile.nickname,
        avatarUrl: avatarUrl ?? existingProfile.avatarUrl,
        countryCode: countryCode ?? existingProfile.countryCode,
        birthDate: birthDate ?? existingProfile.birthDate,
        gender: gender ?? existingProfile.gender,
        birthTime: birthTime ?? existingProfile.birthTime,
      );

      return await update(updatedProfile);
    } catch (e, s) {
      logger.e('Error updating user profile', error: e, stackTrace: s);
      return null;
    }
  }

  /// 사용자의 스타 캔디 정보를 업데이트합니다
  Future<UserProfilesModel?> updateStarCandy({
    required String userId,
    int? starCandy,
    int? starCandyBonus,
  }) async {
    try {
      final existingProfile = await getById(userId);
      if (existingProfile == null) {
        logger.w('User profile not found: $userId');
        return null;
      }

      final updatedProfile = existingProfile.copyWith(
        starCandy: starCandy ?? existingProfile.starCandy,
        starCandyBonus: starCandyBonus ?? existingProfile.starCandyBonus,
      );

      return await update(updatedProfile);
    } catch (e, s) {
      logger.e('Error updating star candy', error: e, stackTrace: s);
      return null;
    }
  }

  /// 사용자 프로필을 생성합니다
  Future<UserProfilesModel?> createProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    String? countryCode,
    bool? isAdmin,
    int? starCandy,
    int? starCandyBonus,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) async {
    try {
      final newProfile = UserProfilesModel(
        id: userId,
        nickname: nickname,
        avatarUrl: avatarUrl,
        countryCode: countryCode,
        isAdmin: isAdmin ?? false,
        starCandy: starCandy ?? 0,
        starCandyBonus: starCandyBonus ?? 0,
        birthDate: birthDate,
        gender: gender,
        birthTime: birthTime,
        deletedAt: null,
        userAgreement: null,
      );

      return await create(newProfile);
    } catch (e, s) {
      logger.e('Error creating user profile', error: e, stackTrace: s);
      return null;
    }
  }

  /// 활성 사용자 프로필들을 가져옵니다 (삭제되지 않은 것만)
  Future<List<UserProfilesModel>> getActiveProfiles() async {
    try {
      final results = await getAll(
        where: 'deleted_at IS NULL',
        orderBy: 'nickname ASC',
      );
      
      logger.d('Fetched ${results.length} active user profiles');
      return results;
    } catch (e, s) {
      logger.e('Error fetching active profiles', error: e, stackTrace: s);
      return [];
    }
  }
} 