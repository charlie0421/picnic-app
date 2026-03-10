import 'package:picnic_lib/data/models/user_profiles.dart';

/// 사용자 프로필 모델 테스트 팩토리 클래스
class UserFactory {
  /// 기본 UserProfilesModel 생성
  static UserProfilesModel create({
    String? id = 'test-user-id-001',
    String? nickname = '테스트유저',
    String? avatarUrl,
    String? countryCode = 'KR',
    DateTime? deletedAt,
    UserAgreement? userAgreement,
    bool? isAdmin = false,
    int? starCandy = 100,
    int? starCandyBonus = 50,
    int? jmaCandy = 0,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) {
    return UserProfilesModel(
      id: id,
      nickname: nickname,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      deletedAt: deletedAt,
      userAgreement: userAgreement,
      isAdmin: isAdmin,
      starCandy: starCandy,
      starCandyBonus: starCandyBonus,
      jmaCandy: jmaCandy,
      birthDate: birthDate,
      gender: gender,
      birthTime: birthTime,
    );
  }

  /// 관리자 사용자 생성
  static UserProfilesModel createAdmin({
    String? id = 'admin-user-id-001',
    String? nickname = '관리자',
  }) {
    return create(
      id: id,
      nickname: nickname,
      isAdmin: true,
      starCandy: 9999,
      starCandyBonus: 9999,
    );
  }

  /// 약관 동의 완료된 사용자 생성
  static UserProfilesModel createWithAgreement({
    String? id = 'agreed-user-id-001',
    String? nickname = '동의유저',
  }) {
    return create(
      id: id,
      nickname: nickname,
      userAgreement: UserAgreementFactory.create(),
    );
  }

  /// 삭제된 사용자 생성
  static UserProfilesModel createDeleted({
    String? id = 'deleted-user-id-001',
    String? nickname = '삭제유저',
  }) {
    return create(
      id: id,
      nickname: nickname,
      deletedAt: DateTime.now(),
    );
  }

  /// 캔디가 없는 사용자 생성
  static UserProfilesModel createBroke({
    String? id = 'broke-user-id-001',
    String? nickname = '무캔디유저',
  }) {
    return create(
      id: id,
      nickname: nickname,
      starCandy: 0,
      starCandyBonus: 0,
      jmaCandy: 0,
    );
  }
}

/// UserAgreement 테스트 팩토리
class UserAgreementFactory {
  /// 기본 UserAgreement 생성
  static UserAgreement create({
    DateTime? terms,
    DateTime? privacy,
  }) {
    final now = DateTime.now();
    return UserAgreement(
      terms: terms ?? now,
      privacy: privacy ?? now,
    );
  }
}
