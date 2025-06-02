part of 'user_profile_bloc.dart';

@freezed
class UserProfileState with _$UserProfileState {
  /// Initial state when no operation has been performed
  const factory UserProfileState.initial() = UserProfileInitial;

  /// Loading state during asynchronous operations
  const factory UserProfileState.loading({
    UserEntity? user, // Keep previous user data during updates
  }) = UserProfileLoading;

  /// Successfully loaded user profile
  const factory UserProfileState.loaded({
    required UserEntity user,
  }) = UserProfileLoaded;

  /// Error state with error message
  const factory UserProfileState.error({
    required String message,
    UserEntity? user, // Keep previous user data if available
  }) = UserProfileError;
}

/// Extension for convenient state checking
extension UserProfileStateX on UserProfileState {
  /// Check if the state is loading
  bool get isLoading => this is UserProfileLoading;

  /// Check if the state has loaded data
  bool get isLoaded => this is UserProfileLoaded;

  /// Check if the state has an error
  bool get hasError => this is UserProfileError;

  /// Get the user entity if available
  UserEntity? get user => when(
    initial: () => null,
    loading: (user) => user,
    loaded: (user) => user,
    error: (message, user) => user,
  );

  /// Get the error message if in error state
  String? get errorMessage => when(
    initial: () => null,
    loading: (_) => null,
    loaded: (_) => null,
    error: (message, _) => message,
  );

  /// Check if user can perform actions (not in loading state)
  bool get canPerformActions => !isLoading;

  /// Check if user profile is complete
  bool get isProfileComplete => user?.isProfileComplete ?? false;

  /// Check if user can participate in votes
  bool get canParticipateInVotes => user?.canParticipateInVotes ?? false;

  /// Get star candy balance
  StarCandy get starCandyBalance => user?.starCandy ?? StarCandy.zero;

  /// Get bonus star candy balance
  StarCandy get bonusStarCandyBalance => user?.starCandyBonus ?? StarCandy.zero;

  /// Get total star candy (including bonus)
  StarCandy get totalStarCandy => user?.totalStarCandy ?? StarCandy.zero;
}