import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/application/common/use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';

class UpdateUserProfileUseCase implements UseCase<UpdateUserProfileParams, UserEntity> {
  final IUserRepository _userRepository;

  const UpdateUserProfileUseCase(this._userRepository);

  @override
  Future<UseCaseResult<UserEntity>> execute(UpdateUserProfileParams params) async {
    try {
      // Validate input parameters
      if (params.userId.isEmpty) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('User ID cannot be empty')
        );
      }

      // Get current user to check permissions and current state
      final currentUser = await _userRepository.getUserById(params.userId);
      if (currentUser == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('User not found with ID: ${params.userId}')
        );
      }

      // Check if user is active
      if (!currentUser.isActive) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Cannot update profile of deactivated user')
        );
      }

      // Validate nickname if provided
      if (params.nickname != null) {
        final nicknameValidation = await _validateNickname(params.nickname!, currentUser);
        if (nicknameValidation.isFailure) {
          return UseCaseResult.failure(nicknameValidation.failure!);
        }
      }

      // Validate birth date if provided
      if (params.birthDate != null) {
        final birthDateValidation = _validateBirthDate(params.birthDate!);
        if (birthDateValidation.isFailure) {
          return UseCaseResult.failure(birthDateValidation.failure!);
        }
      }

      // Validate gender if provided
      if (params.gender != null) {
        final genderValidation = _validateGender(params.gender!);
        if (genderValidation.isFailure) {
          return UseCaseResult.failure(genderValidation.failure!);
        }
      }

      // Validate avatar URL if provided
      if (params.avatarUrl != null) {
        final avatarValidation = _validateAvatarUrl(params.avatarUrl!);
        if (avatarValidation.isFailure) {
          return UseCaseResult.failure(avatarValidation.failure!);
        }
      }

      // Update user profile
      final updatedUser = await _userRepository.updateUserProfile(
        userId: params.userId,
        nickname: params.nickname,
        avatarUrl: params.avatarUrl,
        birthDate: params.birthDate,
        gender: params.gender,
        birthTime: params.birthTime,
      );

      return UseCaseResult.success(updatedUser);

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to update user profile: $e')
      );
    }
  }

  Future<UseCaseResult<void>> _validateNickname(String nickname, UserEntity currentUser) async {
    // Check nickname length
    if (nickname.length < 2) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Nickname must be at least 2 characters long')
      );
    }

    if (nickname.length > 50) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Nickname must be less than 50 characters long')
      );
    }

    // Check nickname format
    final nicknameRegex = RegExp(r'^[a-zA-Z0-9가-힣_.-]+$');
    if (!nicknameRegex.hasMatch(nickname)) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Nickname contains invalid characters')
      );
    }

    // Check if nickname is different from current
    if (nickname == currentUser.nickname) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('New nickname must be different from current nickname')
      );
    }

    // Check if nickname is already taken (only if different from current)
    final nicknameExists = await _userRepository.nicknameExists(nickname);
    if (nicknameExists) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule('Nickname is already taken')
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    
    // Check if birth date is in the future
    if (birthDate.isAfter(now)) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Birth date cannot be in the future')
      );
    }

    // Check if birth date is too far in the past (e.g., more than 120 years)
    final maxAge = DateTime(now.year - 120, now.month, now.day);
    if (birthDate.isBefore(maxAge)) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Birth date is too far in the past')
      );
    }

    // Check if user would be too young (less than 13 years old)
    final minAge = DateTime(now.year - 13, now.month, now.day);
    if (birthDate.isAfter(minAge)) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule('User must be at least 13 years old')
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateGender(String gender) {
    final validGenders = ['male', 'female', 'other'];
    if (!validGenders.contains(gender.toLowerCase())) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Invalid gender value. Must be one of: ${validGenders.join(', ')}')
      );
    }

    return UseCaseResult.success(null);
  }

  UseCaseResult<void> _validateAvatarUrl(String avatarUrl) {
    // Basic URL validation
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(avatarUrl)) {
      return UseCaseResult.failure(
        UseCaseFailure.invalidInput('Invalid avatar URL format')
      );
    }

    // Check if URL is from allowed domains (implement as needed)
    final allowedDomains = [
      'imgur.com',
      'cloudinary.com',
      'aws.amazon.com',
      'storage.googleapis.com',
    ];
    
    final uri = Uri.parse(avatarUrl);
    final isAllowedDomain = allowedDomains.any((domain) => 
        uri.host.contains(domain));
    
    if (!isAllowedDomain) {
      return UseCaseResult.failure(
        UseCaseFailure.businessRule('Avatar must be hosted on an approved service')
      );
    }

    return UseCaseResult.success(null);
  }
}

class UpdateUserProfileParams {
  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? gender;
  final String? birthTime;

  const UpdateUserProfileParams({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    this.birthDate,
    this.gender,
    this.birthTime,
  });

  /// Check if any field is being updated
  bool get hasUpdates => 
      nickname != null ||
      avatarUrl != null ||
      birthDate != null ||
      gender != null ||
      birthTime != null;

  @override
  String toString() {
    return 'UpdateUserProfileParams(userId: $userId, nickname: $nickname, avatarUrl: $avatarUrl, birthDate: $birthDate, gender: $gender, birthTime: $birthTime)';
  }
}