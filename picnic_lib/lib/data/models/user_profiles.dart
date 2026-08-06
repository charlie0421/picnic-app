import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/providers/models/user_profiles.freezed.dart';
part '../../generated/providers/models/user_profiles.g.dart';

@freezed
abstract class UserProfilesModel with _$UserProfilesModel {
  const UserProfilesModel._();

  /// 관리자 화면 접근 판정의 **단일 predicate**.
  ///
  /// DB 쪽 관리자 판정(`is_super_admin()` 함수, get_payment_breakdown 내부
  /// 검사)은 `is_super_admin OR is_admin` 이다. UI 게이트가 is_admin 만
  /// 읽으면 is_super_admin=true/is_admin=false 계정이 DB 는 통과하는데
  /// UI 에서 거부된다 (Sol 머지 게이트 리뷰, PR #135). 관리자 게이트는
  /// 반드시 이 getter 를 쓴다 - isAdmin 을 직접 읽지 말 것.
  bool get hasAdminAccess => (isAdmin ?? false) || (isSuperAdmin ?? false);

  const factory UserProfilesModel({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'nickname') String? nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'user_agreement') UserAgreement? userAgreement,
    @JsonKey(name: 'is_admin') required bool? isAdmin,
    @JsonKey(name: 'is_super_admin') bool? isSuperAdmin,
    @JsonKey(name: 'star_candy') required int? starCandy,
    @JsonKey(name: 'star_candy_bonus') required int? starCandyBonus,
    @JsonKey(name: 'jma_candy') required int? jmaCandy,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'birth_time') String? birthTime,
  }) = _UserProfilesModel;

  factory UserProfilesModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfilesModelFromJson(json);
}

@freezed
abstract class UserAgreement with _$UserAgreement {
  const UserAgreement._();

  const factory UserAgreement({
    required DateTime terms,
    required DateTime privacy,
  }) = _UserAgreement;

  factory UserAgreement.fromJson(Map<String, dynamic> json) =>
      _$UserAgreementFromJson(json);
}
