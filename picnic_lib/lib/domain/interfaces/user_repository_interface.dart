import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/value_objects/email.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';

/// Domain interface for user repository operations
/// This interface defines what the domain layer expects from the data layer
abstract class IUserRepository {
  /// Get user by ID
  Future<UserEntity?> getUserById(String userId);

  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Update user profile
  Future<UserEntity> updateUserProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  });

  /// Update user email
  Future<UserEntity> updateUserEmail({
    required String userId,
    required Email newEmail,
  });

  /// Update user nickname
  Future<UserEntity> updateUserNickname({
    required String userId,
    required String nickname,
  });

  /// Update user avatar
  Future<UserEntity> updateUserAvatar({
    required String userId,
    required String avatarUrl,
  });

  /// Add star candy to user
  Future<UserEntity> addStarCandy({
    required String userId,
    required StarCandy amount,
    String? reason,
  });

  /// Spend star candy from user
  Future<UserEntity> spendStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  });

  /// Add bonus star candy to user
  Future<UserEntity> addBonusStarCandy({
    required String userId,
    required StarCandy amount,
    String? reason,
  });

  /// Set user agreement
  Future<UserEntity> setUserAgreement({
    required String userId,
    bool? terms,
    bool? privacy,
  });

  /// Create user agreement
  Future<UserEntity> createUserAgreement({
    required String userId,
    bool agreeToTerms,
    bool agreeToPrivacy,
  });

  /// Get expiring bonus prediction for user
  Future<List<Map<String, dynamic>>?> getExpiringBonusPrediction(String userId);

  /// Mark user as deleted (soft delete)
  Future<void> deleteUser(String userId);

  /// Restore deleted user
  Future<UserEntity> restoreUser(String userId);

  /// Check if user exists
  Future<bool> userExists(String userId);

  /// Check if email is already in use
  Future<bool> emailExists(Email email);

  /// Check if nickname is already in use
  Future<bool> nicknameExists(String nickname);

  /// Get users by criteria
  Future<List<UserEntity>> getUsers({
    int? limit,
    int? offset,
    String? searchQuery,
    bool? isAdmin,
    DateTime? createdAfter,
    DateTime? createdBefore,
  });

  /// Stream user changes for real-time updates
  Stream<UserEntity?> streamUser(String userId);

  /// Stream current user changes
  Stream<UserEntity?> streamCurrentUser();
}