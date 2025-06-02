import 'package:picnic_lib/domain/entities/artist_entity.dart';
import 'package:picnic_lib/domain/interfaces/artist_repository_interface.dart';
import 'package:picnic_lib/application/common/use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';

class GetArtistUseCase implements UseCase<GetArtistParams, ArtistEntity?> {
  final IArtistRepository _artistRepository;

  const GetArtistUseCase(this._artistRepository);

  @override
  Future<UseCaseResult<ArtistEntity?>> execute(GetArtistParams params) async {
    try {
      // Validate input parameters
      if (params.artistId <= 0) {
        return UseCaseResult.failure(
          UseCaseFailure.invalidInput('Artist ID must be positive')
        );
      }

      // Get artist from repository
      final artist = await _artistRepository.getArtistById(params.artistId);

      if (artist == null) {
        return UseCaseResult.failure(
          UseCaseFailure.notFound('Artist not found with ID: ${params.artistId}')
        );
      }

      // Check if artist is active
      if (!artist.isActive && params.requireActive) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Artist is not active')
        );
      }

      // Apply business rules based on requirements
      if (params.requireCompleteProfile && !artist.hasCompleteProfile) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Artist profile is incomplete')
        );
      }

      if (params.requirePopular && !artist.isPopular) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Artist is not popular enough')
        );
      }

      if (params.requireVoteEligible && !artist.canReceiveVotes()) {
        return UseCaseResult.failure(
          UseCaseFailure.businessRule('Artist is not eligible for votes')
        );
      }

      // Return successful result
      return UseCaseResult.success(artist);

    } catch (e) {
      return UseCaseResult.failure(
        UseCaseFailure.unexpected('Failed to get artist: $e')
      );
    }
  }
}

class GetArtistParams {
  final int artistId;
  final bool requireActive;
  final bool requireCompleteProfile;
  final bool requirePopular;
  final bool requireVoteEligible;

  const GetArtistParams({
    required this.artistId,
    this.requireActive = true,
    this.requireCompleteProfile = false,
    this.requirePopular = false,
    this.requireVoteEligible = false,
  });

  @override
  String toString() {
    return 'GetArtistParams(artistId: $artistId, requireActive: $requireActive, requireCompleteProfile: $requireCompleteProfile, requirePopular: $requirePopular, requireVoteEligible: $requireVoteEligible)';
  }
}