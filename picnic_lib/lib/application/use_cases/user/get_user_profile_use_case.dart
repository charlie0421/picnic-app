import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/application/common/use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';

class GetUserProfileUseCase implements UseCase<GetUserProfileParams, UserEntity?> {
  final IUserRepository _userRepository;

  const GetUserProfileUseCase(this._userRepository);

  @override
  Future<UseCaseResult<UserEntity?>> execute(GetUserProfileParams params) async {
    try {
      // Validate input parameters
      if (params.userId.isEmpty) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('User ID cannot be empty')
        );
      }

      // Get user from repository
      final user = await _userRepository.getUserById(params.userId);

      if (user == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('User not found with ID: ${params.userId}')
        );
      }

      // Check if user is active
      if (!user.isActive) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User account is deactivated')
        );
      }

      // Apply business rules based on requirements
      if (params.requireCompleteProfile && !user.isProfileComplete) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User profile is incomplete')
        );
      }

      if (params.requireAgreement && !user.hasAgreedToTerms) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User has not agreed to terms of service')
        );
      }

      if (params.requireAdultContent && !user.canAccessAdultContent) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('User cannot access adult content')
        );
      }

      // Return successful result
      return UseCaseResult.success(user);

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to get user profile: $e')
      );
    }
  }
}

class GetUserProfileParams {
  final String userId;
  final bool requireCompleteProfile;
  final bool requireAgreement;
  final bool requireAdultContent;

  const GetUserProfileParams({
    required this.userId,
    this.requireCompleteProfile = false,
    this.requireAgreement = false,
    this.requireAdultContent = false,
  });

  @override
  String toString() {
    return 'GetUserProfileParams(userId: $userId, requireCompleteProfile: $requireCompleteProfile, requireAgreement: $requireAgreement, requireAdultContent: $requireAdultContent)';
  }
}