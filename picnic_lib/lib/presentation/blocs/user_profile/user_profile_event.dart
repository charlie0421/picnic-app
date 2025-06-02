part of 'user_profile_bloc.dart';

@freezed
class UserProfileEvent with _$UserProfileEvent {
  /// Load user profile with optional requirements
  const factory UserProfileEvent.loadUserProfile({
    required String userId,
    @Default(false) bool requireCompleteProfile,
    @Default(false) bool requireAgreement,
  }) = UserProfileLoadRequested;

  /// Update user profile information
  const factory UserProfileEvent.updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) = UserProfileUpdateRequested;

  /// Add star candy to user account
  const factory UserProfileEvent.addStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  }) = UserProfileAddStarCandyRequested;

  /// Spend star candy from user account
  const factory UserProfileEvent.spendStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  }) = UserProfileSpendStarCandyRequested;

  /// Refresh user profile data
  const factory UserProfileEvent.refresh({
    required String userId,
  }) = UserProfileRefreshRequested;
}